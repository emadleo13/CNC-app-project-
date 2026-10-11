import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cnc_assist/features/history/data/history_repository.dart';
import 'package:cnc_assist/features/history/domain/saved_analysis.dart';
import 'package:cnc_assist/features/history/domain/saved_calculation.dart';

SavedCalculation _milling(DateTime at, {int rpm = 2546}) => SavedCalculation(
  materialName: '4140 Steel',
  toolTypeCode: 'end_mill_4fl',
  diameter: 10,
  flutes: 4,
  units: 'mm',
  rpm: rpm,
  feedRatePerMin: 509.2,
  chipLoad: 0.05,
  mrr: 5.09,
  cuttingSpeed: 80,
  savedAt: at,
);

SavedAnalysis _analysis(DateTime at) => SavedAnalysis(
  label: 'O1000',
  dialectName: 'Haas',
  lineCount: 12,
  errorCount: 0,
  warningCount: 1,
  savedAt: at,
);

/// The layout app versions up to 1.3.2 wrote: milling only, eleven fields.
class _V132Adapter extends SavedCalculationAdapter {
  @override
  void write(BinaryWriter writer, SavedCalculation obj) {
    writer.writeString(obj.materialName);
    writer.writeString(obj.toolTypeCode);
    writer.writeDouble(obj.diameter);
    writer.writeInt(obj.flutes);
    writer.writeString(obj.units);
    writer.writeInt(obj.rpm);
    writer.writeDouble(obj.feedRatePerMin);
    writer.writeDouble(obj.chipLoad);
    writer.writeDouble(obj.mrr);
    writer.writeDouble(obj.cuttingSpeed);
    writer.writeInt(obj.savedAt.millisecondsSinceEpoch);
  }
}

void main() {
  late Directory dir;
  final now = DateTime(2026, 10, 11, 12);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cnc_history_');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    Hive.resetAdapters();
    await dir.delete(recursive: true);
  });

  Future<void> openBoxes() async {
    Hive.registerAdapter(SavedCalculationAdapter());
    Hive.registerAdapter(SavedAnalysisAdapter());
    await Hive.openBox<SavedCalculation>('calculations');
    await Hive.openBox<SavedAnalysis>('analyses');
  }

  test('a milling record saved by 1.3.2 loads as milling', () async {
    Hive.registerAdapter(_V132Adapter());
    var box = await Hive.openBox<SavedCalculation>('calculations');
    await box.add(_milling(now));
    await box.close();
    Hive.resetAdapters();

    Hive.registerAdapter(SavedCalculationAdapter());
    box = await Hive.openBox<SavedCalculation>('calculations');
    final c = box.getAt(0)!;
    expect(c.kind, CalcKind.milling);
    expect(c.rpm, 2546);
    expect(c.feedPerRev, 0);
  });

  test('a turning calculation reads back with its inputs', () async {
    await openBoxes();
    final box = Hive.box<SavedCalculation>('calculations');
    await box.add(SavedCalculation(
      kind: CalcKind.turning,
      diameter: 50,
      units: 'mm',
      rpm: 1273,
      feedRatePerMin: 254.6,
      mrr: 80,
      cuttingSpeed: 200,
      feedPerRev: 0.2,
      depth: 2,
      length: 100,
      passes: 3,
      cutTimeMin: 1.18,
      savedAt: now,
    ));
    await box.close();
    final c = (await Hive.openBox<SavedCalculation>('calculations')).getAt(0)!;
    expect(c.kind, CalcKind.turning);
    expect(c.feedPerRev, 0.2);
    expect(c.depth, 2);
    expect(c.length, 100);
    expect(c.passes, 3);
    expect(c.cutTimeMin, 1.18);
  });

  test('entries older than 30 days are deleted, newer ones kept', () async {
    await openBoxes();
    final calcs = Hive.box<SavedCalculation>('calculations');
    final analyses = Hive.box<SavedAnalysis>('analyses');
    await calcs.addAll([
      _milling(now.subtract(const Duration(days: 31))),
      _milling(now.subtract(const Duration(days: 29))),
    ]);
    await analyses.addAll([
      _analysis(now.subtract(const Duration(days: 45))),
      _analysis(now.subtract(const Duration(hours: 1))),
    ]);

    await HistoryRepository().purgeExpired(now: now);

    expect(calcs.values.map((c) => c.savedAt), [now.subtract(const Duration(days: 29))]);
    expect(analyses.values.map((a) => a.savedAt), [now.subtract(const Duration(hours: 1))]);
  });

  test('tapping Calculate again with nothing changed saves one entry', () async {
    await openBoxes();
    final calcs = CalculationsNotifier(HistoryRepository());
    await calcs.save(_milling(now));
    await calcs.save(_milling(now.add(const Duration(seconds: 5))));
    expect(calcs.state, hasLength(1));

    await calcs.save(_milling(now, rpm: 3000));
    expect(calcs.state, hasLength(2));
    expect(calcs.state.first.rpm, 3000, reason: 'newest first');

    final analyses = AnalysesNotifier(HistoryRepository());
    await analyses.save(_analysis(now));
    await analyses.save(_analysis(now.add(const Duration(minutes: 1))));
    expect(analyses.state, hasLength(1));
  });
}
