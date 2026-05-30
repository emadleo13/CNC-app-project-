import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/tool_def.dart';

/// Phase 0 — the calculator "hub": a grid of every machining tool, grouped by
/// category. Replaces the old single milling screen as the `/calculator` tab.
class ToolsHubScreen extends ConsumerWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.toolsHubTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.push(RouteNames.settings),
            tooltip: s.navSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          for (final category in ToolCategory.values)
            ..._buildCategory(context, s, category),
        ],
      ),
    );
  }

  List<Widget> _buildCategory(
      BuildContext context, AppStrings s, ToolCategory category) {
    final tools = kTools.where((t) => t.category == category).toList();
    if (tools.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          category.label(s).toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: tools.map((t) => _ToolCard(tool: t, s: s)).toList(),
      ),
    ];
  }
}

class _ToolCard extends StatelessWidget {
  final ToolDef tool;
  final AppStrings s;
  const _ToolCard({required this.tool, required this.s});

  @override
  Widget build(BuildContext context) {
    final enabled = !tool.comingSoon;
    return GestureDetector(
      onTap: enabled ? () => context.push(tool.route) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(tool.icon, size: 22, color: AppColors.primary),
                  const Spacer(),
                  if (tool.comingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warningYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s.toolComingSoon,
                          style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.warningYellow,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                tool.title(s),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                tool.subtitle(s),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
