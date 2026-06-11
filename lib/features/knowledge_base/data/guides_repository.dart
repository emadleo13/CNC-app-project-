import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/cnc_guide.dart';

class GuidesRepository {
  List<CncGuide>? _cache;

  Future<List<CncGuide>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw  = await rootBundle.loadString('assets/data/guides.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    _cache = (json['guides'] as List)
        .map((e) => CncGuide.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}
