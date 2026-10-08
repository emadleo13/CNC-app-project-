import { budgetFor, llmComplete, RefusalError } from "../_shared/llm.ts";
import { adminClient, requireUser } from "../_shared/auth.ts";
import { isPro } from "../_shared/entitlement.ts";
import { error, internalError, json, preflight } from "../_shared/http.ts";
import { releaseUsage, reserveUsage, settleUsage } from "../_shared/quota.ts";
import { answerFormat, gcodeCommentRule, styleRules, tidyAnswer } from "../_shared/answer_style.ts";
import { answerLanguage } from "../_shared/language.ts";

interface PdfRequest {
  pdfBase64: string;
  question?: string;
  dialect?:  string;
  /// App language, en | fa | ro | ar (app 1.3.0+).
  language?: string;
  /// "markdown" when the app renders Markdown (app 1.3.0+).
  format?:   string;
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
      // pro_required stays in the body: app versions up to 1.1.6 look for it.
      return error(403, "pro_required", "Pro subscription required", { pro_required: true });
    }

    const body: PdfRequest = await req.json();
    const { pdfBase64, question, dialect = "haas" } = body;
    const language = answerLanguage(question ?? "", body.language);
    const format = answerFormat(body.format);

    if (!pdfBase64 || pdfBase64.length === 0) {
      return error(400, "bad_request", "No PDF provided");
    }
    // ~10MB limit for PDF base64
    if (pdfBase64.length > 14_000_000) {
      return error(400, "too_large", "PDF too large. Max 10MB.");
    }

    const safeDialect = dialect === "sinumerik" ? "SINUMERIK" : "HAAS";
    const userQuestion = question?.trim().substring(0, 2000) ||
      `Analyze this technical drawing and generate ${safeDialect} G-code for machining the part shown. Include tool list, work offsets, feeds and speeds.`;

    const systemPrompt =
      "You are an expert CNC programmer analyzing technical drawings and engineering documents.\n" +
      "When given a technical drawing or part specification:\n" +
      "1. Identify visible dimensions, tolerances, surface finish, and features\n" +
      "2. Write a complete draft CNC G-code program, well commented. It is a starting point a programmer will check, never a program to run as is.\n" +
      "3. Include: (VERIFY BEFORE RUNNING: GRAPHICS, DRY RUN, SINGLE BLOCK) after the program number, a full safe-start line with units, tool list, work offset, spindle start before every cut, operations in order, and a safe footer ending in M30\n" +
      "4. State assumptions clearly when dimensions are not visible\n" +
      "If not a technical drawing, extract and summarize CNC-relevant information.\n\n" +
      styleRules(language, format, false) + "\n" +
      gcodeCommentRule(language);

    const reservation = await reserveUsage(admin, user.id, pro, {
      question_excerpt: `[pdf] ${userQuestion.substring(0, 200)}`,
      is_image:         true,
    });
    if (reservation instanceof Response) return reservation;

    let result;
    try {
      result = await llmComplete({
        system: systemPrompt,
        parts: [
          { kind: "pdf",  data: pdfBase64 },
          { kind: "text", text: userQuestion },
        ],
        maxTokens:   6000,
        claudeModel: "claude-sonnet-5-5",
        effort:      "low",
        language,
        budgetMs:    budgetFor(body.clientTimeout),
      });
    } catch (e) {
      await releaseUsage(admin, reservation.logId);
      if (e instanceof RefusalError) return error(422, "ai_refused", "The AI declined to answer this request");
      console.error("analyze-pdf LLM failure:", e);
      return error(503, "ai_unavailable", "AI service temporarily unavailable");
    }
    await settleUsage(admin, reservation.logId, result.tokens);

    return json({ answer: tidyAnswer(result.text, language, format), provider: result.provider, truncated: result.truncated });
  } catch (e) {
    return internalError("analyze-pdf", e);
  }
});
