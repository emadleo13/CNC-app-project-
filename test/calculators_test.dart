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
import 'package:cnc_assist/features/gcode_analyzer/domain/cnc_dialect.dart';
import 'package:cnc_assist/features/gcode_analyzer/parsers/gcode_parser.dart';

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
    test('machine RPM limit caps drilling RPM', () {
      final r = DrillingCalculator.drilling(
        const DrillingInput(diameter: 2, cuttingSpeed: 60, feedPerRev: 0.04,
            holeDepth: 6, units: UnitSystem.metric),
        maxRpm: 6000,
      )!;
      expect(r.limitedFromRpm, 9549); // 60·1000/(π·2)
      expect(r.rpm, 6000);
      expect(r.feedPerMin, closeTo(240, 1e-9));
    });
    test('tap drill at 75% matches the standard drill sizes', () {
      // M6×1 → 5.0 mm, M10×1.5 → 8.5 mm, 1/4-20 → #7 (0.201").
      expect(
          DrillingCalculator.tapDrill(
              majorDiameter: 6, pitch: 1, threadPercent: 75),
          closeTo(5.026, 0.001));
      expect(
          DrillingCalculator.tapDrill(
              majorDiameter: 10, pitch: 1.5, threadPercent: 75),
          closeTo(8.539, 0.001));
      expect(
          DrillingCalculator.tapDrill(
              majorDiameter: 0.25, pitch: 1 / 20, threadPercent: 75),
          closeTo(0.2013, 0.0001));
    });
    test('tap drill for M6x1 at 75% stays inside the 6H minor diameter', () {
      // ISO 965-1, M6×1 6H: D1 min 4.917, max 5.153.
      final d = DrillingCalculator.tapDrill(
          majorDiameter: 6, pitch: 1, threadPercent: 75);
      expect(d, inInclusiveRange(4.917, 5.153));
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
    test('sweep follows the arc through the middle point', () {
      // Quarter circle from (10,0) clockwise through (7.07,-7.07) to (0,-10).
      final cw = ArcCalculator.threePoint(const ArcPoint(10, 0),
          const ArcPoint(7.0710678, -7.0710678), const ArcPoint(0, -10))!;
      expect(cw.sweepAngle, closeTo(90, 1e-6));
      expect(cw.clockwise, isTrue);
      // Same end points the other way round: 270° counter-clockwise.
      final ccw = ArcCalculator.threePoint(const ArcPoint(10, 0),
          const ArcPoint(-10, 0), const ArcPoint(0, -10))!;
      expect(ccw.sweepAngle, closeTo(270, 1e-6));
      expect(ccw.clockwise, isFalse);
      // Upper half circle, (0,0) → (10,10) → (20,0), runs clockwise.
      final top = ArcCalculator.threePoint(
          const ArcPoint(0, 0), const ArcPoint(10, 10), const ArcPoint(20, 0))!;
      expect(top.sweepAngle, closeTo(180, 1e-6));
      expect(top.clockwise, isTrue);
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
    List<String> analyze(String program) => [
          for (final l in GcodeParser.parse(program, CncDialect.haas))
            for (final i in l.issues) 'L${l.lineNumber} ${i.rule}',
        ];

    test('G76 program is complete and passes the analyzer', () {
      final p = GcodeGenerator.threadG76(majorDiameter: 20, pitch: 1.5, zEnd: -25);
      for (final part in ['G18 G21', 'T0101', 'G97 S800 M03', 'G28 U0.', 'M30', 'VERIFY']) {
        expect(p, contains(part));
      }
      // Thread height 0.974, minor Ø 20 − 2·0.97425 = 18.0515 → 18.052,
      // first pass h/√10 ≈ 0.308.
      expect(p, contains('G76 X18.052 Z-25. P974 Q308 F1.5'));
      expect(p, contains('(THREAD M20X1.5'));
      expect(analyze(p), isEmpty);
    });

    test('fine pitch gets a proportionally small first pass', () {
      final p = GcodeGenerator.threadG76(majorDiameter: 6, pitch: 0.5, zEnd: -10);
      expect(p, contains('P325 Q103 F0.5'));
    });

    test('bolt circle: spindle, tool, length offset, G98, G80 and safe home', () {
      for (final cycle in ['G81', 'G83']) {
        final p = GcodeGenerator.boltCircleDrill(
          cycle: cycle, holes: 6, boltCircleDiameter: 100, centerX: 0,
          centerY: 0, startAngleDeg: 0, rPlane: 2, zDepth: -15, feed: 120,
        );
        for (final part in ['G21', 'T1 M06', 'S1000 M03', 'G43 Z25. H01', 'G98 $cycle',
            'G80', 'G28 G91 Z0.', 'M30']) {
          expect(p, contains(part), reason: '$cycle: $part');
        }
        expect(p.contains(' Q3.'), cycle == 'G83');
        expect('X'.allMatches(p).length, greaterThanOrEqualTo(6));
        expect(analyze(p), isEmpty, reason: cycle);
      }
    });

    test('bad inputs are reported instead of generated', () {
      expect(GcodeGenerator.checkThread(majorDiameter: 20, pitch: 0, zEnd: -25),
          [GenProblem.pitch]);
      expect(GcodeGenerator.checkThread(majorDiameter: 1, pitch: 2, zEnd: -25),
          [GenProblem.diameter]);
      expect(GcodeGenerator.checkThread(majorDiameter: 20, pitch: 1.5, zEnd: 10),
          [GenProblem.zEnd]);
      expect(GcodeGenerator.checkBoltCircle(cycle: 'G83', holes: 6, boltCircleDiameter: 100,
          rPlane: 2, zDepth: 5, feed: 100), [GenProblem.planes]);
      expect(GcodeGenerator.checkBoltCircle(cycle: 'G83', holes: 6, boltCircleDiameter: 100,
          rPlane: 2, zDepth: -5, feed: 100, peck: 0), [GenProblem.peck]);
      expect(GcodeGenerator.checkBoltCircle(cycle: 'G81', holes: 6, boltCircleDiameter: 100,
          rPlane: 2, zDepth: -5, feed: 100, peck: 0), isEmpty);
    });
  });
}
