import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/error_alarm.dart';

class ErrorsRepository {
  static List<ErrorAlarm>? _cache;

  Future<List<ErrorAlarm>> loadAll() async {
    if (_cache != null) return _cache!;

    final raw  = await rootBundle.loadString('assets/data/errors.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final haas = (json['haas_alarms'] as List)
        .map((e) => ErrorAlarm.fromJson(e as Map<String, dynamic>, 'haas'))
        .toList();
    final sinumerik = (json['sinumerik_alarms'] as List)
        .map((e) => ErrorAlarm.fromJson(e as Map<String, dynamic>, 'sinumerik'))
        .toList();
    final fanuc = (json['fanuc_alarms'] as List)
        .map((e) => ErrorAlarm.fromJson(e as Map<String, dynamic>, 'fanuc'))
        .toList();
    final heidenhain = (json['heidenhain_alarms'] as List)
        .map((e) => ErrorAlarm.fromJson(e as Map<String, dynamic>, 'heidenhain'))
        .toList();

    _cache = [...haas, ...sinumerik, ...fanuc, ...heidenhain];
    return _cache!;
  }

  Future<List<ErrorAlarm>> search(String query, {String machine = 'all'}) async {
    final all   = await loadAll();
    final q     = query.toLowerCase().trim();
    final list  = machine == 'all' ? all : all.where((a) => a.machine == machine).toList();

    if (q.isEmpty) return list;

    return list.where((a) =>
      a.code.toLowerCase().contains(q) ||
      a.title.toLowerCase().contains(q) ||
      a.description.toLowerCase().contains(q) ||
      a.possibleCauses.any((c) => c.toLowerCase().contains(q)) ||
      a.solutions.any((s) => s.toLowerCase().contains(q))
    ).toList();
  }

  Future<ErrorAlarm?> findByCode(String code) async {
    final all = await loadAll();
    final normalized = code.trim().toUpperCase();
    try {
      return all.firstWhere(
        (a) => a.code.toUpperCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }
}
