import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/saved_analysis.dart';
import '../domain/saved_calculation.dart';

/// How long history entries are kept. Calculations and analyses are saved
/// automatically, so without a limit the list would only ever grow; the
/// History screen tells the user about it (historyRetentionNote).
const kHistoryRetention = Duration(days: 30);

class HistoryRepository {
  Box<SavedCalculation> get _calcBox => Hive.box<SavedCalculation>('calculations');
  Box<SavedAnalysis> get _analysisBox => Hive.box<SavedAnalysis>('analyses');

  List<SavedCalculation> getCalculations() =>
      _calcBox.values.toList().reversed.toList();

  List<SavedAnalysis> getAnalyses() =>
      _analysisBox.values.toList().reversed.toList();

  Future<void> addCalculation(SavedCalculation c) => _calcBox.add(c);
  Future<void> addAnalysis(SavedAnalysis a) => _analysisBox.add(a);

  Future<void> deleteCalculationAt(int boxIndex) => _calcBox.deleteAt(boxIndex);
  Future<void> deleteAnalysisAt(int boxIndex) => _analysisBox.deleteAt(boxIndex);

  Future<void> clearCalculations() => _calcBox.clear();
  Future<void> clearAnalyses() => _analysisBox.clear();

  int get calcCount => _calcBox.length;
  int get analysisCount => _analysisBox.length;

  /// Deletes entries saved more than [kHistoryRetention] before [now].
  /// Runs once at start-up, before anything reads the boxes.
  Future<void> purgeExpired({DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).subtract(kHistoryRetention);
    await _calcBox.deleteAll([
      for (final key in _calcBox.keys)
        if (_calcBox.get(key)!.savedAt.isBefore(cutoff)) key,
    ]);
    await _analysisBox.deleteAll([
      for (final key in _analysisBox.keys)
        if (_analysisBox.get(key)!.savedAt.isBefore(cutoff)) key,
    ]);
  }
}

final historyRepoProvider = Provider((_) => HistoryRepository());

// ── Calculations ──────────────────────────────────────────────────────

class CalculationsNotifier extends StateNotifier<List<SavedCalculation>> {
  final HistoryRepository _repo;
  CalculationsNotifier(this._repo) : super(_repo.getCalculations());

  /// Saves [c] unless it repeats the newest entry (Calculate tapped again
  /// with nothing changed).
  Future<void> save(SavedCalculation c) async {
    if (state.isNotEmpty && state.first.sameAs(c)) return;
    await _repo.addCalculation(c);
    state = _repo.getCalculations();
  }

  Future<void> deleteAt(int uiIndex) async {
    final boxIndex = _repo.calcCount - 1 - uiIndex;
    await _repo.deleteCalculationAt(boxIndex);
    state = _repo.getCalculations();
  }

  Future<void> clearAll() async {
    await _repo.clearCalculations();
    state = [];
  }
}

final calculationsProvider =
    StateNotifierProvider<CalculationsNotifier, List<SavedCalculation>>(
        (ref) => CalculationsNotifier(ref.read(historyRepoProvider)));

// ── Analyses ──────────────────────────────────────────────────────────

class AnalysesNotifier extends StateNotifier<List<SavedAnalysis>> {
  final HistoryRepository _repo;
  AnalysesNotifier(this._repo) : super(_repo.getAnalyses());

  /// Saves [a] unless the same program was the last one analysed.
  Future<void> save(SavedAnalysis a) async {
    if (state.isNotEmpty && state.first.sameAs(a)) return;
    await _repo.addAnalysis(a);
    state = _repo.getAnalyses();
  }

  Future<void> deleteAt(int uiIndex) async {
    final boxIndex = _repo.analysisCount - 1 - uiIndex;
    await _repo.deleteAnalysisAt(boxIndex);
    state = _repo.getAnalyses();
  }

  Future<void> clearAll() async {
    await _repo.clearAnalyses();
    state = [];
  }
}

final analysesProvider =
    StateNotifierProvider<AnalysesNotifier, List<SavedAnalysis>>(
        (ref) => AnalysesNotifier(ref.read(historyRepoProvider)));
