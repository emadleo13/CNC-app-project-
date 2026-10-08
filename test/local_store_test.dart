import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cnc_assist/core/storage/local_store.dart';
import 'package:cnc_assist/features/history/domain/saved_calculation.dart';

SavedCalculation _calc() => SavedCalculation(
  materialName: '4140 Steel',
  toolTypeCode: 'end_mill_4fl',
  diameter: 10,
  flutes: 4,
  units: 'mm',
  rpm: 2546,
  feedRatePerMin: 509.2,
  chipLoad: 0.05,
  mrr: 5.09,
  cuttingSpeed: 80,
  savedAt: DateTime.utc(2026, 10, 8, 12),
);

/// What a later app version might write: the same layout plus a new field.
class _NextVersionAdapter extends SavedCalculationAdapter {
  @override
  void write(BinaryWriter writer, SavedCalculation obj) {
    super.write(writer, obj);
    writer.writeString('a field added in a later version');
  }
}

/// Stands in for a record this version cannot decode.
class _UnreadableAdapter extends SavedCalculationAdapter {
  @override
  SavedCalculation read(BinaryReader reader) =>
      throw RangeError('record shorter than expected');
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cnc_hive_');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    Hive.resetAdapters();
    await dir.delete(recursive: true);
  });

  Future<void> save(TypeAdapter<SavedCalculation> adapter) async {
    Hive.registerAdapter(adapter);
    final box = await Hive.openBox<SavedCalculation>('calculations');
    await box.add(_calc());
    await box.close();
    Hive.resetAdapters();
  }

  test('a saved calculation reads back unchanged', () async {
    await save(SavedCalculationAdapter());
    Hive.registerAdapter(SavedCalculationAdapter());
    final box = await openBoxSafely<SavedCalculation>('calculations', dir.path);
    final c = box.getAt(0)!;
    expect(c.materialName, '4140 Steel');
    expect(c.rpm, 2546);
    expect(c.feedRatePerMin, 509.2);
    expect(c.savedAt.toUtc(), DateTime.utc(2026, 10, 8, 12));
  });

  test(
    'a record with fields appended by a later version still loads',
    () async {
      await save(_NextVersionAdapter());
      Hive.registerAdapter(SavedCalculationAdapter());
      final box = await openBoxSafely<SavedCalculation>(
        'calculations',
        dir.path,
      );
      expect(box.getAt(0)!.rpm, 2546);
    },
  );

  test(
    'an unreadable box starts empty instead of crashing, and is kept aside',
    () async {
      await save(SavedCalculationAdapter());
      Hive.registerAdapter(_UnreadableAdapter());
      final box = await openBoxSafely<SavedCalculation>(
        'calculations',
        dir.path,
      );
      expect(box.isEmpty, isTrue);
      expect(File('${dir.path}/calculations.hive.broken').existsSync(), isTrue);
      // The fresh box works.
      await box.add(_calc());
      expect(box.length, 1);
    },
  );
}
