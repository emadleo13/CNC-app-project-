import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cnc_assist/features/history/domain/saved_analysis.dart';
import 'package:cnc_assist/features/history/domain/saved_calculation.dart';

/// Opens the History boxes in memory. The app opens them before it starts
/// (openLocalStore), and the calculators and the G-code result save to them
/// on their own, so a widget test of those screens needs them open.
Future<void> openHistoryBoxesInMemory() async {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(SavedCalculationAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SavedAnalysisAdapter());
  await Hive.openBox<SavedCalculation>('calculations', bytes: Uint8List(0));
  await Hive.openBox<SavedAnalysis>('analyses', bytes: Uint8List(0));
}
