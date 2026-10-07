import '../../../core/calc/units.dart';

/// Inputs for a single turning operation (OD / facing rough pass).
class TurningInput {
  final double workDiameter; // mm or in
  final double cuttingSpeed; // m/min (metric) or SFM (imperial)
  final double feedPerRev; // mm/rev or in/rev
  final double cutLength; // axial length per pass
  final double depthOfCut; // ap per pass
  final int passes;
  final UnitSystem units;

  const TurningInput({
    required this.workDiameter,
    required this.cuttingSpeed,
    required this.feedPerRev,
    required this.cutLength,
    required this.depthOfCut,
    required this.passes,
    required this.units,
  });
}

class TurningResult {
  final int rpm;
  final double feedPerMin;
  final double cutTimeMin;
  final double mrr; // cm³/min (metric) or in³/min (imperial)
  final UnitSystem units;

  /// Surface speed actually reached (lower than asked when RPM is capped).
  final double cuttingSpeed;

  /// Requested RPM when the machine limit capped it, else null.
  final int? limitedFromRpm;

  const TurningResult({
    required this.rpm,
    required this.feedPerMin,
    required this.cutTimeMin,
    required this.mrr,
    required this.units,
    required this.cuttingSpeed,
    this.limitedFromRpm,
  });

  bool get isMetric => units.isMetric;

  String get rpmFormatted => rpm.toString();
  String get feedFormatted =>
      '${feedPerMin.toStringAsFixed(1)} ${units.feedLabel}';
  String get mrrFormatted =>
      '${mrr.toStringAsFixed(2)} ${isMetric ? 'cm³/min' : 'in³/min'}';

  /// Cut time as mm:ss.
  String get cutTimeFormatted {
    final totalSeconds = (cutTimeMin * 60).round();
    final m = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;
    return '${m}m ${sec.toString().padLeft(2, '0')}s';
  }
}

/// Pure turning feed/speed + cycle-time calculator.
class TurningCalculator {
  /// [maxRpm] is the machine's spindle limit (0 = none), as set with G50 S on
  /// the control. At small diameters the requested RPM often exceeds it.
  static TurningResult? calculate(TurningInput input, {int maxRpm = 0}) {
    if (input.workDiameter <= 0 || input.cuttingSpeed <= 0) return null;
    final isMetric = input.units.isMetric;

    final requestedRpm = SpeedFormulas.rpm(
      cuttingSpeed: input.cuttingSpeed,
      diameter: input.workDiameter,
      isMetric: isMetric,
    );
    final limited = maxRpm > 0 && requestedRpm > maxRpm;
    final rpm = limited ? maxRpm : requestedRpm;
    final vc = limited
        ? SpeedFormulas.cuttingSpeed(rpm: rpm, diameter: input.workDiameter, isMetric: isMetric)
        : input.cuttingSpeed;
    final feedPerMin =
        SpeedFormulas.feedPerMin(rpm: rpm, feedPerRev: input.feedPerRev);

    final passes = input.passes < 1 ? 1 : input.passes;
    final cutTimeMin =
        feedPerMin > 0 ? (input.cutLength * passes) / feedPerMin : 0.0;

    // Q = vc × ap × fn        [cm³/min]  (metric)
    // Q = 12 × SFM × ap × fn  [in³/min]  (imperial)
    final mrr = isMetric
        ? vc * input.depthOfCut * input.feedPerRev
        : 12 * vc * input.depthOfCut * input.feedPerRev;

    return TurningResult(
      rpm: rpm,
      feedPerMin: feedPerMin,
      cutTimeMin: cutTimeMin,
      mrr: mrr,
      units: input.units,
      cuttingSpeed: vc,
      limitedFromRpm: limited ? requestedRpm : null,
    );
  }
}
