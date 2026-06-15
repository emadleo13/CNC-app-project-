import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../history/domain/saved_calculation.dart';
import '../../history/domain/saved_analysis.dart';

/// Handles permanent account + data deletion (Google Play requirement for
/// apps that create user accounts).
///
/// Flow:
///   1. Ask the server (Edge Function) to delete the auth user and all owned
///      rows. The function runs with the service-role key.
///   2. Sign out locally.
///   3. Wipe all on-device data (Hive boxes + secure storage).
///   4. Start a fresh anonymous session so the app keeps working.
class AccountRepository {
  final _supabase = Supabase.instance.client;

  Future<void> deleteAccount() async {
    // 1. Server-side deletion (auth user + profile + owned data).
    final response = await _supabase.functions.invoke('delete-account');
    if (response.status != 200) {
      throw Exception('Server deletion failed (${response.status})');
    }

    // 2. Sign out the deleted user.
    try {
      await _supabase.auth.signOut();
    } catch (_) {}

    // 3. Wipe local data.
    if (Hive.isBoxOpen('calculations')) {
      await Hive.box<SavedCalculation>('calculations').clear();
    }
    if (Hive.isBoxOpen('analyses')) {
      await Hive.box<SavedAnalysis>('analyses').clear();
    }
    try {
      await const FlutterSecureStorage().deleteAll();
    } catch (_) {}

    // 4. Fresh anonymous session so the app is usable again.
    try {
      await _supabase.auth.signInAnonymously();
    } catch (_) {}
  }
}

final accountRepoProvider = Provider((_) => AccountRepository());
