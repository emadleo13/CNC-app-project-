// Parsing and clean-up of the AI G-code review (analyze-gcode). Kept apart
// from the function so it can be tested without starting a server.

export const MAX_FINDINGS = 30;

/// The JSON object in a model reply, with or without a ```json fence.
export function parseReply(text: string): Record<string, unknown> | null {
  const fenced = text.match(/```(?:json)?\s*([\s\S]+?)\s*```/);
  const candidate = fenced ? fenced[1] : text.slice(text.indexOf("{"), text.lastIndexOf("}") + 1);
  try {
    const v = JSON.parse(candidate);
    return v && typeof v === "object" && !Array.isArray(v) ? v as Record<string, unknown> : null;
  } catch {
    return null;
  }
}

/// Coerces a model reply into the documented shape: known severities, line
/// numbers inside the program, bounded lengths.
export function normalise(raw: Record<string, unknown>, lineCount: number) {
  const str = (v: unknown, max: number) => (typeof v === "string" ? v.trim().substring(0, max) : "");
  const findings = (Array.isArray(raw.findings) ? raw.findings : [])
    .filter((f): f is Record<string, unknown> => !!f && typeof f === "object")
    .map((f) => {
      const n = Math.round(Number(f.line));
      return {
        line:       Number.isFinite(n) && n >= 1 && n <= lineCount ? n : null,
        severity:   f.severity === "error" ? "error" : "warning",
        issue:      str(f.issue, 500),
        suggestion: str(f.suggestion, 500),
      };
    })
    .filter((f) => f.issue.length > 0)
    .slice(0, MAX_FINDINGS);
  const suggestions = (Array.isArray(raw.suggestions) ? raw.suggestions : [])
    .map((s) => str(s, 400))
    .filter((s) => s.length > 0)
    .slice(0, 5);
  return {
    summary:        str(raw.summary, 1500),
    operation_type: str(raw.operation_type, 20) || "unknown",
    findings,
    suggestions,
  };
}
