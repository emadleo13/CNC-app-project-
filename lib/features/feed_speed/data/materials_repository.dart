import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/material_spec.dart';

class MaterialsRepository {
  List<MaterialSpec>? _cache;

  Future<List<MaterialSpec>> getAll() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/data/materials.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    _cache = (data['materials'] as List)
        .map((m) => MaterialSpec.fromJson(m as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<MaterialSpec?> getByCode(String code) async {
    final all = await getAll();
    try {
      return all.firstWhere((m) => m.code == code);
    } catch (_) {
      return null;
    }
  }

  Future<List<MaterialSpec>> getByCategory(String category) async {
    final all = await getAll();
    return all.where((m) => m.category == category).toList();
  }

  List<String> get categories => [
    'steel', 'stainless', 'aluminum', 'brass', 'cast_iron',
    'titanium', 'superalloy', 'plastic', 'copper',
  ];
}
