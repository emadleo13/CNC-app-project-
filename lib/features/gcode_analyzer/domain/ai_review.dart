import 'gcode_line.dart';

/// One problem the AI reviewer found. [line] is 1-based, or null when the
/// finding is about the program as a whole.
class AiFinding {
  final int? line;
  final LineSeverity severity;
  final String issue;
  final String suggestion;

  const AiFinding({
    required this.line,
    required this.severity,
    required this.issue,
    required this.suggestion,
  });
}

/// The analyze-gcode Edge Function's answer: a second opinion next to the
/// app's own rule checks.
class AiReview {
  final String summary;
  final String operationType;
  final List<AiFinding> findings;
  final List<String> suggestions;

  const AiReview({
    required this.summary,
    required this.operationType,
    required this.findings,
    required this.suggestions,
  });

  /// Tolerant of missing or mistyped fields; the server already normalises.
  factory AiReview.fromJson(Map<String, dynamic> json) {
    final findings = <AiFinding>[];
    for (final f in (json['findings'] as List? ?? const [])) {
      if (f is! Map) continue;
      final issue = f['issue'];
      if (issue is! String || issue.trim().isEmpty) continue;
      final line = f['line'];
      findings.add(AiFinding(
        line:       line is num ? line.toInt() : null,
        severity:   f['severity'] == 'error' ? LineSeverity.error : LineSeverity.warning,
        issue:      issue.trim(),
        suggestion: (f['suggestion'] as String? ?? '').trim(),
      ));
    }
    return AiReview(
      summary:       (json['summary'] as String? ?? '').trim(),
      operationType: json['operation_type'] as String? ?? 'unknown',
      findings:      findings,
      suggestions:   [
        for (final s in (json['suggestions'] as List? ?? const []))
          if (s is String && s.trim().isNotEmpty) s.trim(),
      ],
    );
  }
}
