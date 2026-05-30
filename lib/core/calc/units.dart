import 'dart:math' as math;

/// Unit system shared across every calculator feature.
///
/// Lives in `core` (not in any single feature) so that turning, drilling,
/// converters, etc. can all share one enum without depending on each other.
enum UnitSystem { metric, imperial }

extension UnitSystemX on UnitSystem {
  bool get isMetric => this == UnitSystem.metric;

  /// Linear unit label, e.g. for diameters / depths.
  String get lengthLabel => isMetric ? 'mm' : 'in';

  /// Feed-per-minute label.
  String get feedLabel => isMetric ? 'mm/min' : 'in/min';

  /// Cutting-speed (surface speed) label.
  String get cuttingSpeedLabel => isMetric ? 'm/min' : 'SFM';
}

/// Pure speed/feed formulas shared by milling, turning and drilling.
///
/// Keeping these in one place means the metric/imperial RPM formula is defined
/// exactly once — see [MillingCalculator] which delegates here.
class SpeedFormulas {
  SpeedFormulas._();

  /// Spindle RPM from surface cutting speed and diameter.
  ///
  /// metric:   RPM = (Vc × 1000) / (π × D)   [Vc in m/min, D in mm]
  /// imperial: RPM = (SFM × 3.82) / D          [D in inches]
  static int rpm({
    required double cuttingSpeed,
    required double diameter,
    required bool isMetric,
  }) {
    if (diameter <= 0) return 0;
    return isMetric
        ? ((cuttingSpeed * 1000) / (math.pi * diameter)).round()
        : ((cuttingSpeed * 3.82) / diameter).round();
  }

  /// Inverse of [rpm]: surface cutting speed from spindle RPM and diameter.
  static double cuttingSpeed({
    required int rpm,
    required double diameter,
    required bool isMetric,
  }) {
    if (diameter <= 0) return 0;
    return isMetric
        ? (math.pi * diameter * rpm) / 1000
        : (diameter * rpm) / 3.82;
  }

  /// Feed per minute from spindle RPM and feed per revolution.
  static double feedPerMin({required int rpm, required double feedPerRev}) =>
      rpm * feedPerRev;

  /// Feed per revolution from feed per minute and spindle RPM.
  static double feedPerRev({required double feedPerMin, required int rpm}) =>
      rpm == 0 ? 0 : feedPerMin / rpm;

  /// Feed per minute for a multi-tooth cutter (milling).
  static double feedPerMinFromTooth({
    required int rpm,
    required int teeth,
    required double feedPerTooth,
  }) =>
      rpm * teeth * feedPerTooth;
}
