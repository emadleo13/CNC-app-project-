// Answer language: which one to write in, and whether a reply kept to it.

export type Lang = "en" | "fa" | "ro" | "ar";

export const LANGUAGE_NAMES: Record<Lang, string> = {
  en: "English",
  fa: "Persian (Farsi)",
  ro: "Romanian",
  ar: "Arabic",
};

export function isLang(v: unknown): v is Lang {
  return v === "en" || v === "fa" || v === "ro" || v === "ar";
}

const ARABIC_SCRIPT = /[؀-ۿ]/;
// Letters Persian uses and Arabic does not: پ چ ژ گ ک ی
const PERSIAN_LETTERS = /[پچژگکی]/;
const ROMANIAN_LETTERS = /[ăâîșşțţ]/i;

/// The language an answer to [text] should be in. The question's own script
/// wins over the app language (someone with a Persian app may ask in
/// English); the app language decides what the script cannot: English vs
/// Romanian without diacritics, or a bare alarm number. Null: unknown, let
/// the model follow the question.
export function answerLanguage(text: string, appLanguage?: unknown): Lang | null {
  const app = isLang(appLanguage) ? appLanguage : null;
  if (ARABIC_SCRIPT.test(text)) {
    if (PERSIAN_LETTERS.test(text)) return "fa";
    return app === "fa" ? "fa" : "ar";
  }
  if (ROMANIAN_LETTERS.test(text)) return "ro";
  if (/[a-z]/i.test(text)) return app === "ro" ? "ro" : app ? "en" : null;
  return app;
}

// Scripts none of the four app languages use: Cyrillic, Hebrew, Indic, Thai,
// Hangul, Kana, CJK. Greek is left out on purpose: π, μ and Δ appear in
// formulas.
const FOREIGN_SCRIPTS =
  /[Ѐ-ԯ֐-׿ऀ-෿฀-๿ᄀ-ᇿ぀-ヿ㐀-䶿一-鿿가-힯豈-﫿]/g;
// Accented Latin letters (velocità, Qualität, lực). Ø (diameter), ×, ÷ and
// µ are not in these ranges.
const ACCENTED_LATIN = /[À-ÖÙ-öù-ɏḀ-ỿ]/g;

/// Above this many stray characters a reply counts as garbled. A few are
/// allowed: brand names such as Gühring or Böhler are legitimate.
export const GARBLED_SCORE = 4;

/// How many characters of [text] belong to no script an answer in [lang]
/// would use. Weak free models drift into other languages mid-sentence
/// ("دور devotion", "بار 칩", "серمکولنت"); this is what catches it. Code is
/// not scored.
export function foreignScore(text: string, lang: Lang | null): number {
  const prose = text.replace(/```[\s\S]*?(?:```|$)/g, " ").replace(/`[^`\n]*`/g, " ");
  let n = prose.match(FOREIGN_SCRIPTS)?.length ?? 0;
  if (lang === "fa" || lang === "ar") {
    n += prose.match(ACCENTED_LATIN)?.length ?? 0;
  } else if (lang !== null) {
    n += prose.match(/[؀-ۿ]/g)?.length ?? 0;
  }
  return n;
}

/// Removes reasoning that some free models write into the answer itself.
export function stripThinking(text: string): string {
  let t = text.replace(/<think(?:ing)?>[\s\S]*?<\/think(?:ing)?>/gi, "");
  // Reasoning with only the closing tag: everything before it is reasoning.
  const close = t.search(/<\/think(?:ing)?>/i);
  if (close >= 0) t = t.slice(t.indexOf(">", close) + 1);
  return t.trim();
}
