import 'dart:convert';
import 'package:flutter/services.dart';

class GcodeEntry {
  final String        code;
  final String        brand;   // primary brand — used for badge colour
  final List<String>  brands;  // all applicable brands — used for filtering
  final String        name;
  final String        description;
  final String?       syntax;
  final String?       warning;

  const GcodeEntry({
    required this.code,
    required this.brand,
    required this.brands,
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

    // g_codes and m_codes — each has a 'dialects' list; brands derived from dialects
    for (final section in ['g_codes', 'm_codes']) {
      for (final item in (json[section] as List)) {
        final dialects = (item['dialects'] as List).cast<String>();
        final primaryBrand = _primaryBrand(dialects);
        // Normalise: 'generic' → 'haas' so the entry is findable under haas filter
        final brands = dialects.map((d) => d == 'generic' ? 'haas' : d).toSet().toList();
        entries.add(GcodeEntry(
          code:        item['code'] as String,
          brand:       primaryBrand,
          brands:      brands,
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
        brands:      const ['sinumerik'],
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
        brands:      const ['fanuc'],
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
        brands:      const ['heidenhain'],
        name:        item['name'] as String,
        description: item['description'] as String,
        syntax:      item['syntax'] as String?,
        warning:     item['warning'] as String?,
      ));
    }

    // mazak_codes
    for (final item in (json['mazak_codes'] as List)) {
      entries.add(GcodeEntry(
        code:        item['code'] as String,
        brand:       'mazak',
        brands:      const ['mazak'],
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
