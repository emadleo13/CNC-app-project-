import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/purchase_controller.dart';
import '../data/subscription_repository.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  SubscriptionOption? _product;
  bool            _loading    = true;
  String?         _errorMsg;   // red — a real failure (e.g. purchase failed)
  String?         _infoMsg;    // amber — a benign notice (store/price unavailable)

  /// Play Billing answered: a missing product then means the subscription is
  /// not live in Play Console, not that the app was installed elsewhere.
  bool            _billingAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final s = ref.read(appStringsProvider);
    setState(() { _loading = true; _errorMsg = null; _infoMsg = null; });
    try {
      final repo = ref.read(subscriptionRepoProvider);
      final available = await repo
          .isAvailable()
          .timeout(const Duration(seconds: 8), onTimeout: () => false);
      _billingAvailable = available;
      if (!available) {
        if (mounted) setState(() => _infoMsg = s.subNotAvailable);
        return;
      }
      final product = await repo
          .loadProduct()
          .timeout(const Duration(seconds: 8), onTimeout: () => null);
      if (mounted) {
        setState(() {
          _product = product;
          // Store is reachable but the product isn't configured/returned —
          // benign (common in unpublished builds), so show a soft notice.
          if (product == null) _infoMsg = s.subProductUnavailable;
        });
      }
    } catch (_) {
      // Billing client not ready, no Play Store, unsupported device, etc.
      if (mounted) setState(() => _infoMsg = s.subNotAvailable);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Shows the outcome of a purchase or restore the user started. Every user
  /// action passes through [PurchaseFlow.busy], so each outcome is a fresh
  /// transition even when it repeats the previous one.
  void _onFlow(PurchaseFlow flow) {
    final s = ref.read(appStringsProvider);
    void snack(String text, Color color) => ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
    switch (flow) {
      case PurchaseFlow.purchased:
      case PurchaseFlow.restored:
        snack(flow == PurchaseFlow.purchased ? s.subSuccess : s.subRestored,
            AppColors.successGreen);
        Navigator.pop(context, true);
      case PurchaseFlow.pending:
        setState(() { _errorMsg = null; _infoMsg = s.subPending; });
      case PurchaseFlow.canceled:
        setState(() { _errorMsg = null; _infoMsg = s.subCanceled; });
      case PurchaseFlow.nothingToRestore:
        setState(() { _errorMsg = null; _infoMsg = s.subNothingToRestore; });
      case PurchaseFlow.verifyRetry:
        setState(() { _errorMsg = null; _infoMsg = s.subVerifyRetry; });
      case PurchaseFlow.error:
        setState(() { _infoMsg = null; _errorMsg = s.subError; });
      case PurchaseFlow.idle:
      case PurchaseFlow.busy:
        break;
    }
  }

  Future<void> _subscribe() async {
    final s = ref.read(appStringsProvider);
    // No product means Play Billing isn't available (e.g. a sideloaded build,
    // or the subscription isn't live in Play Console yet). Give clear feedback
    // instead of doing nothing.
    if (_product == null) {
      final msg = _billingAvailable ? s.subProductUnavailable : s.subNeedsPlayStore;
      setState(() => _infoMsg = msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.warningYellow,
      ));
      return;
    }
    setState(() { _errorMsg = null; _infoMsg = null; });
    await ref.read(purchaseControllerProvider.notifier).buy(_product!.product);
  }

  Future<void> _restore() async {
    setState(() { _errorMsg = null; _infoMsg = null; });
    await ref.read(purchaseControllerProvider.notifier).restore();
  }

  Future<void> _manage() async {
    try {
      await launchUrl(kManageSubscriptionUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ref.read(appStringsProvider).subNeedsPlayStore),
        backgroundColor: AppColors.warningYellow,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s    = ref.watch(appStringsProvider);
    final tier = ref.watch(currentTierProvider);
    ref.listen<PurchaseFlow>(purchaseControllerProvider, (_, flow) => _onFlow(flow));

    // Never block the whole screen on the tier lookup — show content
    // immediately, treating an unknown tier as 'free'.
    return Scaffold(
      appBar: AppBar(title: Text(s.subTitle)),
      body: _buildContent(s, tier.valueOrNull ?? 'free'),
    );
  }

  Widget _buildContent(AppStrings s, String tier) {
    final isPro = tier == 'pro' || tier == 'team';
    final flow = ref.watch(purchaseControllerProvider);
    final purchasing = flow == PurchaseFlow.busy || flow == PurchaseFlow.pending;

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

          // Benign notice (e.g. live price unavailable) — calm, not an alarm.
          if (_infoMsg != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningYellow.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warningYellow.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.warningYellow),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_infoMsg!,
                      style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                  ),
                ],
              ),
            ),

          if (!isPro) ...[
            // Free trial badge: only when Play actually offers this user the
            // trial (it is not offered again after one was used).
            if (_product?.freeTrial ?? false) Container(
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
              // Always tappable (unless busy): when no product is loaded the tap
              // explains why purchases are unavailable rather than doing nothing.
              onPressed: (purchasing || _loading) ? null : _subscribe,
              style: ElevatedButton.styleFrom(
                padding:  const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primary,
              ),
              child: purchasing
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
              onPressed: (purchasing || _loading) ? null : _restore,
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
              onPressed: _manage,
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
