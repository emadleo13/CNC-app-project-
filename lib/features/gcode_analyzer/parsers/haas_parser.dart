import '../domain/gcode_line.dart';
import 'base_parser.dart';
import 'block.dart';

Set<String> _range(int from, int to) => {for (var i = from; i <= to; i++) 'G$i'};

/// Haas mills and lathes (Fanuc-compatible). G-code list from the Haas mill
/// and lathe operator manuals, so codes like G187, G154 and G110–G129 are
/// not reported as unknown.
class HaasParser extends BaseParser {
  static final Set<String> _knownG = {
    ..._range(0, 5), 'G9', 'G10', 'G12', 'G13', 'G14', 'G15', 'G16',
    ..._range(17, 21), ..._range(28, 33), 'G35', 'G36', 'G37',
    ..._range(40, 44), 'G47', ..._range(49, 61), 'G63', 'G64',
    ..._range(65, 77), ..._range(80, 103), 'G105', 'G107',
    ..._range(110, 129), 'G136', 'G141', 'G143', 'G150', 'G153', 'G154',
    'G155', ..._range(161, 166), 'G169', 'G174', 'G184', 'G186', 'G187',
    'G195', 'G196', 'G200', 'G211', 'G212', 'G234', ..._range(241, 249),
    'G253', 'G254', 'G255', 'G266', 'G268', 'G269',
  };

  @override
  final BlockReader reader = const BlockReader(semicolonComments: false);

  @override
  String get dialectName => 'Haas';

  @override
  Set<String>? get knownGCodes => _knownG;

  @override
  Set<String> cannedCyclesFor(ProgramShape shape) => shape.isMill
      ? const {'G73', 'G74', 'G76', 'G77', 'G81', 'G82', 'G83', 'G84', 'G85', 'G86', 'G87', 'G88', 'G89'}
      // On lathes G73/G74/G76 are stock-removal, grooving and threading cycles.
      : const {'G81', 'G82', 'G83', 'G84', 'G85', 'G86', 'G87', 'G88', 'G89'};

  @override
  Set<String> get programEnds => const {'M30', 'M2'};

  @override
  String get programEndText => 'M30';

  @override
  bool get usesLengthCompensation => true;

  @override
  bool get usesG28IntermediatePoint => true;

  @override
  Set<String> get unitCodes => const {'G20', 'G21'};

  @override
  Set<String> get workOffsetCodes => {
        ..._range(54, 59), 'G54.1', 'G154', ..._range(110, 129), 'G92',
      };

  @override
  void checkBlock(Block b, List<LineIssue> out, ProgramShape shape) {
    checkCommon(b, out);
    checkFanucStyle(b, out, shape, cannedCyclesFor(shape));
  }

  /// Rules shared by Haas and generic Fanuc controls.
  static void checkFanucStyle(Block b, List<LineIssue> out, ProgramShape shape,
      Set<String> cycles) {
    // Canned cycle on its first line: depth, R plane, peck depth.
    final cycle = b.gCodes.where(cycles.contains).firstOrNull;
    if (cycle != null) {
      if (!b.has('Z')) {
        out.add(LineIssue(LineSeverity.error, 'cycle_no_z', {'code': cycle}));
      }
      if (!b.has('R')) {
        out.add(LineIssue(LineSeverity.warning, 'cycle_no_r', {'code': cycle}));
      }
      if ((cycle == 'G73' || cycle == 'G83') && !b.has('Q') && !b.has('I')) {
        out.add(LineIssue(LineSeverity.warning, 'cycle_no_q', {'code': cycle}));
      }
    }

    // Subprogram call needs the program number (Haas NGC also accepts a
    // quoted file name, which the reader strips).
    if (b.hasM('M98') && !b.has('P') && !b.hadQuotedText) {
      out.add(const LineIssue(LineSeverity.error, 'm98_no_p'));
    }

    _checkCutterComp(b, out, needsD: shape.isMill);
  }
}

/// G41/G42 must start on a straight move; mills also need the D offset.
void _checkCutterComp(Block b, List<LineIssue> out, {required bool needsD}) {
  final comp = b.gCodes.where((g) => g == 'G41' || g == 'G42').firstOrNull;
  if (comp == null) return;
  if (b.hasG('G2') || b.hasG('G3')) {
    out.add(LineIssue(LineSeverity.error, 'comp_on_arc', {'code': comp}));
  }
  if (needsD && !b.has('D')) {
    out.add(LineIssue(LineSeverity.warning, 'comp_no_d', {'code': comp}));
  }
}

/// Exposed for SinumerikParser (which has no D requirement).
void checkCutterCompStart(Block b, List<LineIssue> out) =>
    _checkCutterComp(b, out, needsD: false);
