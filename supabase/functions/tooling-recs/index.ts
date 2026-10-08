import { budgetFor, llmComplete, RefusalError } from "../_shared/llm.ts";
import { adminClient, requireUser } from "../_shared/auth.ts";
import { isPro } from "../_shared/entitlement.ts";
import { error, internalError, json, preflight } from "../_shared/http.ts";
import { releaseUsage, reserveUsage, settleUsage } from "../_shared/quota.ts";
import { answerFormat, styleRules } from "../_shared/answer_style.ts";
import { answerLanguage } from "../_shared/language.ts";

interface ToolingRequest {
  material:      string;
  operation:     string;
  diameter:      number;
  units:         "metric" | "imperial";
  toolMaterial?: string;
  depthOfCut?:   number;
  widthOfCut?:   number;
  /// App language, en | fa | ro | ar (app 1.3.0+).
  language?:     string;
  /// "markdown" when the app renders Markdown (app 1.3.0+).
  format?:       string;
  /// Seconds the app waits for the answer (app 1.3.0+; earlier: 90).
  clientTimeout?: number;
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
1. Tool geometry (flutes, helix angle, coating, edge prep)
2. Two or three brand and product-line options (e.g. Sandvik, Kennametal, Walter, Iscar)
3. Why these suit this material and operation
4. One budget alternative

Name product lines or series. Give an exact catalogue number only when you are sure of it, and tell the operator to confirm the code in the maker's catalogue. Keep it practical for a shop floor operator.`;

    const reservation = await reserveUsage(admin, user.id, pro, {
      question_excerpt: `[tooling] ${material} ${operation} D${diameter}`,
    });
    if (reservation instanceof Response) return reservation;

    // The request is built from form fields, so the app language decides.
    const language = answerLanguage("", body.language);

    let result;
    try {
      result = await llmComplete({
        system:      "You are a CNC tooling engineer advising shop floor operators.\n\n" +
                     styleRules(language, answerFormat(body.format), true),
        parts:       [{ kind: "text", text: prompt }],
        maxTokens:   2000,
        claudeModel: "claude-haiku-4-5",
        language,
        budgetMs:    budgetFor(body.clientTimeout),
      });
    } catch (e) {
      await releaseUsage(admin, reservation.logId);
      if (e instanceof RefusalError) return error(422, "ai_refused", "The AI declined to answer this request");
      console.error("tooling-recs LLM failure:", e);
      return error(503, "ai_unavailable", "AI service temporarily unavailable");
    }
    await settleUsage(admin, reservation.logId, result.tokens);

    return json({ answer: result.text, provider: result.provider, truncated: result.truncated });
  } catch (e) {
    return internalError("tooling-recs", e);
  }
});
