import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      final now        = DateTime.now();
      final monthStart = DateTime(now.year, now.month).toIso8601String();

      // Fetch usage rows and profile in parallel
      final usageFuture = _supabase
          .from('qa_logs')
          .select('id')
          .eq('user_id', user.id)
          .gte('created_at', monthStart);

      final profileFuture = _supabase
          .from('profiles')
          .select('subscription_tier')
          .eq('id', user.id)
          .maybeSingle();

      final usageRows = await usageFuture;
      final profile   = await profileFuture;

      final tier  = profile?['subscription_tier'] as String? ?? 'free';
      final isPro = tier == 'pro' || tier == 'team';
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
