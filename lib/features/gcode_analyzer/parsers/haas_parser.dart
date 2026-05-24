import '../domain/cnc_dialect.dart';
import '../domain/gcode_line.dart';
import 'base_parser.dart';

class HaasParser extends BaseParser {
  static const _knownG = [
    'G0','G00','G1','G01','G2','G02','G3','G03','G4','G04',
    'G9','G09','G10','G12','G13','G17','G18','G19',
    'G20','G21','G28','G29','G30','G31',
    'G40','G41','G42','G43','G44','G49',
    'G50','G51','G52','G53','G54','G55','G56','G57','G58','G59',
    'G61','G64','G65','G68','G69',
    'G73','G74','G76','G80','G81','G82','G83','G84','G85','G86','G87','G88','G89',
    'G90','G91','G92','G93','G94','G95','G96','G97','G98','G99',
  ];

  static const _knownM = [
    'M0','M00','M1','M01','M2','M02','M3','M03','M4','M04','M5','M05',
    'M6','M06','M7','M07','M8','M08','M9','M09',
    'M19','M21','M22','M23','M24','M25','M26','M27','M28','M29','M30',
    'M31','M36','M39','M41','M42','M51','M53','M54','M55','M59',
    'M97','M98','M99','M109','M136','M154',
  ];

  @override
  List<String> knownGCodes() => _knownG;

  @override
  List<String> knownMCodes() => _knownM;

  @override
  LineSeverity validateLine(String line, List<String> tokens) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('(') || trimmed.startsWith(';') || trimmed == '%') {
      return LineSeverity.ok;
    }

    // Check for macro variable syntax errors
    if (trimmed.contains('#') && !RegExp(r'#\d+').hasMatch(trimmed)) {
      return LineSeverity.warning;
    }

    // Check that M98 has P word
    if (tokens.contains('M98') && !tokens.any((t) => t.startsWith('P'))) {
      return LineSeverity.error;
    }

    // Check canned cycle has R word
    final cannedCycles = {'G81','G82','G83','G84','G85','G86','G87','G88','G89','G73','G74','G76'};
    if (tokens.any((t) => cannedCycles.contains(t)) && !tokens.any((t) => t.startsWith('R'))) {
      return LineSeverity.warning;
    }

    return LineSeverity.ok;
  }

  static CncDialect detectDialect(String gcode) => CncDialect.haas;
}
