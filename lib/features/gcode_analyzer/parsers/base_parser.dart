import '../domain/gcode_line.dart';

// Pre-compiled once. parse() runs these for every line of the program; building
// them per-line recompiled hundreds of thousands of RegExps for a large file.
final RegExp _reNewline = RegExp(r'\r?\n');
final RegExp _reToken   = RegExp(r'[A-Za-z][+-]?[\d.]+|[A-Za-z]+');
final RegExp _reLeadZero = RegExp(r'^0+');
final RegExp _reDigit    = RegExp(r'\d');

abstract class BaseParser {
  List<GcodeLine> parse(String gcode) {
    final rawLines = gcode.split(_reNewline);
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
    return _reToken
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
        final gnum = tok.substring(1).replaceAll(_reLeadZero, '');
        final normalized = 'G${gnum.isEmpty ? "0" : gnum}';
        if (!knownGCodes().contains(normalized) && !knownGCodes().contains(tok)) {
          return 'Unknown G-code: $tok';
        }
      }
      if (tok.startsWith('M') && tok.length > 1 && tok[1].contains(_reDigit)) {
        if (!knownMCodes().contains(tok)) {
          return 'Unknown M-code: $tok (may be machine-specific)';
        }
      }
    }
    return null;
  }
}
