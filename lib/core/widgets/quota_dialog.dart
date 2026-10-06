import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../routing/route_names.dart';
import '../theme/app_colors.dart';

/// "Free AI questions used up" dialog with an upgrade button. Shown whenever
/// an AI call comes back with the monthly quota exceeded.
Future<void> showQuotaDialog(BuildContext context, AppStrings s) {
  return showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(
            Icons.lock_outline,
            color: AppColors.warningYellow,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(s.proLimitTitle)),
        ],
      ),
      content: Text(
        s.proLimitMsg,
        style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            s.proLaterBtn,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.push(RouteNames.subscription);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(s.proUpgradeBtn),
        ),
      ],
    ),
  );
}
