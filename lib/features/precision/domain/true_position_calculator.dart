import 'dart:math' as math;

enum MaterialCondition { rfs, mmc, lmc }

class TruePositionResult {
  final double deviationX;
  final double deviationY;
  final double truetPosition; // diametral (2 × radial error)
  final double bonus;
  final double totalTolerance;
  final bool withinTolerance;

  const TruePositionResult({
    required this.deviationX,
    required this.deviationY,
    required this.truetPosition,
    required this.bonus,
    required this.totalTolerance,
    required this.withinTolerance,
  });
}

class TruePositionCalculator {
  /// Diametral true position with optional bonus tolerance.
  ///
  /// TP = 2 · √(ΔX² + ΔY²)
  /// bonus = |actualSize − materialConditionSize|  (0 for RFS)
  /// total allowed = statedTolerance + bonus
  static TruePositionResult calculate({
    required double trueX,
    required double trueY,
    required double measuredX,
    required double measuredY,
    required double statedTolerance,
    MaterialCondition condition = MaterialCondition.rfs,
    double actualSize = 0,
    double mcSize = 0,
  }) {
    final dx = measuredX - trueX;
    final dy = measuredY - trueY;
    final tp = 2 * math.sqrt(dx * dx + dy * dy);

    double bonus = 0;
    if (condition != MaterialCondition.rfs) {
      bonus = (actualSize - mcSize).abs();
    }
    final total = statedTolerance + bonus;

    return TruePositionResult(
      deviationX: dx,
      deviationY: dy,
      truetPosition: tp,
      bonus: bonus,
      totalTolerance: total,
      withinTolerance: tp <= total,
    );
  }
}
