import 'dart:math' as math;

/// Advanced milling helpers (Phase 1.5): cusp height, radial chip thinning and
/// material removal rate. Pure functions, unit-agnostic (caller keeps units
/// consistent — mm in → mm out, or in → in).
class MillingHelpers {
  MillingHelpers._();

  /// Scallop / cusp height left between parallel passes of a ball-nose mill.
  ///
  /// h = R − √(R² − (stepover/2)²)
  static double cuspHeight({
    required double ballDiameter,
    required double stepover,
  }) {
    final r = ballDiameter / 2;
    final half = stepover / 2;
    if (half >= r) return r; // stepover ≥ diameter → full radius
    return r - math.sqrt(r * r - half * half);
  }

  /// Radial chip thinning factor (RCTF) for a cut narrower than half the tool
  /// diameter. Multiply the table feed-per-tooth by this factor to keep the
  /// real chip thickness on target.
  ///
  /// RCTF = 1 / √(1 − (1 − 2·WOC/D)²)   for WOC < D/2, else 1.
  static double chipThinningFactor({
    required double toolDiameter,
    required double widthOfCut,
  }) {
    if (toolDiameter <= 0) return 1;
    final ratio = widthOfCut / toolDiameter;
    if (ratio <= 0) return 1;
    if (ratio >= 0.5) return 1;
    final term = 1 - 2 * ratio;
    final denom = math.sqrt(1 - term * term);
    return denom == 0 ? 1 : 1 / denom;
  }

  /// Material removal rate for milling: MRR = WOC × DOC × feedPerMin.
  /// Returns the same length³/min unit implied by the inputs.
  static double mrr({
    required double widthOfCut,
    required double depthOfCut,
    required double feedPerMin,
  }) =>
      widthOfCut * depthOfCut * feedPerMin;
}
