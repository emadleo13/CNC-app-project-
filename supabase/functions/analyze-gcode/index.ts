import { llmComplete } from "../_shared/llm.ts";
import { adminClient, requireUser } from "../_shared/auth.ts";
import { isPro } from "../_shared/entitlement.ts";
import { error, internalError, json, preflight } from "../_shared/http.ts";
import { releaseUsage, reserveUsage, settleUsage } from "../_shared/quota.ts";

interface AnalyzeRequest {
  gcode:    string;
  dialect:  "haas" | "sinumerik" | "generic";
  context?: string;
}

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;

  try {
    const user = await requireUser(req);
    if (user instanceof Response) return user;

    const body: AnalyzeRequest = await req.json();
    const { gcode } = body;
    const dialect = body.dialect === "sinumerik" ? "sinumerik" : body.dialect === "generic" ? "generic" : "haas";

    if (!gcode || gcode.trim().length === 0) {
      return error(400, "bad_request", "No G-code provided");
    }
    // Limit input size to prevent abuse (max 50KB of G-code)
    if (gcode.length > 50000) {
      return error(400, "too_large", "G-code too large. Max 50KB per request.");
    }

    // Each analysis counts toward the free monthly limit like any AI question.
    const admin = adminClient();
    const reservation = await reserveUsage(admin, user.id, await isPro(admin, user.id), {
      question_excerpt: `[gcode:${dialect}] ${gcode.substring(0, 100)}`,
    });
    if (reservation instanceof Response) return reservation;

    const dialectGuide = dialect === "sinumerik"
      ? `You are analyzing Siemens Sinumerik 840D/828D G-code.
Key Sinumerik specifics:
- Cycles: CYCLE81 (drilling), CYCLE82 (drilling+dwell), CYCLE83 (deep hole peck), CYCLE84 (rigid tapping), CYCLE840 (flexible tapping)
- Variables: DEF REAL/INT/BOOL/STRING, accessed via variable name
- Transformations: TRANS, ATRANS, ROT, AROT, SCALE, MIRROR
- Jumps: GOTOB (backward), GOTOF (forward), labels end with ':'
- Tool change: T1 D1 (T=tool, D=cutting edge)
- Subroutines: PROC name / ENDPROC`
      : `You are analyzing Haas CNC G-code (compatible with Fanuc ISO standard).
Key Haas specifics:
- Tool change: T1 M6 (M6 executes the change)
- Tool length: G43 H# (H matches tool number)
- Subprograms: M98 P#### (call), M99 (return)
- Macro variables: #1-#33 (local), #100-#199 (global retained), #500-#999 (global saved)
- Haas-specific: M136 (inch per rev tapping), M154/M155 (pallet control)`;

    const systemPrompt = `${dialectGuide}

Analyze the G-code and respond with a valid JSON object using EXACTLY this structure:
{
  "summary": "One paragraph describing what this CNC program does",
  "operation_type": "milling|turning|drilling|tapping|multi",
  "estimated_runtime_minutes": null,
  "lines": [
    {
      "line_number": 1,
      "original": "exact line text",
      "explanation": "What this line does in plain language",
      "severity": "ok|warning|error",
      "issue": "Description of the problem (only if warning/error, else omit)",
      "suggestion": "How to fix it (only if error, else omit)"
    }
  ],
  "overall_issues": ["list of significant issues found"],
  "suggestions": ["list of optimization recommendations"]
}

Rules:
- Every line in the program must appear in "lines" array, including empty lines and comments
- Be thorough but concise in explanations
- Flag potential crashes, wrong tool calls, missing retracts as errors
- Flag suboptimal feeds, missing G-codes as warnings
- DO NOT include markdown or text outside the JSON`;

    let responseText: string;
    let tokens: number;
    try {
      ({ text: responseText, tokens } = await llmComplete({
        system: systemPrompt,
        parts:  [{ kind: "text", text: `Analyze this ${dialect.toUpperCase()} G-code program:\n\n${gcode}` }],
        maxTokens:      8192,
        anthropicModel: "claude-sonnet-4-6",
      }));
    } catch (e) {
      await releaseUsage(admin, reservation.logId);
      console.error("analyze-gcode LLM failure:", e);
      return error(503, "ai_unavailable", "AI service temporarily unavailable");
    }
    await settleUsage(admin, reservation.logId, tokens);

    // Extract JSON from response
    let analysisJson: Record<string, unknown>;

    try {
      // Handle case where Claude wraps JSON in markdown code blocks
      const jsonMatch = responseText.match(/```(?:json)?\s*([\s\S]+?)\s*```/) ||
                        responseText.match(/(\{[\s\S]+\})/);
      const jsonStr = jsonMatch ? jsonMatch[1] : responseText;
      analysisJson = JSON.parse(jsonStr);
    } catch {
      console.error("analyze-gcode unparseable reply:", responseText.substring(0, 500));
      return error(502, "ai_bad_response", "Failed to parse AI response");
    }

    const lines = Array.isArray(analysisJson.lines) ? analysisJson.lines as Array<{ severity?: string }> : [];
    const { error: saveError } = await admin.from("gcode_analyses").insert({
      user_id:       user.id,
      gcode_content: gcode,
      dialect:       dialect,
      analysis_json: analysisJson,
      error_count:   lines.filter((l) => l.severity === "error").length,
      warning_count: lines.filter((l) => l.severity === "warning").length,
      line_count:    lines.length,
      token_count:   tokens,
    });
    if (saveError) console.error("analyze-gcode save failed:", saveError);

    return json(analysisJson);
  } catch (e) {
    return internalError("analyze-gcode", e);
  }
});
