import 'dart:math' as math;

/// Why a set of generator inputs cannot produce a sensible program.
enum GenProblem { pitch, diameter, zEnd, holes, bcd, planes, feed, rpm, peck, tool }

/// Generates complete, metric Fanuc/Haas programs: safe-start line, tool
/// call, spindle and coolant, the cycle, and a safe return home. They pass
/// the app's own analyzer with no findings (see test/calculators_test.dart).
/// They are still starting points, so every program opens with a
/// verify-before-running comment.
class GcodeGenerator {
  GcodeGenerator._();

  static const _verify = '(VERIFY BEFORE RUNNING: GRAPHICS, DRY RUN, SINGLE BLOCK)';

  /// Thread start point: 1 mm above the diameter, 5 mm in front of the face.
  static const threadStartZ = 5.0;

  // ── G76 threading (lathe) ──────────────────────────────────────────────────

  static List<GenProblem> checkThread({
    required double majorDiameter,
    required double pitch,
    required double zEnd,
    int tool = 1,
    int rpm = 800,
  }) => [
        if (!(pitch > 0)) GenProblem.pitch,
        if (pitch > 0 && majorDiameter - 2 * _threadHeight(pitch) <= 0) GenProblem.diameter,
        if (!(zEnd < threadStartZ)) GenProblem.zEnd,
        if (tool < 1 || tool > 99) GenProblem.tool,
        if (rpm < 1 || rpm > 30000) GenProblem.rpm,
      ];

  /// Fanuc two-block G76 for an external 60° metric thread.
  static String threadG76({
    required double majorDiameter,
    required double pitch,
    required double zEnd,
    int tool = 1,
    int rpm = 800,
    int programNumber = 1001,
    double finishAllowance = 0.05,
    int springPasses = 1,
    int chamfer = 1,
  }) {
    final h = _threadHeight(pitch);
    final minor = majorDiameter - 2 * h;
    // First pass depth: G76 cuts constant chip area, so pass n is Q·√n deep.
    // Q = h/√10 gives about ten passes at any pitch (0.3 mm at P1.5).
    final first = (h / math.sqrt(10)).clamp(0.05, 0.5);
    final minCut = math.min(0.1, first / 2);
    final m = springPasses.toString().padLeft(2, '0');
    final r = (chamfer * 10).toString().padLeft(2, '0');
    final tt = tool.toString().padLeft(2, '0');
    final startX = majorDiameter + 2;

    return [
      '%',
      'O$programNumber (THREAD M${_label(majorDiameter)}X${_label(pitch)} - FANUC/HAAS LATHE)',
      _verify,
      'G18 G21 G40 G80 G99',
      'G28 U0.',
      'T$tt$tt',
      'G54',
      'G97 S$rpm M03',
      'G00 X${_f(startX)} Z${_f(threadStartZ)} M08',
      'G76 P$m${r}60 Q${_um(minCut)} R${finishAllowance.toStringAsFixed(2)}',
      'G76 X${_f(minor)} Z${_f(zEnd)} P${_um(h)} Q${_um(first)} F${_f(pitch)}',
      'M09',
      'G28 U0.',
      'G28 W0.',
      'M05',
      'M30',
      '%',
    ].join('\n');
  }

  // ── Bolt-circle drilling (mill) ────────────────────────────────────────────

  static List<GenProblem> checkBoltCircle({
    required String cycle,
    required int holes,
    required double boltCircleDiameter,
    required double rPlane,
    required double zDepth,
    required double feed,
    double peck = 3,
    double clearanceZ = 25,
    int tool = 1,
    int rpm = 1000,
  }) => [
        if (holes < 1 || holes > 360) GenProblem.holes,
        if (!(boltCircleDiameter > 0)) GenProblem.bcd,
        if (!(zDepth < rPlane && rPlane < clearanceZ)) GenProblem.planes,
        if (!(feed > 0)) GenProblem.feed,
        if (rpm < 1 || rpm > 30000) GenProblem.rpm,
        if (cycle == 'G83' && !(peck > 0)) GenProblem.peck,
        if (tool < 1 || tool > 99) GenProblem.tool,
      ];

  /// G81 (simple) or G83 (peck) on a bolt-circle pattern, returning to the
  /// clearance plane (G98) between holes so the tool clears clamps.
  static String boltCircleDrill({
    required String cycle, // 'G81' or 'G83'
    required int holes,
    required double boltCircleDiameter,
    required double centerX,
    required double centerY,
    required double startAngleDeg,
    required double rPlane,
    required double zDepth,
    required double feed,
    double peck = 3,
    double clearanceZ = 25,
    int tool = 1,
    int rpm = 1000,
    int programNumber = 1002,
  }) {
    final radius = boltCircleDiameter / 2;
    final points = [
      for (var i = 0; i < holes; i++)
        () {
          final ang = (startAngleDeg + i * 360 / holes) * math.pi / 180;
          return (centerX + radius * math.cos(ang), centerY + radius * math.sin(ang));
        }(),
    ];
    final tt = tool.toString().padLeft(2, '0');
    final first = points.first;
    final qPart = cycle == 'G83' ? ' Q${_f(peck)}' : '';

    return [
      '%',
      'O$programNumber (${holes}X ON BCD ${_label(boltCircleDiameter)} - $cycle)',
      _verify,
      'G17 G21 G40 G49 G80 G90 G94',
      'G28 G91 Z0.',
      'G90',
      'T$tool M06',
      'G54',
      'S$rpm M03',
      'G00 X${_f(first.$1)} Y${_f(first.$2)}',
      'G43 Z${_f(clearanceZ)} H$tt M08',
      'G98 $cycle X${_f(first.$1)} Y${_f(first.$2)} Z${_f(zDepth)} R${_f(rPlane)}$qPart F${_f(feed)}',
      for (final p in points.skip(1)) 'X${_f(p.$1)} Y${_f(p.$2)}',
      'G80',
      'G00 Z${_f(clearanceZ)}',
      'M09',
      'M05',
      'G28 G91 Z0.',
      'G90',
      'M30',
      '%',
    ].join('\n');
  }

  /// Radial thread height of a 60° external thread.
  static double _threadHeight(double pitch) => 0.6495 * pitch;

  /// Length with a decimal point and no trailing zeros: 22 → "22.",
  /// 18.0510 → "18.051". The point matters on Fanuc-type controls.
  static String _f(double v) {
    final rounded = (v * 1000).round() / 1000;
    if (rounded == 0) return '0.';
    var s = rounded.toStringAsFixed(3);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    return s;
  }

  /// A number for a comment: no trailing point (M20X1.5, not M20.X1.5).
  static String _label(double v) {
    final s = _f(v);
    return s.endsWith('.') ? s.substring(0, s.length - 1) : s;
  }

  /// G76 P/Q are in 0.001 mm (G21).
  static int _um(double mm) => (mm * 1000).round();
}
