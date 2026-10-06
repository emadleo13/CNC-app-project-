import { llmComplete } from "../_shared/llm.ts";
import { adminClient, requireUser } from "../_shared/auth.ts";
import { isPro } from "../_shared/entitlement.ts";
import { error, internalError, json, preflight } from "../_shared/http.ts";
import { releaseUsage, reserveUsage, settleUsage } from "../_shared/quota.ts";

interface AskRequest {
  question:      string;
  alarmContext?: string;
}

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;

  try {
    const user = await requireUser(req);
    if (user instanceof Response) return user;

    const body: AskRequest = await req.json();
    const { question } = body;
    // The app builds this from its bundled alarm database; cap it rather than
    // reject, so a question naming several codes still gets an answer.
    const alarmContext = body.alarmContext?.substring(0, 6000);

    if (!question || question.trim().length === 0) {
      return error(400, "bad_request", "No question provided");
    }
    if (question.length > 2000) {
      return error(400, "too_large", "Question too long. Max 2000 characters.");
    }

    const admin = adminClient();
    const reservation = await reserveUsage(admin, user.id, await isPro(admin, user.id), {
      question_excerpt:  question,
      had_alarm_context: !!alarmContext,
    });
    if (reservation instanceof Response) return reservation;

    const contextBlock = alarmContext
      ? `\n\nThe app has found the following alarm data from its local database relevant to this question:\n${alarmContext}Use this data to provide a specific, accurate answer about this alarm code.`
      : "";

    const systemPrompt =
      "You are an expert CNC machining assistant for an app used by machine operators and programmers. " +
      "You specialize in:\n" +
      "- Haas CNC controllers (VF series, ST series, DC series) — alarms, programming, operation\n" +
      "- Siemens Sinumerik 840D sl / 828D — alarms, cycles (CYCLE81–CYCLE840), machine data\n" +
      "- FANUC Series 0i/16i/18i/21i/31i — alarms, parameters, PMC\n" +
      "- Heidenhain TNC 640/530/426 — alarms, cycles, conversational programming\n" +
      "- G-code programming (ISO 6983, Haas dialect, Sinumerik dialect)\n" +
      "- Feed and speed calculations (Vc, RPM, chip load, MRR)\n" +
      "- CNC troubleshooting — servo faults, spindle issues, ATC faults, parameter errors\n" +
      "- Tooling — carbide/HSS endmills, drills, inserts, taps\n\n" +
      "Guidelines:\n" +
      "- Be concise and practical — operators need quick, actionable answers\n" +
      "- When answering about alarm codes: what it means, top 2–3 likely causes, first steps to resolve\n" +
      "- Format code with triple backticks and specify the dialect\n" +
      "- If a question involves safety risks, mention them clearly\n" +
      "- When uncertain, say so — do not guess critical safety or machine-specific information\n" +
      contextBlock;

    let result;
    try {
      result = await llmComplete({
        system:         systemPrompt,
        parts:          [{ kind: "text", text: question }],
        maxTokens:      1024,
        anthropicModel: "claude-haiku-4-5-20251001",
      });
    } catch (e) {
      await releaseUsage(admin, reservation.logId);
      console.error("ask-claude LLM failure:", e);
      return error(503, "ai_unavailable", "AI service temporarily unavailable");
    }
    await settleUsage(admin, reservation.logId, result.tokens);

    return json({ answer: result.text });
  } catch (e) {
    return internalError("ask-claude", e);
  }
});
