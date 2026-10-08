import { budgetFor, llmComplete, RefusalError } from "../_shared/llm.ts";
import { adminClient, requireUser } from "../_shared/auth.ts";
import { isPro } from "../_shared/entitlement.ts";
import { error, internalError, json, preflight } from "../_shared/http.ts";
import { releaseUsage, reserveUsage, settleUsage } from "../_shared/quota.ts";
import { answerFormat, historyFrom, styleRules } from "../_shared/answer_style.ts";
import { answerLanguage } from "../_shared/language.ts";

interface AskRequest {
  question:      string;
  alarmContext?: string;
  /// App language, en | fa | ro | ar (app 1.3.0+).
  language?:     string;
  /// "markdown" when the app renders Markdown (app 1.3.0+).
  format?:       string;
  /// Earlier turns of this chat, oldest first: [{role, content}] (app 1.3.0+).
  history?:      unknown;
  /// Seconds the app waits for the answer (app 1.3.0+; earlier: 90).
  clientTimeout?: number;
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

    const language = answerLanguage(question, body.language);
    const contextBlock = alarmContext
      ? `\n\nThe app found this alarm data in its local database for the question:\n${alarmContext}\n` +
        "Use it for a specific, accurate answer about this alarm code."
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
      "- Give cutting data as starting values with a range, and say what to watch and adjust on the machine\n" +
      "- If a question involves safety risks, mention them clearly\n" +
      "- When uncertain, say so — do not guess critical safety or machine-specific information\n\n" +
      styleRules(language, answerFormat(body.format), true) +
      contextBlock;

    let result;
    try {
      result = await llmComplete({
        system:      systemPrompt,
        history:     historyFrom(body.history),
        parts:       [{ kind: "text", text: question }],
        maxTokens:   2500,
        claudeModel: "claude-haiku-4-5",
        language,
        budgetMs:    budgetFor(body.clientTimeout),
      });
    } catch (e) {
      await releaseUsage(admin, reservation.logId);
      if (e instanceof RefusalError) return error(422, "ai_refused", "The AI declined to answer this question");
      console.error("ask-claude LLM failure:", e);
      return error(503, "ai_unavailable", "AI service temporarily unavailable");
    }
    await settleUsage(admin, reservation.logId, result.tokens);

    return json({ answer: result.text, provider: result.provider, truncated: result.truncated });
  } catch (e) {
    return internalError("ask-claude", e);
  }
});
