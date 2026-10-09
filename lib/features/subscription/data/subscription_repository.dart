import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
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

/// What the Pro screen sells: the Play offer to buy, its monthly price, and
/// whether that offer starts with a free trial.
class SubscriptionOption {
  final ProductDetails product;

  /// The recurring price ("28,99 RON"), never a trial's "Free".
  final String price;
  final bool freeTrial;
  const SubscriptionOption({
    required this.product,
    required this.price,
    required this.freeTrial,
  });
}

/// Picks what to sell from the product details Play returned.
///
/// Play returns one entry per offer of the subscription (the base plan, and
/// the 7-day trial while the user is still eligible for it), in no promised
/// order, and an entry's `price` is that of its first phase: "Free" for the
/// trial. Taking the first entry could charge from day one under a "7-Day
/// Free Trial" badge, or show "Free" as the monthly price. The trial is
/// bought when Play offers it; the price shown is always the recurring one.
SubscriptionOption? pickSubscriptionOption(List<ProductDetails> details) {
  if (details.isEmpty) return null;
  final offers = <(ProductDetails, SubscriptionOfferDetailsWrapper)>[
    for (final d in details)
      if (d is GooglePlayProductDetails && d.subscriptionIndex != null)
        (d, d.productDetails.subscriptionOfferDetails![d.subscriptionIndex!]),
  ];
  if (offers.isEmpty) {
    final d = details.first;
    return SubscriptionOption(product: d, price: d.price, freeTrial: false);
  }
  bool startsFree(SubscriptionOfferDetailsWrapper o) =>
      o.pricingPhases.isNotEmpty && o.pricingPhases.first.priceAmountMicros == 0;
  final trial = offers.where((o) => startsFree(o.$2)).firstOrNull;
  final base = offers.where((o) => o.$2.offerId == null).firstOrNull ?? offers.first;
  final chosen = trial ?? base;
  final recurring = chosen.$2.pricingPhases.lastWhere(
    (p) => p.priceAmountMicros > 0,
    orElse: () => base.$2.pricingPhases.last,
  );
  return SubscriptionOption(
    product: chosen.$1,
    price: recurring.formattedPrice,
    freeTrial: trial != null,
  );
}

/// Product lookup and the cached tier. Buying and restoring live in
/// PurchaseController, which owns the purchase stream.
class SubscriptionRepository {
  final _supabase = Supabase.instance.client;

  Future<bool> isAvailable() => InAppPurchase.instance.isAvailable();

  Future<SubscriptionOption?> loadProduct() async {
    final response = await InAppPurchase.instance.queryProductDetails({
      kProMonthlyId,
    });
    return pickSubscriptionOption(response.productDetails);
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
