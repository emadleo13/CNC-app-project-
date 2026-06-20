import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Shared G-code syntax highlighting.
///
/// Single source of truth for tokenizing a G-code string into colored spans.
/// Used both by the live editor ([GcodeHighlightController]) and the read-only
/// result view, so colors never drift between the two.

// Pre-compiled once at load time. Building these per-token (the previous
// behaviour) recompiled eight RegExps for every word in the file on every
// rebuild — tens of thousands of allocations for a real G-code program, which
// blocked the UI thread and triggered an ANR on upload.
final RegExp _reN     = RegExp(r'^N\d+$');
final RegExp _reG     = RegExp(r'^G[\d.]+$');
final RegExp _reM     = RegExp(r'^M[\d.]+$');
final RegExp _reCycle = RegExp(r'^CYCLE\d+$');
final RegExp _reKw    = RegExp(r'^(TRANS|ATRANS|ROT|AROT|DEF|REAL|INT|PROC|ENDPROC|CALL)$');
final RegExp _reAddr1 = RegExp(r'^[XYZABCIJKF][+-]?[\d.]*$');
final RegExp _reAddr2 = RegExp(r'^[STHDRQP][+-]?[\d.]*$');
final RegExp _reNum   = RegExp(r'^[+-]?[\d.]+$');

/// Above this many characters the live editor skips syntax highlighting and
/// renders plain text, so opening a large program stays responsive.
const int kGcodeHighlightLimit = 20000;

/// Returns the syntax color for a single whitespace-free token (word).
Color gcodeTokenColor(String token) {
  final t = token.toUpperCase();
  if (t.isEmpty) return AppColors.gcodeValue;
  if (_reN.hasMatch(t)) return AppColors.gcodeN;
  if (_reG.hasMatch(t)) return AppColors.gcodeG;
  if (_reM.hasMatch(t)) return AppColors.gcodeM;
  if (_reCycle.hasMatch(t)) return AppColors.gcodeCycle;
  if (_reKw.hasMatch(t)) return AppColors.gcodeCycle;
  if (_reAddr1.hasMatch(t)) return AppColors.gcodeAddr;
  if (_reAddr2.hasMatch(t)) return AppColors.gcodeAddr;
  if (_reNum.hasMatch(t)) return AppColors.gcodeValue;
  return AppColors.gcodeValue;
}

/// Tokenizes [text] into colored [TextSpan]s, preserving every character
/// (whitespace and newlines included) so the result can back a [TextField]
/// without disturbing the cursor.
List<TextSpan> buildGcodeSpans(String text, TextStyle base) {
  final spans = <TextSpan>[];
  final commentStyle = base.copyWith(color: AppColors.gcodeComment);
  final valueStyle   = base.copyWith(color: AppColors.gcodeValue);

  final n = text.length;
  var i = 0;
  while (i < n) {
    final c = text[i];

    // Parenthesized comment: ( ... )
    if (c == '(') {
      final end = text.indexOf(')', i);
      final stop = end == -1 ? n : end + 1;
      spans.add(TextSpan(text: text.substring(i, stop), style: commentStyle));
      i = stop;
      continue;
    }

    // Semicolon comment: to end of line
    if (c == ';') {
      var end = text.indexOf('\n', i);
      if (end == -1) end = n;
      spans.add(TextSpan(text: text.substring(i, end), style: commentStyle));
      i = end;
      continue;
    }

    // Whitespace run (kept neutral)
    if (_isWhitespace(c)) {
      var j = i + 1;
      while (j < n && _isWhitespace(text[j])) {
        j++;
      }
      spans.add(TextSpan(text: text.substring(i, j), style: valueStyle));
      i = j;
      continue;
    }

    // Word token: a letter followed by optional sign / digits / dot
    if (_isLetter(c)) {
      var j = i + 1;
      if (j < n && (text[j] == '+' || text[j] == '-')) j++;
      while (j < n && (_isDigit(text[j]) || text[j] == '.')) {
        j++;
      }
      final tok = text.substring(i, j);
      spans.add(TextSpan(text: tok, style: base.copyWith(color: gcodeTokenColor(tok))));
      i = j;
      continue;
    }

    // Standalone number (e.g. after a bare letter elsewhere)
    if (_isDigit(c) || c == '+' || c == '-' || c == '.') {
      var j = i + 1;
      while (j < n && (_isDigit(text[j]) || text[j] == '.')) {
        j++;
      }
      spans.add(TextSpan(text: text.substring(i, j), style: valueStyle));
      i = j;
      continue;
    }

    // Any other single character (%, *, =, etc.)
    spans.add(TextSpan(text: c, style: valueStyle));
    i++;
  }

  return spans;
}

bool _isWhitespace(String c) => c == ' ' || c == '\t' || c == '\n' || c == '\r';
bool _isLetter(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 65 && u <= 90) || (u >= 97 && u <= 122);
}
bool _isDigit(String c) {
  final u = c.codeUnitAt(0);
  return u >= 48 && u <= 57;
}

/// A [TextEditingController] that renders its content with live G-code
/// syntax highlighting.
class GcodeHighlightController extends TextEditingController {
  GcodeHighlightController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    // Skip tokenizing very large programs to keep typing/scrolling responsive.
    if (text.length > kGcodeHighlightLimit) {
      return TextSpan(style: base, text: text);
    }
    return TextSpan(style: base, children: buildGcodeSpans(text, base));
  }
}
