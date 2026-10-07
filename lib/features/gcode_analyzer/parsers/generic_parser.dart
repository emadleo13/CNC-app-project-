import '../domain/gcode_line.dart';
import 'base_parser.dart';
import 'block.dart';
import 'haas_parser.dart';

/// Generic ISO / Fanuc. Same rules as Haas, minus the unknown-code check
/// (Fanuc builders add their own codes), plus the decimal-point check.
class GenericParser extends HaasParser {
  @override
  String get dialectName => 'Fanuc/ISO';

  @override
  Set<String>? get knownGCodes => null;

  @override
  Set<String> get workOffsetCodes => {...super.workOffsetCodes, 'G50'};

  /// Addresses whose integer values Fanuc-type controls read in least input
  /// increments when the decimal point is missing (X10 = 0.010 mm).
  static const _scaledAddresses = ['X', 'Y', 'Z', 'U', 'V', 'W', 'I', 'J', 'K', 'R'];

  @override
  void checkBlock(Block b, List<LineIssue> out, ProgramShape shape) {
    super.checkBlock(b, out, shape);
    for (final a in _scaledAddresses) {
      final v = b.words[a];
      if (v == null || v.contains('.')) continue;
      final n = int.tryParse(v);
      if (n == null || n == 0) continue;
      out.add(LineIssue(LineSeverity.warning, 'no_decimal', {'word': '$a$v', 'fixed': '$a$v.'}));
      break; // one reminder per line is enough
    }
  }
}
