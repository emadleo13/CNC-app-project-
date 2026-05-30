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

  const TurningResult({
    required this.rpm,
    required this.feedPerMin,
    required this.cutTimeMin,
    required this.mrr,
    required this.units,
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
  static TurningResult? calculate(TurningInput input) {
    if (input.workDiameter <= 0 || input.cuttingSpeed <= 0) return null;
    final isMetric = input.units.isMetric;

    final rpm = SpeedFormulas.rpm(
      cuttingSpeed: input.cuttingSpeed,
      diameter: input.workDiameter,
      isMetric: isMetric,
    );
    final feedPerMin =
        SpeedFormulas.feedPerMin(rpm: rpm, feedPerRev: input.feedPerRev);

    final passes = input.passes < 1 ? 1 : input.passes;
    final cutTimeMin =
        feedPerMin > 0 ? (input.cutLength * passes) / feedPerMin : 0.0;

    // Q = vc × ap × fn        [cm³/min]  (metric)
    // Q = 12 × SFM × ap × fn  [in³/min]  (imperial)
    final mrr = isMetric
        ? input.cuttingSpeed * input.depthOfCut * input.feedPerRev
        : 12 * input.cuttingSpeed * input.depthOfCut * input.feedPerRev;

    return TurningResult(
      rpm: rpm,
      feedPerMin: feedPerMin,
      cutTimeMin: cutTimeMin,
      mrr: mrr,
      units: input.units,
    );
  }
}
