import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../subscription/data/subscription_repository.dart';

class UsageStatus {
  final int  used;
  final int  limit;
  final bool isPro;
  const UsageStatus({required this.used, required this.limit, required this.isPro});

  static const int freeLimit = 10;

  int    get remaining      => isPro ? 999 : (limit - used).clamp(0, limit);
  bool   get isLimitReached => !isPro && used >= limit;
  double get fraction       => isPro ? 0.0 : (used / limit).clamp(0.0, 1.0);
}

class UsageRepository {
  final _supabase = Supabase.instance.client;

  Future<UsageStatus> getMonthlyUsage() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const UsageStatus(used: 0, limit: UsageStatus.freeLimit, isPro: false);
      }

      // Same month boundary as the server's quota count (UTC).
      final now        = DateTime.now().toUtc();
      final monthStart = DateTime.utc(now.year, now.month).toIso8601String();

      // Fetch usage rows and the Pro entitlement in parallel
      final usageFuture = _supabase
          .from('qa_logs')
          .select('id')
          .eq('user_id', user.id)
          .gte('created_at', monthStart);

      final entitlementFuture = _supabase
          .from('cnc_entitlements')
          .select('tier, expires_at')
          .eq('user_id', user.id)
          .maybeSingle();

      final usageRows   = await usageFuture;
      final entitlement = await entitlementFuture;

      final isPro = entitlementGrantsPro(entitlement);
      final used  = (usageRows as List).length;

      return UsageStatus(used: used, limit: UsageStatus.freeLimit, isPro: isPro);
    } catch (_) {
      return const UsageStatus(used: 0, limit: UsageStatus.freeLimit, isPro: false);
    }
  }
}

final usageRepositoryProvider = Provider((_) => UsageRepository());

final usageProvider = FutureProvider.autoDispose<UsageStatus>((ref) {
  return ref.read(usageRepositoryProvider).getMonthlyUsage();
});
