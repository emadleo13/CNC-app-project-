import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/features/feed_speed/domain/calculators/milling_calculator.dart';
import 'package:cnc_assist/features/feed_speed/domain/cut_parameters.dart';
import 'package:cnc_assist/features/feed_speed/domain/material_spec.dart';

void main() {
  group('MillingCalculator', () {
    final testMaterial = MaterialSpec(
      code:      'test_steel',
      name:      'Test Steel',
      nameFa:    'فولاد تست',
      category:  'steel',
      hardnessBhn: 131,
      cuttingSpeedsMetric:   const CuttingSpeedSet(hssRough: 27, hssFinish: 37, carbideRough: 91, carbideFinish: 137),
      cuttingSpeedsImperial: const CuttingSpeedSet(hssRough: 90, hssFinish: 120, carbideRough: 300, carbideFinish: 450),
      chipLoadFactors: const ChipLoadFactors(endMill2fl: 0.002, endMill4fl: 0.0015, drill: 0.004, faceMill: 0.006),
      coolantRequired: false,
      notes: 'Test material',
    );

    test('calculates RPM for metric carbide roughing', () {
      final input = CalculatorInput(
        materialCode:  'test_steel',
        toolTypeCode:  'end_mill_4fl',
        toolDiameter:  10.0,
        flutes:        4,
        toolMaterial:  ToolMaterial.carbide,
        operationType: OperationType.roughing,
        units:         UnitSystem.metric,
        depthOfCut:    2.0,
        widthOfCut:    5.0,
      );
      final result = MillingCalculator.calculate(input: input, material: testMaterial)!;
      // RPM = (91 * 1000) / (π * 10) ≈ 2897
      expect(result.rpm, closeTo(2897, 10));
    });

    test('calculates RPM for imperial HSS finishing', () {
      final input = CalculatorInput(
        materialCode:  'test_steel',
        toolTypeCode:  'end_mill_4fl',
        toolDiameter:  0.5,
        flutes:        4,
        toolMaterial:  ToolMaterial.hss,
        operationType: OperationType.finishing,
        units:         UnitSystem.imperial,
        depthOfCut:    0.05,
        widthOfCut:    0.25,
      );
      final result = MillingCalculator.calculate(input: input, material: testMaterial)!;
      // RPM = (120 * 3.82) / 0.5 ≈ 916
      expect(result.rpm, closeTo(916, 10));
    });

    test('returns null for zero diameter', () {
      final input = CalculatorInput(
        materialCode:  'test_steel',
        toolTypeCode:  'end_mill_4fl',
        toolDiameter:  0.0,
        flutes:        4,
        toolMaterial:  ToolMaterial.carbide,
        operationType: OperationType.roughing,
        units:         UnitSystem.metric,
        depthOfCut:    2.0,
        widthOfCut:    5.0,
      );
      expect(MillingCalculator.calculate(input: input, material: testMaterial), isNull);
    });

    test('feed rate = rpm * flutes * chipload', () {
      final input = CalculatorInput(
        materialCode:  'test_steel',
        toolTypeCode:  'end_mill_4fl',
        toolDiameter:  10.0,
        flutes:        4,
        toolMaterial:  ToolMaterial.carbide,
        operationType: OperationType.roughing,
        units:         UnitSystem.metric,
        depthOfCut:    2.0,
        widthOfCut:    5.0,
      );
      final result = MillingCalculator.calculate(input: input, material: testMaterial)!;
      // chipload_metric = 0.0015 * 25.4 = 0.0381 mm
      // feed = rpm * 4 * 0.0381
      final expectedFeed = result.rpm * 4 * (0.0015 * 25.4);
      expect(result.feedRatePerMin, closeTo(expectedFeed, 0.1));
    });
  });
}
