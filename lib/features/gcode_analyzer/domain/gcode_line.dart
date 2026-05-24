enum LineSeverity { ok, warning, error }

class GcodeLine {
  final int lineNumber;
  final String original;
  final String? explanation;
  final LineSeverity severity;
  final String? issue;
  final String? suggestion;
  final List<String> tokens;

  const GcodeLine({
    required this.lineNumber,
    required this.original,
    this.explanation,
    this.severity = LineSeverity.ok,
    this.issue,
    this.suggestion,
    this.tokens = const [],
  });

  bool get hasIssue => severity != LineSeverity.ok;
  bool get isEmpty   => original.trim().isEmpty;
  bool get isComment => original.trim().startsWith(';') || original.trim().startsWith('(');
}
