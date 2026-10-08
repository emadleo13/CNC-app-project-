// Free models on OpenRouter, the AI router's fallback provider.
import { foreignScore, GARBLED_SCORE, stripThinking } from "./language.ts";
import type { LLMRequest, LLMResult, Part } from "./llm_types.ts";

const ENDPOINT = "https://openrouter.ai/api/v1/chat/completions";

// Tried in order. OpenRouter rotates its free models: an ID that is gone
// returns 404, is skipped for the rest of the instance's life and logged, so
// the logs say when this list needs updating. Check the current free models
// at https://openrouter.ai/api/v1/models (IDs ending in ":free").
// Last checked: 2026-10-08.
export const TEXT_MODELS = [
  "google/gemma-4-31b-it:free",
  "nvidia/nemotron-3-ultra-550b-a55b:free",
  "thinkingmachines/inkling:free",
  "nvidia/nemotron-3-super-120b-a12b:free",
  "google/gemma-4-26b-a4b-it:free",
];
// Must accept images. PDFs use this list too, as they always have; OpenRouter's
// file parser hands their text to the model.
export const VISION_MODELS = [
  "google/gemma-4-31b-it:free",
  "thinkingmachines/inkling:free",
  "thinkingmachines/inkling-small:free",
  "google/gemma-4-26b-a4b-it:free",
  "dots-studio/dots-3-note-preview:free",
];
// OpenRouter's own router: picks whichever free model is up. Last, because
// its choice, and so the quality, varies from call to call.
export const ANY_FREE_MODEL = "openrouter/free";

const ATTEMPT_TIMEOUT_MS = 45_000;
// Not worth starting another model with less time than this left.
const MIN_ATTEMPT_MS = 8_000;

const goneModels = new Set<string>();

export async function freeComplete(req: LLMRequest, deadline: number): Promise<LLMResult> {
  const key = Deno.env.get("OPENROUTER_API_KEY") ?? "";
  const hasImage = req.parts.some((p) => p.kind === "image");
  const hasPdf = req.parts.some((p) => p.kind === "pdf");
  const configured = Deno.env.get("OPENROUTER_MODEL");
  const chain = hasImage || hasPdf ? VISION_MODELS : TEXT_MODELS;
  const candidates = [...new Set([configured, ...chain, ANY_FREE_MODEL])]
    .filter((m): m is string => !!m && !goneModels.has(m));
  const messages = toMessages(req);

  const failures: string[] = [];
  let best: { result: LLMResult; score: number } | null = null;
  for (const model of candidates) {
    const left = deadline - Date.now();
    if (left < MIN_ATTEMPT_MS) {
      failures.push("out of time");
      break;
    }

    const payload: Record<string, unknown> = {
      model,
      messages,
      max_tokens: req.maxTokens,
      // OpenRouter's default of 1.0 is what makes weak models wander into
      // other languages mid-sentence.
      temperature: req.json ? 0.2 : 0.3,
      top_p: 0.9,
      // Reasoning models: think briefly, and keep the reasoning out of the answer.
      reasoning: { effort: "low", exclude: true },
      ...(req.json ? { response_format: { type: "json_object" } } : {}),
      ...(hasPdf ? { plugins: [{ id: "file-parser", pdf: { engine: "pdf-text" } }] } : {}),
    };

    let resp: Response;
    try {
      resp = await fetch(ENDPOINT, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${key}`,
          "Content-Type":  "application/json",
          "HTTP-Referer":  "https://cncassist.app",
          "X-Title":       "CNC Assist",
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(Math.min(ATTEMPT_TIMEOUT_MS, left - 2_000)),
      });
    } catch (e) {
      failures.push(`${model} -> ${e instanceof Error ? e.name : e}`);
      continue;
    }

    if (!resp.ok) {
      failures.push(`${model} -> HTTP ${resp.status}: ${(await resp.text()).slice(0, 160)}`);
      if (resp.status === 404) {
        goneModels.add(model);
        console.warn(`ai: free model ${model} is gone (404); update TEXT_MODELS / VISION_MODELS in llm_free.ts`);
      }
      continue; // rate-limited (429), down (5xx), refused (400/403): next model
    }

    const data = await resp.json().catch(() => null);
    const choice = data?.choices?.[0];
    const raw = choice?.message?.content;
    const text = stripThinking(typeof raw === "string" ? raw : "");
    if (!text) {
      failures.push(`${model} -> empty reply`);
      continue;
    }

    const usage = data?.usage ?? {};
    const result: LLMResult = {
      text,
      tokens: usage.total_tokens ?? (usage.prompt_tokens ?? 0) + (usage.completion_tokens ?? 0),
      provider: "free",
      model: typeof data?.model === "string" ? data.model : model,
      truncated: choice?.finish_reason === "length",
    };
    const rejected = req.accept && !req.accept(text);
    const score = foreignScore(text, req.language) + (rejected ? 1000 : 0);
    if (score < GARBLED_SCORE) return result;

    failures.push(`${model} -> ${rejected ? "reply rejected" : `garbled (${score} stray characters)`}`);
    if (!best || score < best.score) best = { result, score };
  }

  // Every model drifted into other languages: the least garbled reply still
  // beats no answer. A reply that failed `accept` is returned too; the
  // caller's own validation decides what to tell the user.
  if (best) {
    console.warn(`ai: no clean free reply, returning the best one -- ${failures.join(" | ")}`);
    return best.result;
  }
  throw new Error(`OpenRouter: no free model answered -- ${failures.join(" | ") || "no candidates"}`);
}

function toMessages(req: LLMRequest): Array<Record<string, unknown>> {
  const messages: Array<Record<string, unknown>> = [];
  if (req.system) messages.push({ role: "system", content: req.system });
  for (const t of req.history ?? []) messages.push({ role: t.role, content: t.text });
  const textOnly = req.parts.every((p) => p.kind === "text");
  messages.push({
    role: "user",
    // Plain text as a string: some free endpoints mishandle a content array.
    content: textOnly ? req.parts.map((p) => (p as { text: string }).text).join("\n\n") : req.parts.map(toPart),
  });
  return messages;
}

function toPart(p: Part): Record<string, unknown> {
  if (p.kind === "text") return { type: "text", text: p.text };
  if (p.kind === "image") return { type: "image_url", image_url: { url: `data:${p.mediaType};base64,${p.data}` } };
  return { type: "file", file: { filename: "document.pdf", file_data: `data:application/pdf;base64,${p.data}` } };
}
