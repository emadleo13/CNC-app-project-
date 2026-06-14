import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Shared G-code syntax highlighting.
///
/// Single source of truth for tokenizing a G-code string into colored spans.
/// Used both by the live editor ([GcodeHighlightController]) and the read-only
/// result view, so colors never drift between the two.

/// Returns the syntax color for a single whitespace-free token (word).
Color gcodeTokenColor(String token) {
  final t = token.toUpperCase();
  if (t.isEmpty) return AppColors.gcodeValue;
  if (RegExp(r'^N\d+$').hasMatch(t)) return AppColors.gcodeN;
  if (RegExp(r'^G[\d.]+$').hasMatch(t)) return AppColors.gcodeG;
  if (RegExp(r'^M[\d.]+$').hasMatch(t)) return AppColors.gcodeM;
  if (RegExp(r'^CYCLE\d+$').hasMatch(t)) return AppColors.gcodeCycle;
  if (RegExp(r'^(TRANS|ATRANS|ROT|AROT|DEF|REAL|INT|PROC|ENDPROC|CALL)$').hasMatch(t)) {
    return AppColors.gcodeCycle;
  }
  if (RegExp(r'^[XYZABCIJKF][+-]?[\d.]*$').hasMatch(t)) return AppColors.gcodeAddr;
  if (RegExp(r'^[STHDRQP][+-]?[\d.]*$').hasMatch(t)) return AppColors.gcodeAddr;
  if (RegExp(r'^[+-]?[\d.]+$').hasMatch(t)) return AppColors.gcodeValue;
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
    return TextSpan(style: base, children: buildGcodeSpans(text, base));
  }
}
