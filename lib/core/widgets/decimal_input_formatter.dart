import 'package:flutter/services.dart';

/// Keeps a numeric field parseable by [double.tryParse] whatever keyboard the
/// operator uses.
///
/// Persian (۰–۹) and Arabic-Indic (٠–٩) digits become ASCII digits, and the
/// decimal comma (`,`), the Arabic decimal separator (`٫`) and the Arabic comma
/// (`،`) become `.`. A plain character filter would silently drop the comma
/// instead — "0,15" turned into "015", a feed 100× too high — so a second
/// separator rejects the whole edit rather than being dropped.
class DecimalInputFormatter extends TextInputFormatter {
  final bool allowNegative;
  const DecimalInputFormatter({this.allowNegative = false});

  /// Normalises [input] the same way the formatter does, for text that never
  /// went through a field (pasted values, stored strings). Returns null when
  /// it holds more than one decimal separator.
  static String? normalize(String input, {bool allowNegative = false}) {
    final r = _apply(input, input.length, allowNegative);
    return r.rejected ? null : r.text;
  }

  /// [double.tryParse] after [normalize].
  static double? parse(String input, {bool allowNegative = false}) {
    final n = normalize(input, allowNegative: allowNegative);
    return n == null ? null : double.tryParse(n);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final end = newValue.selection.end;
    final r = _apply(
      newValue.text,
      end < 0 ? newValue.text.length : end,
      allowNegative,
    );
    if (r.rejected) return oldValue;
    return TextEditingValue(
      text: r.text,
      selection: TextSelection.collapsed(offset: r.cursor),
    );
  }

  static ({String text, int cursor, bool rejected}) _apply(
    String text,
    int cursorIn,
    bool allowNegative,
  ) {
    final out = StringBuffer();
    var cursor = 0;
    var seenSeparator = false;
    for (var i = 0; i < text.length; i++) {
      final c = _canonical(text.codeUnitAt(i));
      String? keep;
      if (c >= 0x30 && c <= 0x39) {
        keep = String.fromCharCode(c);
      } else if (c == 0x2E) {
        if (seenSeparator) return (text: '', cursor: 0, rejected: true);
        seenSeparator = true;
        keep = '.';
      } else if (c == 0x2D && allowNegative && out.isEmpty) {
        keep = '-';
      }
      if (keep != null) {
        out.write(keep);
        if (i < cursorIn) cursor++;
      }
    }
    return (text: out.toString(), cursor: cursor, rejected: false);
  }

  /// Maps a code unit onto ASCII digit, '.', or '-' where it means one of
  /// those; anything else is returned unchanged (and later dropped).
  static int _canonical(int c) {
    if (c >= 0x06F0 && c <= 0x06F9) return 0x30 + (c - 0x06F0); // Persian
    if (c >= 0x0660 && c <= 0x0669) return 0x30 + (c - 0x0660); // Arabic-Indic
    if (c == 0x2C || c == 0x066B || c == 0x060C) return 0x2E; // , ٫ ،
    if (c == 0x2212) return 0x2D; // − minus sign
    return c;
  }
}
