import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/l10n/app_strings.dart';
import 'features/history/domain/saved_calculation.dart';
import 'features/history/domain/saved_analysis.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url:     SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      await supabase.auth.signInAnonymously();
    }
  } catch (_) {
    // App continues offline if Supabase is unreachable
  }

  await Hive.initFlutter();
  Hive.registerAdapter(SavedCalculationAdapter());
  Hive.registerAdapter(SavedAnalysisAdapter());
  await Hive.openBox<SavedCalculation>('calculations');
  await Hive.openBox<SavedAnalysis>('analyses');

  String? savedLocale;
  String? savedUnits;
  String? savedDialect;
  try {
    const storage = FlutterSecureStorage();
    savedLocale   = await storage.read(key: 'locale');
    savedUnits    = await storage.read(key: 'units');
    savedDialect  = await storage.read(key: 'dialect');
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        if (savedLocale   != null) localeProvider.overrideWith((ref)          => savedLocale!),
        if (savedUnits    != null) defaultUnitsProvider.overrideWith((ref)    => savedUnits!),
        if (savedDialect  != null) defaultDialectProvider.overrideWith((ref)  => savedDialect!),
      ],
      child: const CncAssistApp(),
    ),
  );
}
