import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kProMonthlyId = 'cnc_assist_pro_monthly';

/// Play Store page where the user manages or cancels the subscription.
final kManageSubscriptionUrl = Uri.parse(
  'https://play.google.com/store/account/subscriptions'
  '?sku=$kProMonthlyId&package=com.cncassist.cnc_assist',
);

/// Whether a `cnc_entitlements` row grants Pro right now. The server writes it
/// from Google Play with an expiry; a tier without a future expiry is not Pro.
/// This mirrors entitlementActive() in supabase/functions/_shared/entitlement.ts.
///
/// The Supabase project is shared with another app, which owns `profiles`;
/// CNC Assist keeps its subscription state in its own table.
bool entitlementGrantsPro(Map<String, dynamic>? row, {DateTime? now}) {
  final tier = row?['tier'] as String?;
  if (tier == null || tier == 'free') return false;
  final expires = DateTime.tryParse(row?['expires_at'] as String? ?? '');
  return expires != null && expires.isAfter(now ?? DateTime.now());
}

/// Product lookup and the cached tier. Buying and restoring live in
/// PurchaseController, which owns the purchase stream.
class SubscriptionRepository {
  final _supabase = Supabase.instance.client;

  Future<bool> isAvailable() => InAppPurchase.instance.isAvailable();

  Future<ProductDetails?> loadProduct() async {
    final response = await InAppPurchase.instance.queryProductDetails({
      kProMonthlyId,
    });
    if (response.productDetails.isNotEmpty) {
      return response.productDetails.first;
    }
    return null;
  }

  /// 'pro' while the subscription is paid up, otherwise 'free'.
  Future<String> getCurrentTier() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 'free';
      final row = await _supabase
          .from('cnc_entitlements')
          .select('tier, expires_at')
          .eq('user_id', user.id)
          .maybeSingle();
      return entitlementGrantsPro(row) ? row!['tier'] as String : 'free';
    } catch (_) {
      return 'free';
    }
  }
}

final subscriptionRepoProvider = Provider((_) => SubscriptionRepository());

final currentTierProvider = FutureProvider.autoDispose<String>((ref) {
  return ref.read(subscriptionRepoProvider).getCurrentTier();
});
