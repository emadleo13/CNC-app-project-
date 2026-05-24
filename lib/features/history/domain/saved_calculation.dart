import 'package:hive_flutter/hive_flutter.dart';

class SavedCalculation {
  final String materialName;
  final String toolTypeCode;
  final double diameter;
  final int flutes;
  final String units; // 'mm' or 'in'
  final int rpm;
  final double feedRatePerMin;
  final double chipLoad;
  final double mrr;
  final double cuttingSpeed;
  final DateTime savedAt;

  SavedCalculation({
    required this.materialName,
    required this.toolTypeCode,
    required this.diameter,
    required this.flutes,
    required this.units,
    required this.rpm,
    required this.feedRatePerMin,
    required this.chipLoad,
    required this.mrr,
    required this.cuttingSpeed,
    required this.savedAt,
  });
}

class SavedCalculationAdapter extends TypeAdapter<SavedCalculation> {
  @override
  final int typeId = 0;

  @override
  SavedCalculation read(BinaryReader reader) {
    return SavedCalculation(
      materialName:   reader.readString(),
      toolTypeCode:   reader.readString(),
      diameter:       reader.readDouble(),
      flutes:         reader.readInt(),
      units:          reader.readString(),
      rpm:            reader.readInt(),
      feedRatePerMin: reader.readDouble(),
      chipLoad:       reader.readDouble(),
      mrr:            reader.readDouble(),
      cuttingSpeed:   reader.readDouble(),
      savedAt:        DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
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
  }
}
