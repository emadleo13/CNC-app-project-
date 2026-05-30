import 'dart:math' as math;

/// Generates ready-to-edit G-code snippets (Fanuc-style). Values are a sound
/// starting point — always verify against the machine and tooling before use.
class GcodeGenerator {
  /// Fanuc G76 compound threading cycle for a 60° thread.
  static String threadG76({
    required double majorDiameter,
    required double pitch,
    required double zEnd,
    double startZ = 5,
    double firstDepth = 0.3,
    double finishAllowance = 0.05,
    int springPasses = 1,
    int chamfer = 1,
  }) {
    final threadHeight = 0.6495 * pitch; // radial, 60° thread
    final minor = majorDiameter - 2 * threadHeight;
    final pMicron = (threadHeight * 1000).round();
    final qMicron = (firstDepth * 1000).round();
    final rMm = finishAllowance.toStringAsFixed(2);
    final p1 = '${springPasses.toString().padLeft(2, '0')}'
        '${(chamfer * 10).toString().padLeft(2, '0')}'
        '60';

    final b = StringBuffer();
    b.writeln('( THREAD  Ø${majorDiameter.toStringAsFixed(2)} x ${pitch.toStringAsFixed(2)} )');
    b.writeln('G97 S800 M03');
    b.writeln('G00 X${(majorDiameter + 2).toStringAsFixed(3)} '
        'Z${startZ.toStringAsFixed(3)}');
    b.writeln('G76 P$p1 Q100 R$rMm');
    b.writeln('G76 X${minor.toStringAsFixed(3)} Z${zEnd.toStringAsFixed(3)} '
        'P$pMicron Q$qMicron F${pitch.toStringAsFixed(3)}');
    b.writeln('G00 X100. Z100.');
    b.writeln('M30');
    return b.toString();
  }

  /// Drill cycle (G81 simple / G83 peck) over a bolt-circle hole pattern.
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
  }) {
    final radius = boltCircleDiameter / 2;
    final b = StringBuffer();
    b.writeln('( $cycle  ${holes}x on Ø${boltCircleDiameter.toStringAsFixed(2)} BCD )');
    b.writeln('G90 G54');
    b.writeln('G00 X${centerX.toStringAsFixed(3)} Y${centerY.toStringAsFixed(3)}');
    b.writeln('G43 Z${(rPlane + 5).toStringAsFixed(3)} H01');

    for (var i = 0; i < holes; i++) {
      final ang = (startAngleDeg + i * 360 / holes) * math.pi / 180;
      final x = centerX + radius * math.cos(ang);
      final y = centerY + radius * math.sin(ang);
      if (i == 0) {
        final qPart = cycle == 'G83' ? ' Q${peck.toStringAsFixed(3)}' : '';
        b.writeln('$cycle X${x.toStringAsFixed(3)} Y${y.toStringAsFixed(3)} '
            'Z${zDepth.toStringAsFixed(3)} R${rPlane.toStringAsFixed(3)}'
            '$qPart F${feed.toStringAsFixed(1)}');
      } else {
        b.writeln('X${x.toStringAsFixed(3)} Y${y.toStringAsFixed(3)}');
      }
    }
    b.writeln('G80');
    b.writeln('G00 Z100.');
    b.writeln('M30');
    return b.toString();
  }
}
