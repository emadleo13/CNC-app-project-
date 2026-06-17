// Shared LLM helper.
//
// Routes completions to OpenRouter when OPENROUTER_API_KEY is set, otherwise to
// Anthropic (the default). This lets the app run on a free OpenRouter model
// while the Anthropic account is topped up — to switch back to Anthropic, just
// remove the OPENROUTER_API_KEY secret. No code change required.
//
// Optional: OPENROUTER_MODEL overrides the default free model.
import Anthropic from "npm:@anthropic-ai/sdk@0.30.0";

export type Part =
  | { kind: "text"; text: string }
  | { kind: "image"; mediaType: string; data: string } // base64
  | { kind: "pdf"; data: string };                      // base64

export interface LLMRequest {
  system?: string;
  parts: Part[];
  maxTokens: number;
  anthropicModel: string;
}

export interface LLMResult {
  text: string;
  tokens: number;
}

const OR_ENDPOINT = "https://openrouter.ai/api/v1/chat/completions";
const OR_DEFAULT_MODEL = "google/gemma-4-31b-it:free";

// Fallback chains of free models — tried in order when a model is rate-limited
// (429) or returns an empty/failed response. Vision models must be multimodal.
const OR_TEXT_MODELS = [
  "google/gemma-4-31b-it:free",
  "openai/gpt-oss-120b:free",
  "meta-llama/llama-3.3-70b-instruct:free",
  "qwen/qwen3-next-80b-a3b-instruct:free",
];
const OR_VISION_MODELS = [
  "google/gemma-4-31b-it:free",
  "google/gemma-4-26b-a4b-it:free",
  "nvidia/nemotron-nano-12b-v2-vl:free",
];

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export async function llmComplete(req: LLMRequest): Promise<LLMResult> {
  const orKey = Deno.env.get("OPENROUTER_API_KEY");
  return orKey ? viaOpenRouter(req, orKey) : viaAnthropic(req);
}

async function viaAnthropic(req: LLMRequest): Promise<LLMResult> {
  const client = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") ?? "" });
  const content = req.parts.map((p) => {
    if (p.kind === "text")  return { type: "text", text: p.text };
    if (p.kind === "image") return { type: "image", source: { type: "base64", media_type: p.mediaType, data: p.data } };
    return { type: "document", source: { type: "base64", media_type: "application/pdf", data: p.data } };
  });
  const message = await client.messages.create({
    model:      req.anthropicModel,
    max_tokens: req.maxTokens,
    ...(req.system ? { system: req.system } : {}),
    messages:   [{ role: "user", content: content as never }],
  });
  const text = message.content[0]?.type === "text" ? message.content[0].text : "";
  return { text, tokens: message.usage.input_tokens + message.usage.output_tokens };
}

async function viaOpenRouter(req: LLMRequest, key: string): Promise<LLMResult> {
  let hasPdf = false;
  let hasImage = false;
  const content = req.parts.map((p) => {
    if (p.kind === "text")  return { type: "text", text: p.text };
    if (p.kind === "image") { hasImage = true; return { type: "image_url", image_url: { url: `data:${p.mediaType};base64,${p.data}` } }; }
    hasPdf = true;
    return { type: "file", file: { filename: "document.pdf", file_data: `data:application/pdf;base64,${p.data}` } };
  });

  const messages: Array<Record<string, unknown>> = [];
  if (req.system) messages.push({ role: "system", content: req.system });
  messages.push({ role: "user", content });

  // Build the candidate model list: configured/default model first, then fallbacks.
  const configured = Deno.env.get("OPENROUTER_MODEL") ?? OR_DEFAULT_MODEL;
  const chain = (hasImage || hasPdf) ? OR_VISION_MODELS : OR_TEXT_MODELS;
  const candidates = [configured, ...chain.filter((m) => m !== configured)];

  let lastErr = "";
  for (const model of candidates) {
    for (let attempt = 0; attempt < 2; attempt++) {
      const payload: Record<string, unknown> = { model, max_tokens: req.maxTokens, messages };
      if (hasPdf) payload.plugins = [{ id: "file-parser", pdf: { engine: "pdf-text" } }];

      const resp = await fetch(OR_ENDPOINT, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${key}`,
          "Content-Type":  "application/json",
          "HTTP-Referer":  "https://cncassist.app",
          "X-Title":       "CNC Assist",
        },
        body: JSON.stringify(payload),
      });

      if (resp.status === 429 || resp.status >= 500) {
        lastErr = `OpenRouter ${resp.status} on ${model}: ${(await resp.text()).slice(0, 200)}`;
        if (attempt === 0) { await sleep(1500); continue; } // quick retry, then next model
        break;
      }
      if (!resp.ok) {
        lastErr = `OpenRouter ${resp.status} on ${model}: ${(await resp.text()).slice(0, 200)}`;
        break; // non-retryable (e.g. 400/404) — try next model
      }

      const data = await resp.json();
      const raw = data.choices?.[0]?.message?.content;
      const text = typeof raw === "string" ? raw : "";
      if (!text.trim()) { lastErr = `Empty response from ${model}`; break; }
      const tokens = data.usage?.total_tokens ??
        ((data.usage?.prompt_tokens ?? 0) + (data.usage?.completion_tokens ?? 0));
      return { text, tokens };
    }
  }
  throw new Error(lastErr || "OpenRouter: all candidate models failed");
}
