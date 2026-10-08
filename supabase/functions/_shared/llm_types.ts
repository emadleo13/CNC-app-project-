// Types shared by the AI router (llm.ts) and its providers.
import type { Lang } from "./language.ts";

export type Part =
  | { kind: "text"; text: string }
  | { kind: "image"; mediaType: string; data: string } // base64
  | { kind: "pdf"; data: string };                      // base64

/// An earlier turn of the conversation.
export interface Turn {
  role: "user" | "assistant";
  text: string;
}

export interface LLMRequest {
  system?: string;
  /// Earlier turns, oldest first: starts with a user turn, alternates, and
  /// ends with an assistant turn (see historyFrom).
  history?: Turn[];
  /// The new user message.
  parts: Part[];
  /// Room for the visible answer. Claude models that think get more.
  maxTokens: number;
  /// Claude model for this task, unless the CLAUDE_MODEL secret overrides it.
  claudeModel: string;
  /// How hard a thinking Claude model works on it (ignored by Haiku).
  effort?: "low" | "medium" | "high";
  /// Language the answer must be in. A free-model reply that drifts into
  /// other scripts is retried on the next model.
  language: Lang | null;
  /// The reply must be a single JSON object.
  json?: boolean;
  /// Extra test of a reply, e.g. that its JSON parses. A rejected reply
  /// makes the next model try.
  accept?: (text: string) => boolean;
  /// Time for the whole request in ms (budgetFor); 80 s by default.
  budgetMs?: number;
}

export interface LLMResult {
  text: string;
  tokens: number;
  provider: "claude" | "free";
  model: string;
  /// The answer hit the output limit and is cut off.
  truncated: boolean;
}

/// Claude declined the request for safety reasons. Not retried on another
/// provider: routing around a safety decision is not what failover is for.
export class RefusalError extends Error {
  constructor(readonly category: string | null) {
    super(`Claude declined the request (${category ?? "no category"})`);
  }
}
