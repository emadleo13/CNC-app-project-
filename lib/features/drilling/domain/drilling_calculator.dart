import 'dart:math' as math;
import '../../../core/calc/units.dart';

class DrillingInput {
  final double diameter;
  final double cuttingSpeed; // m/min or SFM
  final double feedPerRev; // mm/rev or in/rev
  final double holeDepth;
  final double pointAngle; // included angle, degrees (typ. 118 or 135)
  final UnitSystem units;

  const DrillingInput({
    required this.diameter,
    required this.cuttingSpeed,
    required this.feedPerRev,
    required this.holeDepth,
    this.pointAngle = 118,
    required this.units,
  });
}

class DrillingResult {
  final int rpm;
  final double feedPerMin;
  final double pointLength;
  final double cutTimeMin;
  final UnitSystem units;

  const DrillingResult({
    required this.rpm,
    required this.feedPerMin,
    required this.pointLength,
    required this.cutTimeMin,
    required this.units,
  });

  String get rpmFormatted => rpm.toString();
  String get feedFormatted =>
      '${feedPerMin.toStringAsFixed(1)} ${units.feedLabel}';
  String get pointLengthFormatted =>
      '${pointLength.toStringAsFixed(units.isMetric ? 2 : 4)} ${units.lengthLabel}';
  String get cutTimeFormatted {
    final totalSeconds = (cutTimeMin * 60).round();
    return '${totalSeconds ~/ 60}m ${(totalSeconds % 60).toString().padLeft(2, '0')}s';
  }
}

class DrillingCalculator {
  /// Drilling speeds/feeds + cycle time (drill must travel through the point
  /// length to fully break through).
  static DrillingResult? drilling(DrillingInput input) {
    if (input.diameter <= 0 || input.cuttingSpeed <= 0) return null;
    final rpm = SpeedFormulas.rpm(
      cuttingSpeed: input.cuttingSpeed,
      diameter: input.diameter,
      isMetric: input.units.isMetric,
    );
    final feedPerMin =
        SpeedFormulas.feedPerMin(rpm: rpm, feedPerRev: input.feedPerRev);

    // Point length = (D/2) / tan(pointAngle/2)
    final halfAngleRad = (input.pointAngle / 2) * math.pi / 180;
    final pointLength = (input.diameter / 2) / math.tan(halfAngleRad);

    final travel = input.holeDepth + pointLength;
    final cutTimeMin = feedPerMin > 0 ? travel / feedPerMin : 0.0;

    return DrillingResult(
      rpm: rpm,
      feedPerMin: feedPerMin,
      pointLength: pointLength,
      cutTimeMin: cutTimeMin,
      units: input.units,
    );
  }

  /// Recommended tap drill diameter for a 60° thread.
  ///
  /// metric:   pitch in mm.
  /// imperial: pass pitch = 1/TPI (inches).
  /// tapDrill = D − (%/100) × pitch × 1.0825
  static double tapDrill({
    required double majorDiameter,
    required double pitch,
    required double threadPercent,
  }) {
    return majorDiameter - (threadPercent / 100) * pitch * 1.0825;
  }
}
