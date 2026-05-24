import 'package:hive_flutter/hive_flutter.dart';

class SavedAnalysis {
  final String label;
  final String dialectName;
  final int lineCount;
  final int errorCount;
  final int warningCount;
  final DateTime savedAt;

  SavedAnalysis({
    required this.label,
    required this.dialectName,
    required this.lineCount,
    required this.errorCount,
    required this.warningCount,
    required this.savedAt,
  });
}

class SavedAnalysisAdapter extends TypeAdapter<SavedAnalysis> {
  @override
  final int typeId = 1;

  @override
  SavedAnalysis read(BinaryReader reader) {
    return SavedAnalysis(
      label:        reader.readString(),
      dialectName:  reader.readString(),
      lineCount:    reader.readInt(),
      errorCount:   reader.readInt(),
      warningCount: reader.readInt(),
      savedAt:      DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, SavedAnalysis obj) {
    writer.writeString(obj.label);
    writer.writeString(obj.dialectName);
    writer.writeInt(obj.lineCount);
    writer.writeInt(obj.errorCount);
    writer.writeInt(obj.warningCount);
    writer.writeInt(obj.savedAt.millisecondsSinceEpoch);
  }
}
