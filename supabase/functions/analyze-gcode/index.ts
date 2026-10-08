import { budgetFor, llmComplete, RefusalError } from "../_shared/llm.ts";
import { adminClient, requireUser } from "../_shared/auth.ts";
import { isPro } from "../_shared/entitlement.ts";
import { error, internalError, json, preflight } from "../_shared/http.ts";
import { releaseUsage, reserveUsage, settleUsage } from "../_shared/quota.ts";
import { MAX_FINDINGS, normalise, parseReply } from "../_shared/gcode_review.ts";
import { isLang, LANGUAGE_NAMES } from "../_shared/language.ts";
import { tidyAnswer } from "../_shared/answer_style.ts";

interface AnalyzeRequest {
  gcode:     string;
  dialect?:  string;
  /// App language for the review text: en | fa | ro | ar.
  language?: string;
  /// What the app's own rule checker already reported, "L12: message" lines.
  localFindings?: string[];
  /// Seconds the app waits for the answer (sent from 1.3.0; 1.2.0 waits 120).
  clientTimeout?: number;
}

// AI second opinion on a program. The app checks every line itself; this
// returns only what an experienced programmer would flag, with line numbers
// that refer to the numbered program sent to the model.
//
// Response: { summary, operation_type, findings: [{line, severity, issue,
// suggestion}], suggestions: [] }. Asking for an entry per line (the previous
// design) overflowed the output limit on any real program.
Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;

  try {
    const user = await requireUser(req);
    if (user instanceof Response) return user;

    const body: AnalyzeRequest = await req.json();
    const gcode = body.gcode;
    const dialect = body.dialect === "sinumerik" ? "sinumerik" : body.dialect === "generic" ? "generic" : "haas";
    const lang = isLang(body.language) ? body.language : "en";
    const language = LANGUAGE_NAMES[lang];

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
      ? `The program is Siemens Sinumerik 840D/828D code.
- Comments start with ';'. Parentheses belong to the code: CYCLE83(...), X=IC(5).
- Cycles: CYCLE81/82/83/84/840/85/86; MCALL makes a cycle modal.
- Tool: T... D... (D applies the tool offsets), M6 changes the tool.
- Units are usually set by machine data; G70/G71/G700/G710 change them.`
      : `The program is ${dialect === "haas" ? "Haas" : "Fanuc / ISO"} code.
- Comments are in parentheses.
- Tool change T.. M06 stops the spindle; length offset G43 H.. normally matches the tool.
- Canned cycles G73/G81-G89 need Z and R; G80 or a G00/G01 cancels them.
- G28 G91 Z0. is the safe home move; G28 in G90 passes through the given point first.`;

    const localBlock = body.localFindings?.length
      ? `\n\nThe app's rule checker already reported these, so do not repeat them unless you can add something important:\n${body.localFindings.slice(0, 60).join("\n").substring(0, 4000)}`
      : "";

    const systemPrompt = `You are a senior CNC programmer reviewing a program before it runs on a real machine.
${dialectGuide}

Reply with ONE JSON object and nothing else:
{
  "summary": "2-4 sentences: what the program does (operations, tools, approximate stock or features)",
  "operation_type": "milling|turning|drilling|tapping|multi",
  "findings": [
    { "line": 12, "severity": "error|warning", "issue": "what is wrong", "suggestion": "how to fix it" }
  ],
  "suggestions": ["general improvements, at most 5"]
}

Rules:
- Line numbers refer to the numbered program in the user message.
- Report only real problems that could crash the machine, scrap the part, raise an alarm, or that clearly deviate from good practice. At most ${MAX_FINDINGS} findings, most serious first. An empty list is fine.
- "error" = will alarm, crash or cut wrong. "warning" = risky or bad practice.
- Keep each issue and suggestion to one short sentence (about 20 words), and the summary to at most 3 sentences.
- If something depends on machine settings you cannot see, say so instead of guessing.
- Never state that the program is safe to run.
- Write summary, issue, suggestion and suggestions in ${language} only, never mixing in other languages. Keep G-code words exactly as written (G43, H01, M03).${localBlock}`;

    const numbered = gcode.split(/\r?\n/).map((l, i) => `${i + 1}: ${l}`).join("\n");

    let responseText: string;
    let tokens: number;
    try {
      ({ text: responseText, tokens } = await llmComplete({
        system: systemPrompt,
        parts:  [{ kind: "text", text: `Review this ${dialect.toUpperCase()} program:\n\n${numbered}` }],
        maxTokens:   4000,
        claudeModel: "claude-sonnet-5-5",
        effort:      "medium",
        language:    lang,
        json:        true,
        accept:      (text) => parseReply(text) !== null,
        // App 1.2.0 already waits 120 s for a review.
        budgetMs:    budgetFor(body.clientTimeout ?? 120),
      }));
    } catch (e) {
      await releaseUsage(admin, reservation.logId);
      if (e instanceof RefusalError) return error(422, "ai_refused", "The AI declined to review this program");
      console.error("analyze-gcode LLM failure:", e);
      return error(503, "ai_unavailable", "AI service temporarily unavailable");
    }
    await settleUsage(admin, reservation.logId, tokens);

    const parsed = parseReply(responseText);
    if (!parsed) {
      console.error("analyze-gcode unparseable reply:", responseText.substring(0, 500));
      return error(502, "ai_bad_response", "Failed to parse AI response");
    }
    const lineCount = gcode.split(/\r?\n/).length;

    // The program itself is not stored: usage and token cost are already in
    // qa_logs, and users' G-code stays theirs.
    // The app shows these as plain text.
    const review = normalise(parsed, lineCount);
    const tidy = (s: string) => tidyAnswer(s, lang, "text");
    return json({
      ...review,
      summary:     tidy(review.summary),
      findings:    review.findings.map((f) => ({ ...f, issue: tidy(f.issue), suggestion: tidy(f.suggestion) })),
      suggestions: review.suggestions.map(tidy),
    });
  } catch (e) {
    return internalError("analyze-gcode", e);
  }
});
