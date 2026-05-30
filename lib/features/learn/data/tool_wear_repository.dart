import 'dart:convert';
import 'package:flutter/services.dart';

class ToolWearType {
  final String name;
  final String icon;
  final String severity; // normal | warning | critical
  final String description;
  final List<String> causes;
  final List<String> solutions;

  const ToolWearType({
    required this.name,
    required this.icon,
    required this.severity,
    required this.description,
    required this.causes,
    required this.solutions,
  });

  factory ToolWearType.fromJson(Map<String, dynamic> j) => ToolWearType(
        name: j['name'] as String,
        icon: j['icon'] as String,
        severity: j['severity'] as String,
        description: j['description'] as String,
        causes: (j['causes'] as List).cast<String>(),
        solutions: (j['solutions'] as List).cast<String>(),
      );
}

class ToolWearRepository {
  List<ToolWearType>? _cache;

  Future<List<ToolWearType>> getAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/tool_wear.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (data['wear_types'] as List)
        .map((w) => ToolWearType.fromJson(w as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}
