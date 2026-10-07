enum LineSeverity { ok, warning, error }

/// One finding of the rule checker on one line. [rule] identifies the check
/// and [args] fill its message, so the text can be shown in the user's
/// language (see GcodeRuleText).
class LineIssue {
  final LineSeverity severity;
  final String rule;
  final Map<String, String> args;

  const LineIssue(this.severity, this.rule, [this.args = const {}]);

  @override
  String toString() => 'LineIssue($rule, $severity, $args)';
}

class GcodeLine {
  final int lineNumber;
  final String original;

  /// Findings of the local rule checker.
  final List<LineIssue> issues;

  final List<String> tokens;

  const GcodeLine({
    required this.lineNumber,
    required this.original,
    this.issues = const [],
    this.tokens = const [],
  });

  /// The worst severity among this line's issues.
  LineSeverity get severity {
    var worst = LineSeverity.ok;
    for (final i in issues) {
      if (i.severity.index > worst.index) worst = i.severity;
    }
    return worst;
  }

  bool get hasIssue  => issues.isNotEmpty;
  bool get isEmpty   => original.trim().isEmpty;
  bool get isComment => original.trim().startsWith(';') || original.trim().startsWith('(');
}
