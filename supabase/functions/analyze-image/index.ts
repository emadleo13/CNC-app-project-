import { llmComplete } from "../_shared/llm.ts";
import { adminClient, requireUser } from "../_shared/auth.ts";
import { isPro } from "../_shared/entitlement.ts";
import { error, internalError, json, preflight } from "../_shared/http.ts";
import { releaseUsage, reserveUsage, settleUsage } from "../_shared/quota.ts";

const MEDIA_TYPES = ["image/jpeg", "image/png", "image/webp"];

interface AnalyzeImageRequest {
  imageBase64: string;
  mediaType:   "image/jpeg" | "image/png" | "image/webp";
  mode:        "error_diagnosis" | "drawing_to_gcode";
  question?:   string;
  dialect?:    string;
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
Format your response with clear sections: Alarm Identified / What It Means / Likely Causes / How to Fix / Safety Notes.`;

const DRAWING_SYSTEM = `You are an expert CNC programmer with deep knowledge of Haas and Siemens Sinumerik controllers.
The user will show you a technical drawing, engineering sketch, or photo of a machined part.

Your task:
1. Analyze visible dimensions, tolerances, surface finish requirements, and features
2. Generate a complete, ready-to-run CNC G-code program for machining this part
3. Use the dialect specified by the user (Haas or Sinumerik)
4. Include:
   - Program header with setup notes
   - Tool list with recommended types (endmill, drill, etc.)
   - Work offset setup (G54)
   - Spindle speeds and feed rates (suggest based on steel/aluminum)
   - Operations in logical order (roughing → finishing → holes)
   - Program footer with tool retract and spindle stop

Format the G-code cleanly with inline comments on each line.
State assumptions if dimensions are not fully visible.
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
    const maxTokens = isError ? 1024 : 4096;
    const system    = isError ? ERROR_SYSTEM : DRAWING_SYSTEM;
    const safeDialect = dialect === "sinumerik" ? "SINUMERIK" : "HAAS";

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
        maxTokens,
        anthropicModel: "claude-sonnet-4-6",
      });
    } catch (e) {
      await releaseUsage(admin, reservation.logId);
      console.error("analyze-image LLM failure:", e);
      return error(503, "ai_unavailable", "AI service temporarily unavailable");
    }
    await settleUsage(admin, reservation.logId, result.tokens);

    return json({ answer: result.text });
  } catch (e) {
    return internalError("analyze-image", e);
  }
});
