/// One program line reduced to what the rule checks need: its G and M codes,
/// its address words, and any multi-letter keywords (GOTO, IF, CYCLE83, …).
class Block {
  final int index;

  /// Normalised G codes in line order: G00 → G0, G01 → G1, G43.4 stays.
  final List<String> gCodes;

  /// Normalised M codes: M03 → M3. Sinumerik `M1=3` (spindle 1) → M3.
  final List<String> mCodes;

  /// Address letter → raw numeric text of its first occurrence, or null when
  /// the value is a variable or an expression (X#101, X=R1, X[#1+2]).
  final Map<String, String?> words;

  /// Multi-letter words: control flow, cycles, Sinumerik commands.
  final List<String> keywords;

  /// Keywords written as a call with an argument list: CYCLE83(…).
  final Set<String> keywordsWithArgs;

  /// All matched tokens, for display and debugging.
  final List<String> tokens;

  /// The line held a quoted string (Haas `M98 "O1000.nc"`, Sinumerik MSG).
  final bool hadQuotedText;

  const Block({
    required this.index,
    required this.gCodes,
    required this.mCodes,
    required this.words,
    required this.keywords,
    this.keywordsWithArgs = const {},
    required this.tokens,
    required this.hadQuotedText,
  });

  bool get isEmpty =>
      gCodes.isEmpty && mCodes.isEmpty && words.isEmpty && keywords.isEmpty;

  bool has(String letter) => words.containsKey(letter);
  bool hasG(String code) => gCodes.contains(code);
  bool hasM(String code) => mCodes.contains(code);
  bool hasAnyG(Iterable<String> codes) => codes.any(gCodes.contains);
  bool hasKeyword(String k) => keywords.contains(k);

  /// Numeric value of [letter], when it is a plain number.
  double? number(String letter) {
    final raw = words[letter];
    return raw == null ? null : double.tryParse(raw);
  }

  /// Any linear or rotary axis word.
  bool get hasAxisWord =>
      const ['X', 'Y', 'Z', 'U', 'V', 'W', 'A', 'B', 'C'].any(words.containsKey);
}

/// Reads lines into [Block]s. Comment syntax is the only dialect difference:
/// Fanuc/Haas comments are (parentheses), Sinumerik comments start with ';'
/// and parentheses there belong to the code: CYCLE83(…), X=IC(5).
class BlockReader {
  final bool semicolonComments;
  const BlockReader({required this.semicolonComments});

  static final _quoted = RegExp(r'"[^"]*"');
  static final _parenComment = RegExp(r'\([^)]*\)');
  static final _word = RegExp(
    // 1-3: indexed assignment (Sinumerik): M1=3, S1=1000, R10=5
    r'([A-Z])(\d+)\s*=\s*([^\s]+)'
    // 4: keyword: GOTO, IF, WHILE, DO1, END1, CYCLE83, TRANS, CR, DEF …
    r'|([A-Z]{2,}[A-Z0-9_]*)'
    // 5-6: address assignment (Sinumerik): X=IC(5), F=R1, T="DRILL"
    r'|([A-Z])\s*=\s*([^\s]*)'
    // 7-8: plain address word: X-1.5, G01, M03, X.5, X1.
    r'|([A-Z])\s*([+-]?(?:\d+\.?\d*|\.\d+))'
    // 9: address with a macro value: X#101, X[#1+2]
    r'|([A-Z])\s*(?=[#\[])',
  );

  /// Code text of [line] with comments and quoted strings removed.
  String codeOf(String line) {
    var s = line.toUpperCase().replaceAll(_quoted, ' ');
    if (semicolonComments) {
      final semi = s.indexOf(';');
      if (semi >= 0) s = s.substring(0, semi);
    } else {
      s = s.replaceAll(_parenComment, ' ');
      final open = s.indexOf('('); // unclosed comment runs to the end
      if (open >= 0) s = s.substring(0, open);
      final semi = s.indexOf(';'); // end-of-block marker some editors add
      if (semi >= 0) s = s.substring(0, semi);
    }
    return s;
  }

  Block read(int index, String line) {
    final code = codeOf(line);
    final gCodes = <String>[];
    final mCodes = <String>[];
    final words = <String, String?>{};
    final keywords = <String>[];
    final withArgs = <String>{};
    final tokens = <String>[];

    for (final m in _word.allMatches(code)) {
      tokens.add(m.group(0)!.trim());
      if (m.group(1) != null) {
        final letter = m.group(1)!;
        final value = m.group(3)!;
        if (letter == 'M') {
          // M1=3: spindle 1 clockwise. Keep the function, drop the spindle number.
          final fn = _normaliseCode('M', value);
          if (fn != null) mCodes.add(fn);
        } else if (letter != 'R') {
          // R10=5 assigns an R parameter; it is not an R word.
          words.putIfAbsent(letter, () => null);
        }
      } else if (m.group(4) != null) {
        final k = m.group(4)!;
        keywords.add(k);
        if (code.substring(m.end).trimLeft().startsWith('(')) withArgs.add(k);
      } else if (m.group(5) != null) {
        final letter = m.group(5)!;
        final value = m.group(6)!;
        words.putIfAbsent(letter, () => double.tryParse(value) != null ? value : null);
      } else if (m.group(7) != null) {
        final letter = m.group(7)!;
        final value = m.group(8)!;
        if (letter == 'G') {
          final g = _normaliseCode('G', value);
          if (g != null) gCodes.add(g);
        } else if (letter == 'M') {
          final mc = _normaliseCode('M', value);
          if (mc != null) mCodes.add(mc);
        } else {
          words.putIfAbsent(letter, () => value);
        }
      } else if (m.group(9) != null) {
        final letter = m.group(9)!;
        if (letter == 'G' || letter == 'M') continue; // G#1: computed code
        words.putIfAbsent(letter, () => null);
      }
    }

    return Block(
      index: index,
      gCodes: gCodes,
      mCodes: mCodes,
      words: words,
      keywords: keywords,
      keywordsWithArgs: withArgs,
      tokens: tokens,
      hadQuotedText: line.contains('"'),
    );
  }

  /// G01 → G1, G00 → G0, G43.4 → G43.4, G154 → G154. Null for non-numbers.
  static String? _normaliseCode(String letter, String value) {
    final v = value.startsWith('+') ? value.substring(1) : value;
    if (v.startsWith('-')) return null;
    final parts = v.split('.');
    final whole = int.tryParse(parts[0].isEmpty ? '0' : parts[0]);
    if (whole == null) return null;
    final frac = parts.length > 1 ? parts[1] : '';
    if (frac.isEmpty || int.tryParse(frac) == 0) return '$letter$whole';
    return '$letter$whole.$frac';
  }
}
