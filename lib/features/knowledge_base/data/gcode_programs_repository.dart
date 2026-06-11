import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/gcode_program.dart';

class GcodeProgramsRepository {
  List<GcodeProgram>? _cache;

  Future<List<GcodeProgram>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw  = await rootBundle.loadString('assets/data/gcode_programs.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    _cache = (json['programs'] as List)
        .map((e) => GcodeProgram.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}
