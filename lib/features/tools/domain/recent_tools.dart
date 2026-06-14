import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted list of most-recently-opened tool ids (newest first), powering the
/// "quick access" row on the Tools Hub. Stored in secure storage as a CSV,
/// matching the lightweight-prefs pattern used elsewhere in the app.
class RecentToolsNotifier extends StateNotifier<List<String>> {
  RecentToolsNotifier() : super(const []) {
    _load();
  }

  static const _key       = 'recent_tools';
  static const _maxRecent = 4;
  final _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null && raw.isNotEmpty) {
        state = raw.split(',').where((e) => e.isNotEmpty).toList();
      }
    } catch (_) {
      // Ignore — quick access simply stays empty if storage is unavailable.
    }
  }

  /// Records [toolId] as most-recent, de-duplicating and capping the list.
  void record(String toolId) {
    final next = <String>[
      toolId,
      ...state.where((id) => id != toolId),
    ].take(_maxRecent).toList();
    if (listEquals(next, state)) return;
    state = next;
    _storage.write(key: _key, value: next.join(',')).ignore();
  }
}

final recentToolsProvider =
    StateNotifierProvider<RecentToolsNotifier, List<String>>(
  (ref) => RecentToolsNotifier(),
);
