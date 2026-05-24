import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/saved_analysis.dart';
import '../domain/saved_calculation.dart';

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
}

final historyRepoProvider = Provider((_) => HistoryRepository());

// ── Calculations ──────────────────────────────────────────────────────

class CalculationsNotifier extends StateNotifier<List<SavedCalculation>> {
  final HistoryRepository _repo;
  CalculationsNotifier(this._repo) : super(_repo.getCalculations());

  Future<void> save(SavedCalculation c) async {
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

  Future<void> save(SavedAnalysis a) async {
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
