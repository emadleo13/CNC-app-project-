import { llmComplete } from "../_shared/llm.ts";
import { adminClient, requireUser } from "../_shared/auth.ts";
import { isPro } from "../_shared/entitlement.ts";
import { error, internalError, json, preflight } from "../_shared/http.ts";
import { releaseUsage, reserveUsage, settleUsage } from "../_shared/quota.ts";

interface ToolingRequest {
  material:      string;
  operation:     string;
  diameter:      number;
  units:         "metric" | "imperial";
  toolMaterial?: string;
  depthOfCut?:   number;
  widthOfCut?:   number;
}

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;

  try {
    const user = await requireUser(req);
    if (user instanceof Response) return user;

    const admin = adminClient();
    const pro = await isPro(admin, user.id);
    if (!pro) {
      return error(403, "pro_required", "Pro subscription required", { pro_required: true });
    }

    const body: ToolingRequest = await req.json();
    const material  = String(body.material ?? "").substring(0, 100);
    const operation = String(body.operation ?? "").substring(0, 40);
    const diameter  = Number(body.diameter);
    const { units, toolMaterial, depthOfCut, widthOfCut } = body;
    if (!material || !operation || !(diameter > 0)) {
      return error(400, "bad_request", "Missing material, operation or diameter");
    }

    const unitStr = units === "imperial" ? "inches" : "mm";
    const prompt  = `I need tooling recommendations for this CNC milling operation:
- Material: ${material}
- Operation: ${operation}
- Tool diameter: ${diameter} ${unitStr}
- Tool material: ${toolMaterial ?? "carbide"}
- Depth of cut: ${depthOfCut ?? "??"} ${unitStr}
- Width of cut: ${widthOfCut ?? "??"} ${unitStr}

Please recommend:
1. **Specific tool geometry** (flutes, helix angle, coating, edge prep)
2. **Top 2-3 brand/grade recommendations** (e.g., Sandvik, Kennametal, Walter, Iscar)
3. **Why these specs suit this material + operation**
4. **One alternative budget option**

Be specific with product codes where possible. Keep it practical for a shop floor operator.`;

    const reservation = await reserveUsage(admin, user.id, pro, {
      question_excerpt: `[tooling] ${material} ${operation} D${diameter}`,
    });
    if (reservation instanceof Response) return reservation;

    let result;
    try {
      result = await llmComplete({
        parts:          [{ kind: "text", text: prompt }],
        maxTokens:      1200,
        anthropicModel: "claude-haiku-4-5-20251001",
      });
    } catch (e) {
      await releaseUsage(admin, reservation.logId);
      console.error("tooling-recs LLM failure:", e);
      return error(503, "ai_unavailable", "AI service temporarily unavailable");
    }
    await settleUsage(admin, reservation.logId, result.tokens);

    return json({ answer: result.text });
  } catch (e) {
    return internalError("tooling-recs", e);
  }
});
