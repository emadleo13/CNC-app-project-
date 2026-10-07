import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/net/edge_functions.dart';
import '../../knowledge_base/data/usage_repository.dart';
import 'subscription_repository.dart';

/// Where the purchase or restore the user started stands. Purchases found
/// silently at app start never change this.
enum PurchaseFlow {
  idle,
  busy,
  pending,
  purchased,
  restored,
  canceled,
  nothingToRestore,

  /// Paid, but the server could not confirm it with Google yet. It is
  /// re-checked on the next app start.
  verifyRetry,
  error,
}

/// The parts of the store this controller uses, so tests can swap it.
abstract class PurchaseStore {
  Future<bool> isAvailable();
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> buy(ProductDetails product, {String? accountId});
  Future<void> restore();
  Future<void> complete(PurchaseDetails purchase);
}

class _PlayStore implements PurchaseStore {
  InAppPurchase get _iap => InAppPurchase.instance;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;
  @override
  Future<bool> buy(ProductDetails product, {String? accountId}) =>
      _iap.buyNonConsumable(
        // The account id travels with the purchase to Google, so Play
        // notifications can name the user even if the app dies before it
        // verifies the purchase.
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: accountId,
        ),
      );
  @override
  Future<void> restore() => _iap.restorePurchases();
  @override
  Future<void> complete(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}

/// Sends a purchase to the server, which checks it with Google and grants Pro.
/// Throws [EdgeFunctionError] when it is not granted.
typedef PurchaseVerifier = Future<void> Function(PurchaseDetails purchase);

Future<void> _verifyWithServer(PurchaseDetails p) => invokeEdgeFunction(
  'verify-purchase',
  body: {
    'purchaseToken': p.verificationData.serverVerificationData,
    'productId': p.productID,
    'platform': 'android',
  },
  timeout: const Duration(seconds: 30),
);

enum _Outcome { granted, rejected, retry }

/// Owns the Play Billing purchase stream for the whole app lifetime.
///
/// Listening only while the subscription screen was open meant a purchase that
/// completed later (pending payment methods, app killed mid-flow) was never
/// verified or acknowledged, and Google refunds unacknowledged purchases
/// after three days. [start] is called once at app launch. It listens from then
/// on and silently re-verifies purchases already on the device, which also
/// picks up monthly renewals and restores Pro after a reinstall.
class PurchaseController extends StateNotifier<PurchaseFlow> {
  PurchaseController(
    this._ref, {
    PurchaseStore? store,
    PurchaseVerifier? verify,
  }) : _store = store ?? _PlayStore(),
       _verify = verify ?? _verifyWithServer,
       super(PurchaseFlow.idle);

  final Ref _ref;
  final PurchaseStore _store;
  final PurchaseVerifier _verify;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  Future<void>? _starting;

  /// True while a purchase or restore the user started is in progress: only
  /// then do updates change [state].
  bool _interactive = false;

  /// Completes when the batch answering the user's restore has been handled.
  Completer<void>? _restoreBatch;

  /// Subscribes to the purchase stream and syncs existing purchases. Safe to
  /// call repeatedly. If billing was unavailable, the next call tries again,
  /// so a Buy after a bad start still gets its result.
  Future<void> start() {
    if (_sub != null) return Future.value();
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<void> _start() async {
    try {
      if (!await _store.isAvailable()) return;
      _sub ??= _store.purchaseStream.listen(
        _onUpdates,
        onError: (Object _) {
          if (_interactive) _finish(PurchaseFlow.error);
        },
      );
      await _store.restore();
    } catch (_) {
      // No Play Store (emulator, sideload) or billing unavailable: nothing to sync.
    }
  }

  Future<void> buy(ProductDetails product) async {
    await start();
    _interactive = true;
    state = PurchaseFlow.busy;
    try {
      final sent = await _store.buy(product, accountId: _currentUserId());
      if (!sent) _finish(PurchaseFlow.error);
    } catch (_) {
      _finish(PurchaseFlow.error);
    }
  }

  Future<void> restore() async {
    await start();
    _interactive = true;
    state = PurchaseFlow.busy;
    final batch = Completer<void>();
    _restoreBatch = batch;
    try {
      await _store.restore();
      // Android answers a restore with one batch, possibly empty.
      await batch.future.timeout(const Duration(seconds: 30));
    } on TimeoutException {
      if (state == PurchaseFlow.busy) _finish(PurchaseFlow.nothingToRestore);
    } catch (_) {
      _finish(PurchaseFlow.error);
    } finally {
      if (identical(_restoreBatch, batch)) _restoreBatch = null;
    }
  }

  Future<void> _onUpdates(List<PurchaseDetails> updates) async {
    final restoreBatch = _restoreBatch;
    var granted = false;
    var retry = false;
    var rejected = false;

    for (final p in updates) {
      switch (p.status) {
        case PurchaseStatus.pending:
          if (_interactive) state = PurchaseFlow.pending;
        case PurchaseStatus.canceled:
          if (_interactive && restoreBatch == null) {
            _finish(PurchaseFlow.canceled);
          }
        case PurchaseStatus.error:
          if (_interactive && restoreBatch == null) _finish(PurchaseFlow.error);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          switch (await _verifyAndComplete(p)) {
            case _Outcome.granted:
              granted = true;
            case _Outcome.retry:
              retry = true;
            case _Outcome.rejected:
              rejected = true;
          }
      }
      // Finished non-purchases (errors, cancellations) must still be
      // completed where the platform asks for it; verified purchases already
      // were, and unverified ones are kept for the next attempt.
      if (p.pendingCompletePurchase &&
          (p.status == PurchaseStatus.error ||
              p.status == PurchaseStatus.canceled)) {
        try {
          await _store.complete(p);
        } catch (_) {}
      }
    }

    if (granted) {
      _ref.invalidate(currentTierProvider);
      _ref.invalidate(usageProvider);
    }
    if (_interactive) {
      if (granted) {
        _finish(
          restoreBatch != null ? PurchaseFlow.restored : PurchaseFlow.purchased,
        );
      } else if (retry) {
        _finish(PurchaseFlow.verifyRetry);
      } else if (restoreBatch != null) {
        // Includes a restore that only found expired purchases.
        _finish(PurchaseFlow.nothingToRestore);
      } else if (rejected) {
        _finish(PurchaseFlow.error);
      }
    }
    if (restoreBatch != null && !restoreBatch.isCompleted) {
      restoreBatch.complete();
    }
  }

  Future<_Outcome> _verifyAndComplete(PurchaseDetails p) async {
    try {
      await _verify(p);
    } on EdgeFunctionError catch (e) {
      // 402: Google says this purchase does not grant Pro (expired, wrong
      // product). Anything else is transient: keep it for the next launch.
      return e.status == 402 ? _Outcome.rejected : _Outcome.retry;
    } catch (_) {
      return _Outcome.retry;
    }
    if (p.pendingCompletePurchase) {
      // The server acknowledges too; this is the client-side half.
      try {
        await _store.complete(p);
      } catch (_) {}
    }
    return _Outcome.granted;
  }

  String? _currentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null; // Supabase not initialised (offline start): buy without it.
    }
  }

  void _finish(PurchaseFlow outcome) {
    _interactive = false;
    state = outcome;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// App-wide; never auto-disposed, so the purchase stream stays subscribed.
final purchaseControllerProvider =
    StateNotifierProvider<PurchaseController, PurchaseFlow>(
      (ref) => PurchaseController(ref),
    );
