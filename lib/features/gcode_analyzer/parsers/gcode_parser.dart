import '../domain/cnc_dialect.dart';
import '../domain/gcode_line.dart';
import 'base_parser.dart';
import 'generic_parser.dart';
import 'haas_parser.dart';
import 'sinumerik_parser.dart';

class GcodeParser {
  static BaseParser parserFor(CncDialect dialect) => switch (dialect) {
        CncDialect.sinumerik => SinumerikParser(),
        CncDialect.generic   => GenericParser(),
        CncDialect.haas      => HaasParser(),
      };

  static CncDialect autoDetect(String gcode) {
    if (SinumerikParser.looksLikeSinumerik(gcode)) return CncDialect.sinumerik;
    return CncDialect.haas;
  }

  static List<GcodeLine> parse(String gcode, CncDialect dialect) {
    return parserFor(dialect).parse(gcode);
  }
}
