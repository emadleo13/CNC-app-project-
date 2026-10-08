// AI completions with automatic failover between Claude and free models.
//
// Every request tries Claude (Anthropic) first when ANTHROPIC_API_KEY is
// set, then the free OpenRouter models. Nothing is switched by hand:
// - Claude fails (credit used up, key revoked, overloaded, timeout): this
//   request is answered by a free model. Failures that would repeat (no
//   credit, bad key) also make this instance skip Claude for ten minutes,
//   then try it again. Topping up the Anthropic account therefore brings
//   Claude back by itself, without a deploy.
// - A free model is rate-limited, gone or writes garbled text: the next one
//   is tried (llm_free.ts).
//
// Secrets (Dashboard → Edge Functions → Secrets; no redeploy needed):
//   ANTHROPIC_API_KEY    enables Claude
//   OPENROUTER_API_KEY   enables the free models
//   AI_MODE              "auto" (default) or "free": never call Claude, for
//                        example to stop spending credit
//   CLAUDE_MODEL         optional: one Claude model for every task
//   OPENROUTER_MODEL     optional: the free model to try first
import { ACCOUNT_PAUSE_MS, claudeComplete, claudePause, describeClaudeError } from "./llm_claude.ts";
import { freeComplete } from "./llm_free.ts";
import { type LLMRequest, type LLMResult, RefusalError } from "./llm_types.ts";

export type { LLMRequest, LLMResult, Part, Turn } from "./llm_types.ts";
export { RefusalError } from "./llm_types.ts";

// The answer has to arrive before the app gives up: app versions before
// 1.3.0 wait 90 s, later ones say how long they wait (`clientTimeout`).
// Edge Functions themselves stop at about 150 s.
const DEFAULT_BUDGET_MS = 80_000;
const MAX_BUDGET_MS = 135_000;
// Claude may use most of the budget but always leaves the free models this
// much of it, up to FREE_RESERVE_MS.
const FREE_SHARE = 0.35;
const FREE_RESERVE_MS = 35_000;

/// How much of [budget] Claude may use: most of it, but the free models keep
/// their share.
export function claudeShare(budget: number): number {
  return budget - Math.min(FREE_RESERVE_MS, budget * FREE_SHARE);
}

/// Time for one request, from the seconds the client says it waits; 10 s
/// are left for the rest of the function and the network.
export function budgetFor(clientTimeoutSeconds: unknown): number {
  const wait = Number(clientTimeoutSeconds);
  if (!Number.isFinite(wait) || wait <= 0) return DEFAULT_BUDGET_MS;
  return Math.min(MAX_BUDGET_MS, Math.max(30_000, (wait - 10) * 1000));
}

/// Time as the Claude pause sees it. Replaceable in tests.
export const clock = { now: () => Date.now() };

let claudePausedUntil = 0;

export function claudeEnabled(): boolean {
  return !!Deno.env.get("ANTHROPIC_API_KEY") &&
    Deno.env.get("AI_MODE") !== "free" &&
    clock.now() >= claudePausedUntil;
}

export async function llmComplete(req: LLMRequest): Promise<LLMResult> {
  const start = Date.now();
  const budget = req.budgetMs ?? DEFAULT_BUDGET_MS;
  const deadline = start + budget;
  const failures: string[] = [];
  let rejected: LLMResult | null = null;

  if (claudeEnabled()) {
    try {
      const result = await claudeComplete(req, start + claudeShare(budget));
      if (!req.accept || req.accept(result.text)) {
        log(result, start);
        return result;
      }
      failures.push(`claude ${result.model}: reply rejected`);
      rejected = result;
    } catch (e) {
      if (e instanceof RefusalError) throw e;
      const pause = claudePause(e);
      if (pause > 0) claudePausedUntil = clock.now() + pause;
      failures.push(`claude: ${describeClaudeError(e)}`);
      console.warn(
        `ai: Claude failed (${describeClaudeError(e)}); ` +
          (pause >= ACCOUNT_PAUSE_MS ? `skipping it for ${pause / 60_000} min; ` : "") +
          "answering with a free model",
      );
    }
  }

  if (Deno.env.get("OPENROUTER_API_KEY")) {
    try {
      const result = await freeComplete(req, deadline);
      log(result, start);
      return result;
    } catch (e) {
      failures.push(String(e));
    }
  }

  if (rejected) return rejected;
  throw new Error(`No AI provider answered -- ${failures.join(" | ") || "none configured"}`);
}

function log(r: LLMResult, start: number) {
  console.log(
    `ai: ${r.provider} ${r.model} ${Date.now() - start} ms, ${r.tokens} tokens${r.truncated ? ", cut off" : ""}`,
  );
}
