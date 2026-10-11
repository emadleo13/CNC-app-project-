import 'package:hive_flutter/hive_flutter.dart';

/// Which calculator produced a [SavedCalculation].
enum CalcKind { milling, turning, drilling }

class SavedCalculation {
  final CalcKind kind;

  /// Milling only; empty for turning and drilling.
  final String materialName;
  final String toolTypeCode;
  final int flutes;

  /// Tool diameter (milling, drilling) or work diameter (turning).
  final double diameter;
  final String units; // 'mm' or 'in'
  final int rpm;
  final double feedRatePerMin;
  final double chipLoad;
  final double mrr;
  final double cuttingSpeed;
  final DateTime savedAt;

  /// Turning and drilling: feed per revolution.
  final double feedPerRev;

  /// Turning: depth of cut per pass (ap). Drilling: hole depth.
  final double depth;

  /// Turning: cut length per pass.
  final double length;

  /// Turning: number of passes.
  final int passes;

  /// Drilling: point angle in degrees.
  final double pointAngle;

  /// Turning and drilling: cutting time in minutes.
  final double cutTimeMin;

  SavedCalculation({
    this.kind = CalcKind.milling,
    this.materialName = '',
    this.toolTypeCode = '',
    this.flutes = 0,
    required this.diameter,
    required this.units,
    required this.rpm,
    required this.feedRatePerMin,
    this.chipLoad = 0,
    this.mrr = 0,
    required this.cuttingSpeed,
    required this.savedAt,
    this.feedPerRev = 0,
    this.depth = 0,
    this.length = 0,
    this.passes = 0,
    this.pointAngle = 0,
    this.cutTimeMin = 0,
  });

  /// Same inputs and results, whenever it was saved: tapping Calculate again
  /// without changing anything.
  bool sameAs(SavedCalculation o) =>
      kind == o.kind &&
      materialName == o.materialName &&
      toolTypeCode == o.toolTypeCode &&
      flutes == o.flutes &&
      diameter == o.diameter &&
      units == o.units &&
      rpm == o.rpm &&
      feedRatePerMin == o.feedRatePerMin &&
      chipLoad == o.chipLoad &&
      mrr == o.mrr &&
      cuttingSpeed == o.cuttingSpeed &&
      feedPerRev == o.feedPerRev &&
      depth == o.depth &&
      length == o.length &&
      passes == o.passes &&
      pointAngle == o.pointAngle &&
      cutTimeMin == o.cutTimeMin;
}

/// Binary layout, oldest field first. Never reorder or remove fields: add new
/// ones at the end and read them only `if (reader.availableBytes > 0)`, so
/// records saved by earlier app versions still load (see local_store.dart).
///
/// Up to 1.3.2 only milling was saved, with the first eleven fields; such
/// records read back as [CalcKind.milling].
class SavedCalculationAdapter extends TypeAdapter<SavedCalculation> {
  @override
  final int typeId = 0;

  @override
  SavedCalculation read(BinaryReader reader) {
    final materialName = reader.readString();
    final toolTypeCode = reader.readString();
    final diameter = reader.readDouble();
    final flutes = reader.readInt();
    final units = reader.readString();
    final rpm = reader.readInt();
    final feedRatePerMin = reader.readDouble();
    final chipLoad = reader.readDouble();
    final mrr = reader.readDouble();
    final cuttingSpeed = reader.readDouble();
    final savedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    // Added in 1.3.3: the calculator, and the turning and drilling inputs.
    var kind = CalcKind.milling;
    double feedPerRev = 0, depth = 0, length = 0, pointAngle = 0, cutTimeMin = 0;
    var passes = 0;
    if (reader.availableBytes > 0) {
      kind = CalcKind.values.asNameMap()[reader.readString()] ?? CalcKind.milling;
      feedPerRev = reader.readDouble();
      depth = reader.readDouble();
      length = reader.readDouble();
      passes = reader.readInt();
      pointAngle = reader.readDouble();
      cutTimeMin = reader.readDouble();
    }
    return SavedCalculation(
      kind:           kind,
      materialName:   materialName,
      toolTypeCode:   toolTypeCode,
      diameter:       diameter,
      flutes:         flutes,
      units:          units,
      rpm:            rpm,
      feedRatePerMin: feedRatePerMin,
      chipLoad:       chipLoad,
      mrr:            mrr,
      cuttingSpeed:   cuttingSpeed,
      savedAt:        savedAt,
      feedPerRev:     feedPerRev,
      depth:          depth,
      length:         length,
      passes:         passes,
      pointAngle:     pointAngle,
      cutTimeMin:     cutTimeMin,
    );
  }

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
    // 1.3.3
    writer.writeString(obj.kind.name);
    writer.writeDouble(obj.feedPerRev);
    writer.writeDouble(obj.depth);
    writer.writeDouble(obj.length);
    writer.writeInt(obj.passes);
    writer.writeDouble(obj.pointAngle);
    writer.writeDouble(obj.cutTimeMin);
  }
}
