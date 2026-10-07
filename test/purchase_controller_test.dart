import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cnc_assist/core/net/edge_functions.dart';
import 'package:cnc_assist/features/subscription/data/purchase_controller.dart';
import 'package:cnc_assist/features/subscription/data/subscription_repository.dart';

/// Play Billing stand-in: the test decides what the purchase stream emits.
class FakeStore implements PurchaseStore {
  bool available = true;
  final updates = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <PurchaseDetails>[];
  List<PurchaseDetails> onRestore = const [];
  List<PurchaseDetails>? onBuy;
  String? lastAccountId;

  @override
  Future<bool> isAvailable() async => available;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => updates.stream;
  @override
  Future<bool> buy(ProductDetails product, {String? accountId}) async {
    lastAccountId = accountId;
    final batch = onBuy;
    if (batch != null) scheduleMicrotask(() => updates.add(batch));
    return true;
  }

  @override
  Future<void> restore() async =>
      scheduleMicrotask(() => updates.add(onRestore));
  @override
  Future<void> complete(PurchaseDetails purchase) async =>
      completed.add(purchase);
}

PurchaseDetails purchase(
  PurchaseStatus status, {
  bool pendingComplete = true,
}) => PurchaseDetails(
  purchaseID: 'GPA.1234',
  productID: kProMonthlyId,
  verificationData: PurchaseVerificationData(
    localVerificationData: '{}',
    serverVerificationData: 'token-${status.name}',
    source: 'google_play',
  ),
  transactionDate: '0',
  status: status,
)..pendingCompletePurchase = pendingComplete;

final product = ProductDetails(
  id: kProMonthlyId,
  title: 'Pro',
  description: 'Pro monthly',
  price: '€4.99',
  rawPrice: 4.99,
  currencyCode: 'EUR',
);

void main() {
  late FakeStore store;
  late List<PurchaseDetails> verified;
  late Object? verifyError;
  late ProviderContainer container;

  PurchaseController controller() =>
      container.read(purchaseControllerProvider.notifier);
  PurchaseFlow flow() => container.read(purchaseControllerProvider);
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    store = FakeStore();
    verified = [];
    verifyError = null;
    container = ProviderContainer(
      overrides: [
        purchaseControllerProvider.overrideWith(
          (ref) => PurchaseController(
            ref,
            store: store,
            verify: (p) async {
              verified.add(p);
              final e = verifyError;
              if (e != null) throw e;
            },
          ),
        ),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('start silently re-verifies purchases already on the device', () async {
    store.onRestore = [purchase(PurchaseStatus.restored)];
    await controller().start();
    await settle();
    expect(verified, hasLength(1));
    expect(store.completed, hasLength(1));
    // Nothing the user started, so no message on screen.
    expect(flow(), PurchaseFlow.idle);
  });

  test(
    'billing unavailable at launch: a later purchase still gets its result',
    () async {
      store.available = false;
      await controller().start();
      store.available = true;
      store.onBuy = [purchase(PurchaseStatus.purchased)];
      await controller().buy(product);
      await settle();
      await settle();
      expect(flow(), PurchaseFlow.purchased);
    },
  );

  test(
    'cancelling the Play dialog ends the purchase (no endless spinner)',
    () async {
      await controller().start();
      await settle();
      store.onBuy = [purchase(PurchaseStatus.canceled, pendingComplete: false)];
      await controller().buy(product);
      expect(flow(), PurchaseFlow.busy);
      await settle();
      expect(flow(), PurchaseFlow.canceled);
    },
  );

  test('restore with no purchases reports it instead of spinning', () async {
    await controller().start();
    await settle();
    store.onRestore = const [];
    await controller().restore();
    expect(flow(), PurchaseFlow.nothingToRestore);
  });

  test('a verified purchase is completed and reported', () async {
    await controller().start();
    await settle();
    store.onBuy = [purchase(PurchaseStatus.purchased)];
    await controller().buy(product);
    await settle();
    await settle();
    expect(
      verified.single.verificationData.serverVerificationData,
      'token-purchased',
    );
    expect(store.completed, hasLength(1));
    expect(flow(), PurchaseFlow.purchased);
  });

  test('restore that finds a paid subscription reports restored', () async {
    await controller().start();
    await settle();
    store.onRestore = [purchase(PurchaseStatus.restored)];
    await controller().restore();
    expect(flow(), PurchaseFlow.restored);
  });

  test(
    'server unreachable: purchase kept unacknowledged for the next launch',
    () async {
      await controller().start();
      await settle();
      verifyError = const EdgeFunctionError(EdgeErrorKind.network);
      store.onBuy = [purchase(PurchaseStatus.purchased)];
      await controller().buy(product);
      await settle();
      await settle();
      expect(store.completed, isEmpty);
      expect(flow(), PurchaseFlow.verifyRetry);
    },
  );

  test('server rejects the purchase: error, not acknowledged', () async {
    await controller().start();
    await settle();
    verifyError = const EdgeFunctionError(
      EdgeErrorKind.server,
      status: 402,
      code: 'invalid_purchase',
    );
    store.onBuy = [purchase(PurchaseStatus.purchased)];
    await controller().buy(product);
    await settle();
    await settle();
    expect(store.completed, isEmpty);
    expect(flow(), PurchaseFlow.error);
  });

  test('pending payment shows as pending, then completes', () async {
    await controller().start();
    await settle();
    store.onBuy = [purchase(PurchaseStatus.pending, pendingComplete: false)];
    await controller().buy(product);
    await settle();
    expect(flow(), PurchaseFlow.pending);
    store.updates.add([purchase(PurchaseStatus.purchased)]);
    await settle();
    await settle();
    expect(flow(), PurchaseFlow.purchased);
  });

  group('profileGrantsPro', () {
    final now = DateTime.utc(2026, 10, 7);
    Map<String, dynamic> row(String tier, String? expires) => {
      'subscription_tier': tier,
      'subscription_expires_at': expires,
    };

    test('Pro only with a future expiry', () {
      expect(
        profileGrantsPro(row('pro', '2026-11-07T00:00:00Z'), now: now),
        isTrue,
      );
      expect(
        profileGrantsPro(row('pro', '2026-10-01T00:00:00Z'), now: now),
        isFalse,
      );
      expect(profileGrantsPro(row('pro', null), now: now), isFalse);
      expect(profileGrantsPro(row('team', null), now: now), isFalse);
      expect(
        profileGrantsPro(row('free', '2027-01-01T00:00:00Z'), now: now),
        isFalse,
      );
      expect(profileGrantsPro(null, now: now), isFalse);
    });
  });
}
