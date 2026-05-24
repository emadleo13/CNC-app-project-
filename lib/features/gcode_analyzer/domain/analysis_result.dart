import 'gcode_line.dart';
import 'cnc_dialect.dart';

class AnalysisResult {
  final String summary;
  final String operationType;
  final int? estimatedRuntimeMinutes;
  final List<GcodeLine> lines;
  final List<String> overallIssues;
  final List<String> suggestions;
  final CncDialect dialect;
  final DateTime analyzedAt;
  final bool isLocalOnly;

  const AnalysisResult({
    required this.summary,
    required this.operationType,
    this.estimatedRuntimeMinutes,
    required this.lines,
    required this.overallIssues,
    required this.suggestions,
    required this.dialect,
    required this.analyzedAt,
    this.isLocalOnly = false,
  });

  int get errorCount   => lines.where((l) => l.severity == LineSeverity.error).length;
  int get warningCount => lines.where((l) => l.severity == LineSeverity.warning).length;
  int get lineCount    => lines.length;

  factory AnalysisResult.fromJson(Map<String, dynamic> json, CncDialect dialect) {
    final linesJson = json['lines'] as List? ?? [];
    return AnalysisResult(
      summary:                  json['summary'] as String? ?? '',
      operationType:            json['operation_type'] as String? ?? 'unknown',
      estimatedRuntimeMinutes:  json['estimated_runtime_minutes'] as int?,
      lines: linesJson.asMap().entries.map((e) {
        final l = e.value as Map<String, dynamic>;
        return GcodeLine(
          lineNumber:  l['line_number'] as int? ?? e.key + 1,
          original:    l['original']    as String? ?? '',
          explanation: l['explanation'] as String?,
          severity:    _parseSeverity(l['severity'] as String?),
          issue:       l['issue']       as String?,
          suggestion:  l['suggestion']  as String?,
        );
      }).toList(),
      overallIssues: List<String>.from(json['overall_issues'] as List? ?? []),
      suggestions:   List<String>.from(json['suggestions']    as List? ?? []),
      dialect:       dialect,
      analyzedAt:    DateTime.now(),
      isLocalOnly:   false,
    );
  }

  static LineSeverity _parseSeverity(String? s) {
    switch (s) {
      case 'error':   return LineSeverity.error;
      case 'warning': return LineSeverity.warning;
      default:        return LineSeverity.ok;
    }
  }
}
