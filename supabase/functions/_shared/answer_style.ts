// How answers are written: language, layout, chat history. Shared by every
// function that returns text to the app.
import { type Lang, LANGUAGE_NAMES } from "./language.ts";
import type { Turn } from "./llm_types.ts";

/// "markdown": the app renders Markdown (1.3.0 and later ask for it).
/// "text": earlier versions show the answer as it is.
export type AnswerFormat = "markdown" | "text";

export function answerFormat(v: unknown): AnswerFormat {
  return v === "markdown" ? "markdown" : "text";
}

const PERSIAN_TERMS =
  "Use the machining terms Iranian operators use, for example دور اسپیندل، پیشروی، عمق برش، قطر ابزار، بار براده (chip load).";

/// Rules appended to a system prompt. [brief] asks for a short answer, for
/// questions rather than programs.
export function styleRules(lang: Lang | null, format: AnswerFormat, brief: boolean): string {
  const language = lang
    ? `Write the whole answer in ${LANGUAGE_NAMES[lang]}. Keep G-code words (G43, M03), units (mm, m/min, rpm), ` +
      `parameter names and brand or product names as they are normally written, but write everything else in ` +
      `${LANGUAGE_NAMES[lang]}. Never switch to another language or script mid-answer.` +
      (lang === "fa" ? ` ${PERSIAN_TERMS}` : "")
    : "Answer in the language the user writes in. Never switch to another language or script mid-answer.";
  const layout = format === "markdown"
    ? "Markdown for a small phone screen: short paragraphs, '-' lists or numbered steps, **bold** only for key " +
      "values, at most a '###' heading in long answers, G-code in ``` code blocks. No tables, no LaTeX, no HTML."
    : "plain text for a small phone screen: short paragraphs, lists starting with '-' or '1.', G-code in ``` " +
      "code blocks. No other Markdown (no **, no #, no tables), no LaTeX, no HTML.";
  return [
    `Language: ${language}`,
    `Layout: ${layout} Write formulas as plain text, for example RPM = (Vc × 1000) / (π × D).`,
    ...(brief ? ["Length: about 100-300 words unless the question needs more, so the answer fits on a phone."] : []),
  ].join("\n");
}

/// G-code comments must stay ASCII: most controllers reject other characters.
export function gcodeCommentRule(lang: Lang | null): string {
  return lang && lang !== "en"
    ? `Inside the G-code, write comments in English using ASCII only (controllers reject other characters); ` +
      `explain the program in ${LANGUAGE_NAMES[lang]} outside the code block.`
    : "Inside the G-code, write comments in ASCII only (controllers reject other characters).";
}

export const MAX_HISTORY_TURNS = 6;
export const MAX_HISTORY_CHARS = 6000;
const MAX_TURN_CHARS = 2000;

/// The chat history a client sent, made safe to forward: only user and
/// assistant text, the most recent turns that fit the limits, starting with
/// a user turn, alternating, and ending with an assistant turn (the new
/// question follows it).
export function historyFrom(raw: unknown): Turn[] {
  if (!Array.isArray(raw)) return [];
  const turns: Turn[] = [];
  for (const item of raw.slice(-4 * MAX_HISTORY_TURNS)) {
    if (!item || typeof item !== "object") continue;
    const { role, content } = item as Record<string, unknown>;
    if ((role !== "user" && role !== "assistant") || typeof content !== "string") continue;
    const text = content.trim().substring(0, MAX_TURN_CHARS);
    if (!text) continue;
    const last = turns[turns.length - 1];
    if (last?.role === role) last.text = `${last.text}\n\n${text}`.substring(0, MAX_TURN_CHARS);
    else turns.push({ role, text });
  }
  while (turns.length && turns[turns.length - 1].role === "user") turns.pop();

  // Newest first, until a limit is reached; then back in order.
  const kept: Turn[] = [];
  let chars = 0;
  for (let i = turns.length - 1; i >= 0 && kept.length < MAX_HISTORY_TURNS; i--) {
    chars += turns[i].text.length;
    if (chars > MAX_HISTORY_CHARS) break;
    kept.unshift(turns[i]);
  }
  while (kept.length && kept[0].role === "assistant") kept.shift();
  return kept;
}
