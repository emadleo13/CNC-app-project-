import 'dart:convert';
import 'package:flutter/services.dart';

class GcodeEntry {
  final String   code;
  final String   brand;
  final String   name;
  final String   description;
  final String?  syntax;
  final String?  warning;

  const GcodeEntry({
    required this.code,
    required this.brand,
    required this.name,
    required this.description,
    this.syntax,
    this.warning,
  });
}

class GcodeRepository {
  List<GcodeEntry>? _cache;

  Future<List<GcodeEntry>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw  = await rootBundle.loadString('assets/data/gcode_reference.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final entries = <GcodeEntry>[];

    // g_codes and m_codes — each has a 'dialects' list; one entry per dialect brand
    for (final section in ['g_codes', 'm_codes']) {
      for (final item in (json[section] as List)) {
        final dialects = (item['dialects'] as List).cast<String>();
        final primaryBrand = _primaryBrand(dialects);
        entries.add(GcodeEntry(
          code:        item['code'] as String,
          brand:       primaryBrand,
          name:        item['name'] as String,
          description: item['description'] as String,
          syntax:      item['syntax'] as String?,
          warning:     item['warning'] as String?,
        ));
      }
    }

    // sinumerik_cycles
    for (final item in (json['sinumerik_cycles'] as List)) {
      entries.add(GcodeEntry(
        code:        item['code'] as String,
        brand:       'sinumerik',
        name:        item['name'] as String,
        description: item['description'] as String,
        syntax:      item['syntax'] as String?,
        warning:     item['warning'] as String?,
      ));
    }

    // fanuc_codes
    for (final item in (json['fanuc_codes'] as List)) {
      entries.add(GcodeEntry(
        code:        item['code'] as String,
        brand:       'fanuc',
        name:        item['name'] as String,
        description: item['description'] as String,
        syntax:      item['syntax'] as String?,
        warning:     item['warning'] as String?,
      ));
    }

    // heidenhain_codes
    for (final item in (json['heidenhain_codes'] as List)) {
      entries.add(GcodeEntry(
        code:        item['code'] as String,
        brand:       'heidenhain',
        name:        item['name'] as String,
        description: item['description'] as String,
        syntax:      item['syntax'] as String?,
        warning:     item['warning'] as String?,
      ));
    }

    _cache = entries;
    return entries;
  }

  static String _primaryBrand(List<String> dialects) {
    if (dialects.contains('haas'))       return 'haas';
    if (dialects.contains('sinumerik'))  return 'sinumerik';
    if (dialects.contains('fanuc'))      return 'fanuc';
    if (dialects.contains('heidenhain')) return 'heidenhain';
    return 'generic';
  }
}
