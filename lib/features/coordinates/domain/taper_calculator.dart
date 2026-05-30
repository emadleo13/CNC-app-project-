import 'dart:math' as math;

/// Result of solving a lathe taper from two diameters and an axial length.
class TaperResult {
  final double radialPerSide; // (D1−D2)/2
  final double angleFromAxis; // degrees, measured from the turning centreline
  final double includedAngle; // degrees (2 × angleFromAxis)
  final double slantLength; // length along the taper face
  final double taperRatio; // axial length per 1 unit of diameter change (L:ΔD)

  /// Z setback so a tool of nose radius R stays tangent entering the taper
  /// (chamfer/entry aid): ΔZ = R · tan(angleFromAxis / 2). Null if no R given.
  final double? noseRSetback;

  /// True when the nose radius cannot physically fit the section.
  final bool noseRWarning;

  const TaperResult({
    required this.radialPerSide,
    required this.angleFromAxis,
    required this.includedAngle,
    required this.slantLength,
    required this.taperRatio,
    required this.noseRSetback,
    required this.noseRWarning,
  });
}

class TaperCalculator {
  /// Solve a taper given the start diameter [d1], end diameter [d2] and the
  /// axial [length] between them. Optionally compute a nose-radius entry
  /// setback for an insert of radius [noseR].
  static TaperResult? solve({
    required double d1,
    required double d2,
    required double length,
    double noseR = 0,
  }) {
    if (length <= 0) return null;
    final radialPerSide = (d1 - d2).abs() / 2;
    final angleRad = math.atan2(radialPerSide, length);
    final angleDeg = angleRad * 180 / math.pi;
    final slant = math.sqrt(length * length + radialPerSide * radialPerSide);
    final deltaD = (d1 - d2).abs();
    final ratio = deltaD == 0 ? double.infinity : length / deltaD;

    double? setback;
    var warn = false;
    if (noseR > 0) {
      setback = noseR * math.tan(angleRad / 2);
      // Radius cannot exceed the section it must blend into.
      warn = noseR > slant / 2 || noseR > radialPerSide && radialPerSide > 0;
    }

    return TaperResult(
      radialPerSide: radialPerSide,
      angleFromAxis: angleDeg,
      includedAngle: angleDeg * 2,
      slantLength: slant,
      taperRatio: ratio,
      noseRSetback: setback,
      noseRWarning: warn,
    );
  }
}
