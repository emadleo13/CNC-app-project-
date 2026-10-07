import '../domain/gcode_line.dart';
import 'base_parser.dart';
import 'block.dart';
import 'haas_parser.dart';

Set<String> _range(int from, int to) => {for (var i = from; i <= to; i++) 'G$i'};

/// Siemens Sinumerik 840D/828D. Comments start with ';'. Parentheses belong to
/// the code (CYCLE83(…), X=IC(5)). The D number applies tool length
/// automatically, so there is no G43 rule.
class SinumerikParser extends BaseParser {
  static final Set<String> _knownG = {
    ..._range(0, 5), 'G7', 'G9', ..._range(15, 21), 'G25', 'G26', 'G28',
    'G33', 'G331', 'G332', 'G34', 'G35', ..._range(40, 42), 'G46', 'G51',
    ..._range(53, 64), 'G601', 'G602', 'G603', 'G621',
    'G641', 'G642', 'G643', 'G644', 'G645', 'G68', 'G70', 'G71', 'G700', 'G710',
    'G74', 'G75', ..._range(80, 99), 'G961', 'G962', 'G971', 'G972', 'G973',
    'G110', 'G111', 'G112', 'G140', 'G141', 'G142', 'G143', 'G147', 'G148',
    'G153', 'G247', 'G248', 'G290', 'G291', 'G340', 'G341', 'G347', 'G348',
    'G450', 'G451', 'G460', 'G461', 'G462', 'G500', ..._range(505, 599),
  };

  static const _types = {'REAL', 'INT', 'BOOL', 'STRING', 'CHAR', 'AXIS', 'FRAME'};
  static final _cycleName = RegExp(r'^CYCLE\d+$');

  static const _keywords = [
    'CYCLE81', 'CYCLE82', 'CYCLE83', 'CYCLE84', 'CYCLE85', 'CYCLE840',
    'CYCLE86', 'CYCLE88', 'CYCLE90', 'TRANS', 'ATRANS', 'ROT', 'AROT',
    'SCALE', 'ASCALE', 'MIRROR', 'AMIRROR', 'DEF', 'REAL', 'INT', 'BOOL',
    'STRING', 'GOTOB', 'GOTOF', 'LABEL', 'REPEAT', 'ENDLOOP', 'LOOP', 'FOR',
    'TO', 'ENDFOR', 'IF', 'ELSE', 'ENDIF', 'PROC', 'ENDPROC', 'CALL',
    'SPCON', 'SPCOF', 'SPOSA', 'WAITM', 'WAITE', 'SETMS',
  ];

  @override
  final BlockReader reader = const BlockReader(semicolonComments: true);

  @override
  String get dialectName => 'Sinumerik';

  @override
  Set<String>? get knownGCodes => _knownG;

  @override
  Set<String> get programEnds => const {'M30', 'M2', 'M17'};

  @override
  String get programEndText => 'M30 / M2 (M17 or RET in a subprogram)';

  @override
  Set<String> get unitCodes => const {'G70', 'G71', 'G700', 'G710', 'G20', 'G21'};

  /// Sinumerik units come from machine data; programs rarely set them.
  @override
  bool get warnMissingUnits => false;

  /// Settable frames are optional on Sinumerik, so no work-offset rule.
  @override
  Set<String> get workOffsetCodes => const {};

  bool isSinumerikKeyword(String token) =>
      _keywords.contains(token.toUpperCase().split('(').first);

  @override
  void checkBlock(Block b, List<LineIssue> out, ProgramShape shape) {
    checkCommon(b, out);
    checkCutterCompStart(b, out);

    // DEF needs a data type: DEF REAL R_DEPTH.
    final def = b.keywords.indexOf('DEF');
    if (def >= 0 && (def + 1 >= b.keywords.length || !_types.contains(b.keywords[def + 1]))) {
      out.add(const LineIssue(LineSeverity.warning, 'sin_def_type'));
    }

    // Cycles take their parameters in parentheses.
    for (final k in b.keywords) {
      if (_cycleName.hasMatch(k) && !b.keywordsWithArgs.contains(k)) {
        out.add(LineIssue(LineSeverity.warning, 'sin_cycle_parens', {'cycle': k}));
      }
    }
  }

  static bool looksLikeSinumerik(String gcode) {
    return RegExp(r'\bCYCLE\d+\b', caseSensitive: false).hasMatch(gcode) ||
           RegExp(r'\bTRANS\b',    caseSensitive: false).hasMatch(gcode) ||
           RegExp(r'\bDEF\s+(REAL|INT|BOOL)', caseSensitive: false).hasMatch(gcode) ||
           gcode.contains(r'$') ||
           RegExp(r'\bPROC\b',     caseSensitive: false).hasMatch(gcode);
  }
}
