import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/features/feed_speed/domain/calculators/milling_calculator.dart';
import 'package:cnc_assist/features/feed_speed/domain/cut_parameters.dart';
import 'package:cnc_assist/features/feed_speed/domain/material_spec.dart';

void main() {
  group('MillingCalculator', () {
    final testMaterial = MaterialSpec(
      code: 'test_steel',
      name: 'Test Steel',
      nameFa: 'فولاد تست',
      category: 'steel',
      hardnessBhn: 131,
      cuttingSpeedsMetric: const CuttingSpeedSet(
        hssRough: 27,
        hssFinish: 37,
        carbideRough: 91,
        carbideFinish: 137,
      ),
      cuttingSpeedsImperial: const CuttingSpeedSet(
        hssRough: 90,
        hssFinish: 120,
        carbideRough: 300,
        carbideFinish: 450,
      ),
      chipLoadFactors: const ChipLoadFactors(
        endMill2fl: 0.002,
        endMill4fl: 0.0015,
        drill: 0.004,
        faceMill: 0.006,
      ),
      coolantRequired: false,
      notes: 'Test material',
    );

    test('calculates RPM for metric carbide roughing', () {
      final input = CalculatorInput(
        materialCode: 'test_steel',
        toolTypeCode: 'end_mill_4fl',
        toolDiameter: 10.0,
        flutes: 4,
        toolMaterial: ToolMaterial.carbide,
        operationType: OperationType.roughing,
        units: UnitSystem.metric,
        depthOfCut: 2.0,
        widthOfCut: 5.0,
      );
      final result = MillingCalculator.calculate(
        input: input,
        material: testMaterial,
      )!;
      // RPM = (91 * 1000) / (π * 10) ≈ 2897
      expect(result.rpm, closeTo(2897, 10));
    });

    test('calculates RPM for imperial HSS finishing', () {
      final input = CalculatorInput(
        materialCode: 'test_steel',
        toolTypeCode: 'end_mill_4fl',
        toolDiameter: 0.5,
        flutes: 4,
        toolMaterial: ToolMaterial.hss,
        operationType: OperationType.finishing,
        units: UnitSystem.imperial,
        depthOfCut: 0.05,
        widthOfCut: 0.25,
      );
      final result = MillingCalculator.calculate(
        input: input,
        material: testMaterial,
      )!;
      // RPM = (120 * 3.82) / 0.5 ≈ 916
      expect(result.rpm, closeTo(916, 10));
    });

    test('returns null for zero diameter', () {
      final input = CalculatorInput(
        materialCode: 'test_steel',
        toolTypeCode: 'end_mill_4fl',
        toolDiameter: 0.0,
        flutes: 4,
        toolMaterial: ToolMaterial.carbide,
        operationType: OperationType.roughing,
        units: UnitSystem.metric,
        depthOfCut: 2.0,
        widthOfCut: 5.0,
      );
      expect(
        MillingCalculator.calculate(input: input, material: testMaterial),
        isNull,
      );
    });

    test('feed rate = rpm * flutes * chipload', () {
      final input = CalculatorInput(
        materialCode: 'test_steel',
        toolTypeCode: 'end_mill_4fl',
        toolDiameter: 10.0,
        flutes: 4,
        toolMaterial: ToolMaterial.carbide,
        operationType: OperationType.roughing,
        units: UnitSystem.metric,
        depthOfCut: 2.0,
        widthOfCut: 5.0,
      );
      final result = MillingCalculator.calculate(
        input: input,
        material: testMaterial,
      )!;
      // Table chip load 0.0015" is for a ½" tool; a 10 mm tool gets 10/12.7
      // of it: 0.0015 × 25.4 × 10/12.7 = 0.030 mm.
      expect(result.chipLoad, closeTo(0.030, 0.0001));
      expect(result.feedRatePerMin, closeTo(result.rpm * 4 * 0.030, 0.1));
    });

    group('chip load follows the tool diameter', () {
      CutParameters run(
        double d, {
        String tool = 'end_mill_4fl',
        int maxRpm = 0,
      }) => MillingCalculator.calculate(
        input: CalculatorInput(
          materialCode: 'test_steel',
          toolTypeCode: tool,
          toolDiameter: d,
          flutes: 4,
          toolMaterial: ToolMaterial.carbide,
          operationType: OperationType.roughing,
          units: UnitSystem.imperial,
          depthOfCut: 0.1,
          widthOfCut: 0.1,
        ),
        material: testMaterial,
        maxRpm: maxRpm,
      )!;

      test('table value at ½", proportional below, slower growth above', () {
        expect(run(0.5).chipLoad, closeTo(0.0015, 1e-9));
        expect(run(0.25).chipLoad, closeTo(0.00075, 1e-9));
        expect(run(0.125).chipLoad, closeTo(0.000375, 1e-9));
        // 1": (1/0.5)^0.7 = 1.6245
        expect(run(1.0).chipLoad, closeTo(0.0015 * 1.6245, 1e-6));
      });

      test('face mills are not scaled', () {
        expect(run(3.0, tool: 'face_mill').chipLoad, closeTo(0.006, 1e-9));
      });

      test(
        'machine RPM limit caps RPM, keeps chip load, lowers surface speed',
        () {
          // 1/8" at 300 SFM wants 300·3.82/0.125 = 9168 RPM.
          final free = run(0.125);
          expect(free.rpm, 9168);
          expect(free.limitedFromRpm, isNull);
          final capped = run(0.125, maxRpm: 8100);
          expect(capped.rpm, 8100);
          expect(capped.limitedFromRpm, 9168);
          expect(capped.chipLoad, free.chipLoad);
          expect(
            capped.feedRatePerMin,
            closeTo(8100 * 4 * capped.chipLoad, 1e-9),
          );
          expect(capped.cuttingSpeed, closeTo(0.125 * 8100 / 3.82, 1e-6));
        },
      );
    });
  });
}
