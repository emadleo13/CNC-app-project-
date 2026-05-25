import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kProMonthlyId = 'cnc_assist_pro_monthly';

class SubscriptionRepository {
  final _iap      = InAppPurchase.instance;
  final _supabase = Supabase.instance.client;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetails?> loadProduct() async {
    final response = await _iap.queryProductDetails({kProMonthlyId});
    if (response.productDetails.isNotEmpty) {
      return response.productDetails.first;
    }
    return null;
  }

  Future<void> buySubscription(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Stream<List<PurchaseDetails>> get purchaseStream =>
      _iap.purchaseStream;

  Future<bool> verifyAndActivate(PurchaseDetails details) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase.functions.invoke('verify-purchase', body: {
        'purchaseToken': details.verificationData.serverVerificationData,
        'productId':     details.productID,
        'platform':      'android',
      });

      if (response.status == 200) {
        await _iap.completePurchase(details);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String> getCurrentTier() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 'free';
      final profile = await _supabase
          .from('profiles')
          .select('subscription_tier')
          .eq('id', user.id)
          .maybeSingle();
      return profile?['subscription_tier'] as String? ?? 'free';
    } catch (_) {
      return 'free';
    }
  }

  void dispose() => _purchaseSub?.cancel();
}

final subscriptionRepoProvider = Provider((_) => SubscriptionRepository());

final currentTierProvider = FutureProvider.autoDispose<String>((ref) {
  return ref.read(subscriptionRepoProvider).getCurrentTier();
});
