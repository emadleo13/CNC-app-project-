import '../domain/gcode_line.dart';

abstract class BaseParser {
  List<GcodeLine> parse(String gcode) {
    final rawLines = gcode.split(RegExp(r'\r?\n'));
    final result = <GcodeLine>[];
    for (var i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      final tokens = tokenize(line);
      final severity = validateLine(line, tokens);
      result.add(GcodeLine(
        lineNumber: i + 1,
        original:   line,
        severity:   severity,
        issue:      _issueForLine(line, tokens),
        tokens:     tokens,
      ));
    }
    return result;
  }

  List<String> tokenize(String line) {
    final clean = _stripComment(line).trim();
    if (clean.isEmpty) return [];
    // Split on word boundaries: letter followed by optional sign and digits
    return RegExp(r'[A-Za-z][+-]?[\d.]+|[A-Za-z]+')
        .allMatches(clean)
        .map((m) => m.group(0)!.toUpperCase())
        .toList();
  }

  LineSeverity validateLine(String line, List<String> tokens);

  List<String> knownGCodes();
  List<String> knownMCodes();

  String _stripComment(String line) {
    var s = line;
    final paren = s.indexOf('(');
    if (paren >= 0) s = s.substring(0, paren);
    final semi = s.indexOf(';');
    if (semi >= 0) s = s.substring(0, semi);
    return s;
  }

  bool _isComment(String line) {
    final t = line.trim();
    return t.startsWith('(') || t.startsWith(';') || t.startsWith('%');
  }

  String? _issueForLine(String line, List<String> tokens) {
    if (_isComment(line) || line.trim().isEmpty) return null;
    for (final tok in tokens) {
      if (tok.startsWith('G')) {
        final gnum = tok.substring(1).replaceAll(RegExp(r'^0+'), '');
        final normalized = 'G${gnum.isEmpty ? "0" : gnum}';
        if (!knownGCodes().contains(normalized) && !knownGCodes().contains(tok)) {
          return 'Unknown G-code: $tok';
        }
      }
      if (tok.startsWith('M') && tok.length > 1 && tok[1].contains(RegExp(r'\d'))) {
        if (!knownMCodes().contains(tok)) {
          return 'Unknown M-code: $tok (may be machine-specific)';
        }
      }
    }
    return null;
  }
}
