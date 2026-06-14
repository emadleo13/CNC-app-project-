import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../data/subscription_repository.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  ProductDetails? _product;
  bool            _loading    = true;
  bool            _purchasing = false;
  String?         _errorMsg;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _listenPurchases();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    final s = ref.read(appStringsProvider);
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final repo = ref.read(subscriptionRepoProvider);
      final available = await repo.isAvailable();
      if (!available) {
        if (mounted) setState(() => _errorMsg = s.subNotAvailable);
        return;
      }
      final product = await repo.loadProduct();
      if (mounted) {
        setState(() {
          _product = product;
          // Store is reachable but the product isn't configured/returned.
          if (product == null) _errorMsg = s.subProductUnavailable;
        });
      }
    } catch (_) {
      // Billing client not ready, no Play Store, unsupported device, etc.
      if (mounted) setState(() => _errorMsg = s.subNotAvailable);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _listenPurchases() {
    final repo = ref.read(subscriptionRepoProvider);
    _purchaseSub = repo.purchaseStream.listen((purchases) async {
      for (final details in purchases) {
        if (details.status == PurchaseStatus.purchased ||
            details.status == PurchaseStatus.restored) {
          setState(() => _purchasing = true);
          final ok = await repo.verifyAndActivate(details);
          if (mounted) {
            setState(() => _purchasing = false);
            if (ok) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ref.read(appStringsProvider).subSuccess),
                backgroundColor: AppColors.successGreen,
              ));
              Navigator.pop(context, true);
            } else {
              setState(() => _errorMsg = ref.read(appStringsProvider).subError);
            }
          }
        } else if (details.status == PurchaseStatus.error) {
          setState(() { _purchasing = false; _errorMsg = ref.read(appStringsProvider).subError; });
        }
      }
    });
  }

  Future<void> _subscribe() async {
    if (_product == null) return;
    setState(() { _purchasing = true; _errorMsg = null; });
    try {
      await ref.read(subscriptionRepoProvider).buySubscription(_product!);
    } catch (_) {
      if (mounted) setState(() { _purchasing = false; _errorMsg = ref.read(appStringsProvider).subError; });
    }
  }

  Future<void> _restore() async {
    setState(() { _purchasing = true; _errorMsg = null; });
    try {
      await ref.read(subscriptionRepoProvider).restorePurchases();
    } catch (_) {
      if (mounted) setState(() { _purchasing = false; _errorMsg = ref.read(appStringsProvider).subError; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s    = ref.watch(appStringsProvider);
    final tier = ref.watch(currentTierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.subTitle)),
      body: tier.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, st) => _buildContent(s, 'free'),
        data:    (t) => _buildContent(s, t),
      ),
    );
  }

  Widget _buildContent(AppStrings s, String tier) {
    final isPro = tier == 'pro' || tier == 'team';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primaryDim],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Column(children: [
              const Icon(Icons.workspace_premium, color: AppColors.primary, size: 48),
              const SizedBox(height: 12),
              Text(s.subTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(s.subSubtitle,
                style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              if (!isPro)
                Text(
                  _loading ? '...' : (_product?.price ?? s.subMonthly),
                  style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary,
                  ),
                ),
              if (isPro)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color:        AppColors.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s.subCurrentPlan,
                    style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
          const SizedBox(height: 24),

          // Feature list
          _FeatureRow(icon: Icons.all_inclusive,        label: s.subFeatureUnlimited),
          _FeatureRow(icon: Icons.description_outlined, label: s.subFeatureSetup),
          _FeatureRow(icon: Icons.build_circle_outlined, label: s.subFeatureTooling),
          _FeatureRow(icon: Icons.picture_as_pdf_outlined, label: s.subFeaturePdf),

          const SizedBox(height: 28),

          if (_errorMsg != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_errorMsg!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.errorRed, fontSize: 13)),
            ),

          if (!isPro) ...[
            // Free trial badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_giftcard, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(s.subFreeTrial,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),

            ElevatedButton(
              // Disabled when no purchasable product is loaded, so the button is
              // never a silent no-op.
              onPressed: (_purchasing || _loading || _product == null) ? null : _subscribe,
              style: ElevatedButton.styleFrom(
                padding:  const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primary,
              ),
              child: _purchasing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(s.subSubscribeBtn,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            // When the live product couldn't load, offer a retry instead of a
            // dead Subscribe button.
            if (!_loading && _product == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: _loadProduct,
                  icon:  const Icon(Icons.refresh, size: 16),
                  label: Text(s.commonRetry),
                ),
              ),

            // Cancel anytime text
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(s.subCancelAnytime,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),

            const SizedBox(height: 12),
            TextButton(
              onPressed: (_purchasing || _loading) ? null : _restore,
              child: Text(s.subRestoreBtn,
                style: const TextStyle(color: AppColors.textSecondary)),
            ),

            // Satisfaction guarantee
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_user, color: AppColors.successGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.subGuaranteeTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.successGreen)),
                      const SizedBox(height: 4),
                      Text(s.subGuaranteeMsg,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  )),
                ],
              ),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(s.subManageBtn),
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:        AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        const Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
      ]),
    );
  }
}
