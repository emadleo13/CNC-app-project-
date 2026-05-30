import 'package:flutter_test/flutter_test.dart';
import 'package:cnc_assist/core/calc/units.dart';
import 'package:cnc_assist/features/converters/domain/hardness_converter.dart';
import 'package:cnc_assist/features/drilling/domain/drilling_calculator.dart';
import 'package:cnc_assist/features/coordinates/domain/taper_calculator.dart';
import 'package:cnc_assist/features/coordinates/domain/arc_calculator.dart';
import 'package:cnc_assist/features/coordinates/domain/gcode_generator.dart';
import 'package:cnc_assist/features/precision/domain/true_position_calculator.dart';
import 'package:cnc_assist/features/precision/domain/part_weight_calculator.dart';
import 'package:cnc_assist/features/feed_speed/domain/calculators/milling_helpers.dart';

void main() {
  group('HardnessConverter', () {
    test('interpolates HRC 45 to HV/HB/tensile', () {
      final r = HardnessConverter.convert(45, HardnessScale.hrc)!;
      expect(r.hv!, closeTo(446, 1));
      expect(r.hb!, closeTo(420.5, 1));
      expect(r.tensileMPa!, closeTo(1600, 5));
    });
    test('out of range returns null', () {
      expect(HardnessConverter.convert(5, HardnessScale.hrc), isNull);
    });
  });

  group('DrillingCalculator', () {
    test('drilling rpm, point length and cut time', () {
      final r = DrillingCalculator.drilling(const DrillingInput(
        diameter: 8,
        cuttingSpeed: 30,
        feedPerRev: 0.1,
        holeDepth: 30,
        units: UnitSystem.metric,
      ))!;
      expect(r.rpm, 1194);
      expect(r.pointLength, closeTo(2.403, 0.01));
      expect(r.cutTimeMin, closeTo(0.2714, 0.005));
    });
    test('tap drill for M6x1 at 75%', () {
      final d = DrillingCalculator.tapDrill(
          majorDiameter: 6, pitch: 1, threadPercent: 75);
      expect(d, closeTo(5.19, 0.01));
    });
  });

  group('TaperCalculator', () {
    test('solves angle, slant and ratio', () {
      final r = TaperCalculator.solve(d1: 50, d2: 30, length: 40)!;
      expect(r.radialPerSide, 10);
      expect(r.angleFromAxis, closeTo(14.036, 0.01));
      expect(r.includedAngle, closeTo(28.07, 0.02));
      expect(r.slantLength, closeTo(41.231, 0.01));
      expect(r.taperRatio, closeTo(2.0, 0.0001));
    });
  });

  group('ArcCalculator', () {
    test('3-point circumcircle', () {
      final r = ArcCalculator.threePoint(
          const ArcPoint(0, 0), const ArcPoint(10, 10), const ArcPoint(20, 0))!;
      expect(r.center.x, closeTo(10, 1e-6));
      expect(r.center.z, closeTo(0, 1e-6));
      expect(r.radius, closeTo(10, 1e-6));
    });
    test('collinear points return null', () {
      expect(
        ArcCalculator.threePoint(
            const ArcPoint(0, 0), const ArcPoint(5, 0), const ArcPoint(10, 0)),
        isNull,
      );
    });
    test('radius from chord and sweep', () {
      expect(ArcCalculator.radiusFromChord(chord: 10, sweepDeg: 180),
          closeTo(5, 1e-9));
    });
  });

  group('TruePositionCalculator', () {
    test('diametral TP with MMC bonus passes', () {
      final r = TruePositionCalculator.calculate(
        trueX: 25,
        trueY: 25,
        measuredX: 25.05,
        measuredY: 24.97,
        statedTolerance: 0.2,
        condition: MaterialCondition.mmc,
        actualSize: 10.1,
        mcSize: 10.0,
      );
      expect(r.truetPosition, closeTo(0.1166, 0.001));
      expect(r.bonus, closeTo(0.1, 1e-9));
      expect(r.totalTolerance, closeTo(0.3, 1e-9));
      expect(r.withinTolerance, isTrue);
    });
  });

  group('MillingHelpers', () {
    test('cusp height', () {
      expect(MillingHelpers.cuspHeight(ballDiameter: 6, stepover: 1),
          closeTo(0.042, 0.001));
    });
    test('chip thinning factor', () {
      expect(
          MillingHelpers.chipThinningFactor(toolDiameter: 10, widthOfCut: 2),
          closeTo(1.25, 1e-9));
      expect(
          MillingHelpers.chipThinningFactor(toolDiameter: 10, widthOfCut: 6),
          1.0);
    });
    test('mrr', () {
      expect(
          MillingHelpers.mrr(widthOfCut: 5, depthOfCut: 2, feedPerMin: 200),
          2000);
    });
  });

  group('PartWeightCalculator', () {
    test('steel round bar Ø50 × 100 mm', () {
      final g = PartWeightCalculator.grams(
        shape: StockShape.roundBar,
        a: 50,
        b: 0,
        c: 100,
        densityGCm3: 7.85,
        units: UnitSystem.metric,
      );
      expect(g, closeTo(1541.4, 1));
    });
  });

  group('GcodeGenerator', () {
    test('G76 thread program is well-formed', () {
      final p = GcodeGenerator.threadG76(
          majorDiameter: 20, pitch: 1.5, zEnd: -25);
      expect(p, contains('G76'));
      expect(p, contains('M30'));
    });
    test('bolt circle emits one line per hole', () {
      final p = GcodeGenerator.boltCircleDrill(
        cycle: 'G83',
        holes: 6,
        boltCircleDiameter: 100,
        centerX: 0,
        centerY: 0,
        startAngleDeg: 0,
        rPlane: 2,
        zDepth: -15,
        feed: 120,
      );
      expect(p, contains('G83'));
      expect('X'.allMatches(p).length, greaterThanOrEqualTo(6));
    });
  });
}
