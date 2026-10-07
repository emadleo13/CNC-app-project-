import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/core/calc/units.dart';
import 'package:cnc_assist/features/turning/domain/turning_calculator.dart';

void main() {
  group('TurningCalculator', () {
    test('metric RPM, feed, MRR for a known case', () {
      final r = TurningCalculator.calculate(const TurningInput(
        workDiameter: 50,
        cuttingSpeed: 200, // m/min
        feedPerRev: 0.2,
        cutLength: 100,
        depthOfCut: 2,
        passes: 1,
        units: UnitSystem.metric,
      ))!;

      // RPM = 200*1000 / (pi*50) ≈ 1273
      expect(r.rpm, 1273);
      // feed/min = rpm * fr
      expect(r.feedPerMin, closeTo(254.6, 0.5));
      // Q = vc * ap * fn = 200 * 2 * 0.2
      expect(r.mrr, closeTo(80.0, 0.001));
      // cut time = L*passes/feedPerMin
      expect(r.cutTimeMin, closeTo(0.3928, 0.001));
    });

    test('multiple passes scale cut time linearly', () {
      final one = TurningCalculator.calculate(const TurningInput(
        workDiameter: 40,
        cuttingSpeed: 150,
        feedPerRev: 0.15,
        cutLength: 80,
        depthOfCut: 1.5,
        passes: 1,
        units: UnitSystem.metric,
      ))!;
      final three = TurningCalculator.calculate(const TurningInput(
        workDiameter: 40,
        cuttingSpeed: 150,
        feedPerRev: 0.15,
        cutLength: 80,
        depthOfCut: 1.5,
        passes: 3,
        units: UnitSystem.metric,
      ))!;
      expect(three.cutTimeMin, closeTo(one.cutTimeMin * 3, 0.0001));
    });

    test('invalid inputs return null', () {
      expect(
        TurningCalculator.calculate(const TurningInput(
          workDiameter: 0,
          cuttingSpeed: 200,
          feedPerRev: 0.2,
          cutLength: 100,
          depthOfCut: 2,
          passes: 1,
          units: UnitSystem.metric,
        )),
        isNull,
      );
    });
  });

  test('machine RPM limit caps turning RPM and lowers the real surface speed', () {
    // Ø10 at 200 m/min wants 6366 RPM.
    const input = TurningInput(
      workDiameter: 10, cuttingSpeed: 200, feedPerRev: 0.2, cutLength: 50,
      depthOfCut: 1, passes: 1, units: UnitSystem.metric,
    );
    final free = TurningCalculator.calculate(input)!;
    expect(free.rpm, 6366);
    expect(free.limitedFromRpm, isNull);
    final capped = TurningCalculator.calculate(input, maxRpm: 4000)!;
    expect(capped.rpm, 4000);
    expect(capped.limitedFromRpm, 6366);
    expect(capped.feedPerMin, closeTo(800, 1e-9));
    expect(capped.cuttingSpeed, closeTo(3.14159265 * 10 * 4000 / 1000, 1e-3));
    // MRR uses the speed actually reached.
    expect(capped.mrr, closeTo(capped.cuttingSpeed * 1 * 0.2, 1e-9));
  });
}
