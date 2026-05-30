import 'dart:math' as math;
import '../../../core/calc/units.dart';

/// Stock shapes supported by the part-weight calculator.
enum StockShape { roundBar, tube, hexBar, square, rectBar, sheet, plate }

extension StockShapeX on StockShape {
  String get label => switch (this) {
        StockShape.roundBar => 'Round bar',
        StockShape.tube => 'Tube',
        StockShape.hexBar => 'Hex bar',
        StockShape.square => 'Square bar',
        StockShape.rectBar => 'Rect bar',
        StockShape.sheet => 'Sheet',
        StockShape.plate => 'Plate',
      };
}

/// Computes the mass of a stock blank from its geometry and material density.
///
/// Density is given in g/cm³ (e.g. steel 7.85, aluminium 2.70). Lengths are mm
/// (metric) or inches (imperial); the result is grams and pounds.
class PartWeightCalculator {
  /// [a],[b],[c] are the shape-specific dimensions (see UI labels). All lengths
  /// share [units]. Returns mass in grams.
  static double grams({
    required StockShape shape,
    required double a,
    required double b,
    required double c,
    required double densityGCm3,
    required UnitSystem units,
  }) {
    final volumeCm3 = _volumeCm3(shape, a, b, c, units);
    return volumeCm3 * densityGCm3;
  }

  static double pounds({
    required StockShape shape,
    required double a,
    required double b,
    required double c,
    required double densityGCm3,
    required UnitSystem units,
  }) =>
      grams(
          shape: shape,
          a: a,
          b: b,
          c: c,
          densityGCm3: densityGCm3,
          units: units) /
      453.59237;

  /// Cross-section area × length, normalised to cm³.
  static double _volumeCm3(
      StockShape shape, double a, double b, double c, UnitSystem units) {
    // Convert every input length to cm first.
    final k = units.isMetric ? 0.1 : 2.54; // mm→cm or in→cm
    final x = a * k, y = b * k, z = c * k;

    final area = switch (shape) {
      // a = diameter, c = length
      StockShape.roundBar => math.pi * (x / 2) * (x / 2),
      // a = OD, b = ID, c = length
      StockShape.tube => math.pi * ((x / 2) * (x / 2) - (y / 2) * (y / 2)),
      // a = across flats, c = length
      StockShape.hexBar => (math.sqrt(3) / 2) * x * x,
      // a = side, c = length
      StockShape.square => x * x,
      // a × b cross-section, c = length
      StockShape.rectBar => x * y,
      // a × b face, c = thickness
      StockShape.sheet => x * y,
      StockShape.plate => x * y,
    };

    final length = switch (shape) {
      StockShape.sheet || StockShape.plate => z, // thickness as the 3rd dim
      _ => z,
    };
    return area * length;
  }
}
