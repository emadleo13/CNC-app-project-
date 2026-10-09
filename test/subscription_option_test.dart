import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:cnc_assist/features/subscription/data/subscription_repository.dart';

const _monthly = PricingPhaseWrapper(
  billingCycleCount: 0,
  billingPeriod: 'P1M',
  formattedPrice: '28,99 RON',
  priceAmountMicros: 28990000,
  priceCurrencyCode: 'RON',
  recurrenceMode: RecurrenceMode.infiniteRecurring,
);
const _freeWeek = PricingPhaseWrapper(
  billingCycleCount: 1,
  billingPeriod: 'P7D',
  formattedPrice: 'Free',
  priceAmountMicros: 0,
  priceCurrencyCode: 'RON',
  recurrenceMode: RecurrenceMode.finiteRecurring,
);
const _base = SubscriptionOfferDetailsWrapper(
  basePlanId: 'monthly',
  offerTags: [],
  offerIdToken: 'token-base',
  pricingPhases: [_monthly],
);
const _trial = SubscriptionOfferDetailsWrapper(
  basePlanId: 'monthly',
  offerId: 'trial-7d',
  offerTags: [],
  offerIdToken: 'token-trial',
  pricingPhases: [_freeWeek, _monthly],
);

/// What Play returns for cnc_assist_pro_monthly: one entry per offer.
List<ProductDetails> _play(List<SubscriptionOfferDetailsWrapper> offers) =>
    GooglePlayProductDetails.fromProductDetails(
      ProductDetailsWrapper(
        description: 'Pro',
        name: 'CNC Assist Pro',
        productId: kProMonthlyId,
        productType: ProductType.subs,
        subscriptionOfferDetails: offers,
        title: 'CNC Assist Pro',
      ),
    );

String? _token(SubscriptionOption o) =>
    (o.product as GooglePlayProductDetails).offerToken;

void main() {
  for (final order in [
    [_base, _trial],
    [_trial, _base],
  ]) {
    test('a new subscriber gets the trial, priced monthly '
        '(${order.first.offerId ?? 'base'} first)', () {
      final o = pickSubscriptionOption(_play(order))!;
      expect(_token(o), 'token-trial');
      expect(o.freeTrial, isTrue);
      expect(o.price, '28,99 RON', reason: 'never "Free"');
    });
  }

  test('after a trial was used, Play offers only the base plan: no badge', () {
    final o = pickSubscriptionOption(_play([_base]))!;
    expect(_token(o), 'token-base');
    expect(o.freeTrial, isFalse);
    expect(o.price, '28,99 RON');
  });

  test('no product from Play: nothing to sell', () {
    expect(pickSubscriptionOption(const []), isNull);
  });
}
