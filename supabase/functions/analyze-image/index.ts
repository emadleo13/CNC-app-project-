import { budgetFor, llmComplete, RefusalError } from "../_shared/llm.ts";
import { adminClient, requireUser } from "../_shared/auth.ts";
import { isPro } from "../_shared/entitlement.ts";
import { error, internalError, json, preflight } from "../_shared/http.ts";
import { releaseUsage, reserveUsage, settleUsage } from "../_shared/quota.ts";
import { answerFormat, gcodeCommentRule, styleRules } from "../_shared/answer_style.ts";
import { answerLanguage } from "../_shared/language.ts";

const MEDIA_TYPES = ["image/jpeg", "image/png", "image/webp"];

interface AnalyzeImageRequest {
  imageBase64: string;
  mediaType:   "image/jpeg" | "image/png" | "image/webp";
  mode:        "error_diagnosis" | "drawing_to_gcode";
  question?:   string;
  dialect?:    string;
  /// App language, en | fa | ro | ar (app 1.3.0+).
  language?:   string;
  /// "markdown" when the app renders Markdown (app 1.3.0+).
  format?:     string;
  /// Seconds the app waits for the answer (app 1.3.0+; earlier: 90).
  clientTimeout?: number;
}

const ERROR_SYSTEM = `You are an expert CNC machine technician and controller specialist.
The user will show you a photo of a CNC machine control panel, screen, or display showing an error, alarm, or fault message.

Your task:
1. Identify the exact alarm code and message visible in the image
2. Explain clearly what this alarm means
3. List the 2-3 most likely causes
4. Provide step-by-step troubleshooting instructions
5. Note any safety considerations before attempting repair

Be specific and practical — operators need to resolve this quickly.
If the image is unclear or doesn't show a CNC alarm, say so and ask for a clearer photo.
Use these sections, with their titles in the answer's language: Alarm Identified / What It Means / Likely Causes / How to Fix / Safety Notes.`;

const DRAWING_SYSTEM = `You are an expert CNC programmer with deep knowledge of Haas and Siemens Sinumerik controllers.
The user will show you a technical drawing, engineering sketch, or photo of a machined part.

Your task:
1. Analyze visible dimensions, tolerances, surface finish requirements, and features
2. Write a complete draft CNC G-code program for machining this part. It is a
   starting point that a programmer will check, never a program to run as is.
3. Use the dialect specified by the user (Haas or Sinumerik)
4. Include:
   - First line after the program number: (VERIFY BEFORE RUNNING: GRAPHICS, DRY RUN, SINGLE BLOCK)
   - Program header with setup notes and every assumption you made
   - A full safe-start line (units G21 or G20, plane, G40, G49, G80, G90)
   - Tool list with recommended types (endmill, drill, etc.)
   - Work offset setup (G54), and tool length compensation (G43 H) on Haas
   - Spindle start before every cutting move; speeds and feeds stated as estimates
   - Operations in logical order (roughing → finishing → holes)
   - Program footer: G80/G40, retract to a safe height or G28 G91 Z0., spindle and coolant off, M30

Format the G-code cleanly with comments.
If a dimension is not visible, say what you assumed instead of guessing silently.
If the image is not a technical drawing or part photo, ask the user to provide one.`;

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;

  try {
    const user = await requireUser(req);
    if (user instanceof Response) return user;

    const body: AnalyzeImageRequest = await req.json();
    const { imageBase64, mediaType = "image/jpeg", mode, question, dialect = "haas" } = body;

    if (!imageBase64 || imageBase64.length === 0) {
      return error(400, "bad_request", "No image provided");
    }
    if (imageBase64.length > 7_000_000) {
      return error(400, "too_large", "Image too large. Please use a smaller photo.");
    }
    if (!MEDIA_TYPES.includes(mediaType)) {
      return error(400, "bad_request", "Unsupported image type");
    }
    if (mode !== "error_diagnosis" && mode !== "drawing_to_gcode") {
      return error(400, "bad_request", "Unknown mode");
    }

    const isError   = mode === "error_diagnosis";
    const safeDialect = dialect === "sinumerik" ? "SINUMERIK" : "HAAS";
    const language  = answerLanguage(question ?? "", body.language);
    const format    = answerFormat(body.format);
    const system    = isError
      ? `${ERROR_SYSTEM}\n\n${styleRules(language, format, false)}`
      : `${DRAWING_SYSTEM}\n\n${styleRules(language, format, false)}\n${gcodeCommentRule(language)}`;

    const userText = isError
      ? (question?.trim().substring(0, 2000) || "What CNC alarm or error is shown in this image? Diagnose it and provide solutions.")
      : `Generate ${safeDialect} G-code for the part shown in this technical drawing.`;

    // Image calls count toward the free monthly limit.
    const admin = adminClient();
    const reservation = await reserveUsage(admin, user.id, await isPro(admin, user.id), {
      question_excerpt: `[image:${mode}] ${userText.substring(0, 100)}`,
      is_image:         true,
    });
    if (reservation instanceof Response) return reservation;

    let result;
    try {
      result = await llmComplete({
        system,
        parts: [
          { kind: "image", mediaType, data: imageBase64 },
          { kind: "text",  text: userText },
        ],
        maxTokens:   isError ? 2000 : 6000,
        claudeModel: "claude-sonnet-5-5",
        effort:      "low",
        language,
        budgetMs:    budgetFor(body.clientTimeout),
      });
    } catch (e) {
      await releaseUsage(admin, reservation.logId);
      if (e instanceof RefusalError) return error(422, "ai_refused", "The AI declined to answer this request");
      console.error("analyze-image LLM failure:", e);
      return error(503, "ai_unavailable", "AI service temporarily unavailable");
    }
    await settleUsage(admin, reservation.logId, result.tokens);

    return json({ answer: result.text, provider: result.provider, truncated: result.truncated });
  } catch (e) {
    return internalError("analyze-image", e);
  }
});
