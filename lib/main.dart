import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/l10n/app_strings.dart';
import 'core/storage/local_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      // A network that hangs (workshop Wi-Fi without internet) must not keep
      // the app on its splash screen. Server calls sign in on demand anyway.
      await supabase.auth.signInAnonymously().timeout(
        const Duration(seconds: 8),
      );
    }
  } catch (_) {
    // App continues offline if Supabase is unreachable
  }

  await openLocalStore();

  String? savedLocale;
  String? savedUnits;
  String? savedDialect;
  String? savedName;
  int savedMaxRpm = 0;
  bool onboardingSeen = false;
  try {
    const storage = FlutterSecureStorage();
    savedLocale = await storage.read(key: 'locale');
    savedUnits = await storage.read(key: 'units');
    savedDialect = await storage.read(key: 'dialect');
    savedName = await storage.read(key: 'user_name');
    savedMaxRpm = int.tryParse(await storage.read(key: 'max_rpm') ?? '') ?? 0;
    onboardingSeen = (await storage.read(key: 'onboarding_seen')) == 'true';
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        if (savedLocale != null)
          localeProvider.overrideWith((ref) => savedLocale!),
        if (savedUnits != null)
          defaultUnitsProvider.overrideWith((ref) => savedUnits!),
        if (savedDialect != null)
          defaultDialectProvider.overrideWith((ref) => savedDialect!),
        if (savedName != null)
          userNameProvider.overrideWith((ref) => savedName!),
        if (onboardingSeen) onboardingSeenProvider.overrideWith((ref) => true),
        if (savedMaxRpm > 0) maxRpmProvider.overrideWith((ref) => savedMaxRpm),
      ],
      child: const CncAssistApp(),
    ),
  );
}
