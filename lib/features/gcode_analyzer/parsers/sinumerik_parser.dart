import '../domain/gcode_line.dart';
import 'base_parser.dart';

class SinumerikParser extends BaseParser {
  static const _knownG = [
    'G0','G00','G1','G01','G2','G02','G3','G03','G4','G04',
    'G17','G18','G19','G25','G26',
    'G40','G41','G42','G43','G44',
    'G53','G54','G55','G56','G57','G500','G505',
    'G60','G61','G62','G63','G64',
    'G70','G71','G90','G91','G94','G95','G96','G97',
  ];

  static const _knownM = [
    'M0','M00','M1','M01','M2','M02','M3','M03','M4','M04','M5','M05',
    'M6','M06','M7','M07','M8','M08','M9','M09',
    'M17','M30','M40','M41','M42',
  ];

  static const _sinumerikKeywords = [
    'CYCLE81','CYCLE82','CYCLE83','CYCLE84','CYCLE85','CYCLE840',
    'CYCLE86','CYCLE88','CYCLE90',
    'TRANS','ATRANS','ROT','AROT','SCALE','ASCALE','MIRROR','AMIRROR',
    'DEF','REAL','INT','BOOL','STRING',
    'GOTOB','GOTOF','LABEL',
    'REPEAT','ENDLOOP','LOOP','FOR','TO','ENDFOR','IF','ELSE','ENDIF',
    'PROC','ENDPROC','CALL',
    'SPCON','SPCOF','SPOSA',
    'WAITM','WAITE','SETMS',
  ];

  @override
  List<String> knownGCodes() => _knownG;

  @override
  List<String> knownMCodes() => _knownM;

  bool isSinumerikKeyword(String token) {
    final upper = token.toUpperCase().split('(').first;
    return _sinumerikKeywords.contains(upper);
  }

  @override
  LineSeverity validateLine(String line, List<String> tokens) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith(';') || trimmed == '%') return LineSeverity.ok;

    // DEF without type keyword is suspicious
    if (trimmed.toUpperCase().startsWith('DEF') &&
        !RegExp(r'DEF\s+(REAL|INT|BOOL|STRING)', caseSensitive: false).hasMatch(trimmed)) {
      return LineSeverity.warning;
    }

    // CYCLE calls should have parentheses
    if (RegExp(r'\bCYCLE\d+\b', caseSensitive: false).hasMatch(trimmed) &&
        !trimmed.contains('(')) {
      return LineSeverity.warning;
    }

    return LineSeverity.ok;
  }

  static bool looksLikeSinumerik(String gcode) {
    return RegExp(r'\bCYCLE\d+\b', caseSensitive: false).hasMatch(gcode) ||
           RegExp(r'\bTRANS\b',    caseSensitive: false).hasMatch(gcode) ||
           RegExp(r'\bDEF\s+(REAL|INT|BOOL)', caseSensitive: false).hasMatch(gcode) ||
           gcode.contains(r'$') ||
           RegExp(r'\bPROC\b',     caseSensitive: false).hasMatch(gcode);
  }
}
