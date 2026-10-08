// Claude (Anthropic) provider for the AI router.
import Anthropic from "npm:@anthropic-ai/sdk@0.131.0";
import { type LLMRequest, type LLMResult, type Part, RefusalError } from "./llm_types.ts";

/// How long Claude is skipped after a failure that will repeat on every
/// request: no credit, revoked key, no access.
export const ACCOUNT_PAUSE_MS = 10 * 60_000;
/// ...and after one that usually clears quickly: rate limit, overload,
/// network trouble, timeout.
export const BUSY_PAUSE_MS = 60_000;

// Models that decline on safety grounds can re-run a declined request on the
// model Anthropic recommends for that category, inside the same call.
const FALLBACK_BETA = "server-side-fallback-2026-07-01";
const FALLBACK_MODELS = new Set(["claude-sonnet-5-5", "claude-opus-5-5", "claude-opus-5", "claude-fable-5-1"]);
// Set when the account turns out not to accept that beta, so it is not sent
// again by this instance.
let fallbackBetaRejected = false;

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/// Answers [req] with Claude, giving up at [deadline] (epoch ms).
export async function claudeComplete(req: LLMRequest, deadline: number): Promise<LLMResult> {
  const model = Deno.env.get("CLAUDE_MODEL") || req.claudeModel;
  const client = new Anthropic({
    apiKey: Deno.env.get("ANTHROPIC_API_KEY"),
    // The router falls back to the free models instead of waiting on retries.
    maxRetries: 0,
  });

  // Haiku 4.5 does not think and rejects `effort`. The current Sonnet and
  // Opus models always think, and thinking counts toward max_tokens.
  const thinks = !model.startsWith("claude-haiku");
  const params: Anthropic.MessageCreateParamsNonStreaming = {
    model,
    max_tokens: thinks ? Math.max(16000, req.maxTokens) : req.maxTokens,
    ...(req.system ? { system: req.system } : {}),
    messages: [
      ...(req.history ?? []).map((t): Anthropic.MessageParam => ({ role: t.role, content: t.text })),
      { role: "user", content: req.parts.map(toBlock) },
    ],
    ...(thinks ? { output_config: { effort: req.effort ?? "low" } } : {}),
  };

  const message = await send(client, params, deadline);
  if (message.stop_reason === "refusal") {
    throw new RefusalError(message.stop_details?.category ?? null);
  }
  const text = message.content
    .map((b) => (b.type === "text" ? b.text : ""))
    .join("")
    .trim();
  const u = message.usage;
  return {
    text,
    tokens: u.input_tokens + u.output_tokens + (u.cache_read_input_tokens ?? 0) + (u.cache_creation_input_tokens ?? 0),
    provider: "claude",
    model: message.model,
    truncated: message.stop_reason === "max_tokens",
  };
}

/// One call, retried once after a brief pause when Claude is rate-limited or
/// overloaded and there is time for it. Timeouts and network errors are not
/// retried: the time is better spent on the free models.
async function send(client: Anthropic, params: Anthropic.MessageCreateParamsNonStreaming, deadline: number) {
  for (let attempt = 0; ; attempt++) {
    try {
      return await sendOnce(client, params, deadline);
    } catch (e) {
      const transient = e instanceof Anthropic.RateLimitError || e instanceof Anthropic.InternalServerError;
      if (!transient || attempt > 0 || deadline - Date.now() < 30_000) throw e;
      await sleep(1000);
    }
  }
}

async function sendOnce(client: Anthropic, params: Anthropic.MessageCreateParamsNonStreaming, deadline: number) {
  const options = () => ({ timeout: Math.max(1_000, deadline - Date.now()) });
  if (!FALLBACK_MODELS.has(params.model) || fallbackBetaRejected) {
    return await client.messages.create(params, options());
  }
  try {
    return await client.beta.messages.create({ ...params, betas: [FALLBACK_BETA], fallbacks: "default" }, options());
  } catch (e) {
    if (!(e instanceof Anthropic.BadRequestError)) throw e;
    // Either the request itself is invalid or this account lacks the beta.
    // Only a plain request can tell which.
    const plain = await client.messages.create(params, options());
    fallbackBetaRejected = true;
    console.warn(`ai: ${FALLBACK_BETA} rejected (${e.message}); sending requests without it`);
    return plain;
  }
}

function toBlock(p: Part): Anthropic.ContentBlockParam {
  if (p.kind === "text") return { type: "text", text: p.text };
  if (p.kind === "image") {
    return {
      type: "image",
      source: { type: "base64", media_type: p.mediaType as "image/jpeg" | "image/png" | "image/webp", data: p.data },
    };
  }
  return { type: "document", source: { type: "base64", media_type: "application/pdf", data: p.data } };
}

/// How long to skip Claude after [e]; 0 when only this request was at fault
/// (for example an image the API rejects).
export function claudePause(e: unknown): number {
  if (e instanceof Anthropic.AuthenticationError || e instanceof Anthropic.PermissionDeniedError) return ACCOUNT_PAUSE_MS;
  if (e instanceof Anthropic.RateLimitError || e instanceof Anthropic.InternalServerError) return BUSY_PAUSE_MS;
  // Includes timeouts (APIConnectionTimeoutError is a subclass).
  if (e instanceof Anthropic.APIConnectionError) return BUSY_PAUSE_MS;
  // 402 billing_error: the credit balance is used up.
  if (e instanceof Anthropic.APIError && (e.status === 402 || e.type === "billing_error")) return ACCOUNT_PAUSE_MS;
  return 0;
}

/// Short description for the logs: status and error type, never the key.
export function describeClaudeError(e: unknown): string {
  if (e instanceof Anthropic.APIConnectionError) return `${e.constructor.name}: ${e.message}`;
  if (e instanceof Anthropic.APIError) return `HTTP ${e.status} ${e.type ?? ""}: ${e.message}`.slice(0, 300);
  return String(e).slice(0, 300);
}
