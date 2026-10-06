import { llmComplete } from "../_shared/llm.ts";
import { adminClient, requireUser } from "../_shared/auth.ts";
import { isPro } from "../_shared/entitlement.ts";
import { error, internalError, json, preflight } from "../_shared/http.ts";
import { releaseUsage, reserveUsage, settleUsage } from "../_shared/quota.ts";

interface PdfRequest {
  pdfBase64: string;
  question?: string;
  dialect?:  string;
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
      "2. Generate a complete CNC G-code program (well-commented, ready to run)\n" +
      "3. Include: program header, tool list, work offset setup, operations in order, footer\n" +
      "4. State assumptions clearly when dimensions are not visible\n" +
      "If not a technical drawing, extract and summarize CNC-relevant information.";

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
        maxTokens:      4096,
        anthropicModel: "claude-sonnet-4-6",
      });
    } catch (e) {
      await releaseUsage(admin, reservation.logId);
      console.error("analyze-pdf LLM failure:", e);
      return error(503, "ai_unavailable", "AI service temporarily unavailable");
    }
    await settleUsage(admin, reservation.logId, result.tokens);

    return json({ answer: result.text });
  } catch (e) {
    return internalError("analyze-pdf", e);
  }
});
