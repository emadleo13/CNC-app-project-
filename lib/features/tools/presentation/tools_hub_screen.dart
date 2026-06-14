import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/tool_def.dart';
import '../domain/recent_tools.dart';

/// Phase 0 — the calculator "hub": a grid of every machining tool, grouped by
/// category. Replaces the old single milling screen as the `/calculator` tab.
class ToolsHubScreen extends ConsumerWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    // Resolve the persisted recent ids into enabled tools, newest first.
    final recentIds = ref.watch(recentToolsProvider);
    final recentTools = <ToolDef>[
      for (final id in recentIds)
        for (final t in kTools)
          if (t.id == id && !t.comingSoon) t,
    ];

    void open(ToolDef tool) {
      ref.read(recentToolsProvider.notifier).record(tool.id);
      context.push(tool.route);
    }

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
          if (recentTools.isNotEmpty) _QuickAccessRow(
            tools: recentTools,
            label: s.quickAccess,
            s: s,
            onTap: open,
          ),
          for (final category in ToolCategory.values)
            ..._buildCategory(s, category, open),
        ],
      ),
    );
  }

  List<Widget> _buildCategory(
      AppStrings s, ToolCategory category, void Function(ToolDef) onTap) {
    final tools = kTools.where((t) => t.category == category).toList();
    if (tools.isEmpty) return const [];
    return [
      _SectionLabel(category.label(s)),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: tools.map((t) => _ToolCard(tool: t, s: s, onTap: onTap)).toList(),
      ),
    ];
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Horizontal strip of recently-opened tools shown at the top of the hub.
class _QuickAccessRow extends StatelessWidget {
  final List<ToolDef> tools;
  final String label;
  final AppStrings s;
  final void Function(ToolDef) onTap;
  const _QuickAccessRow({
    required this.tools,
    required this.label,
    required this.s,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: tools.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final t = tools[i];
              return GestureDetector(
                onTap: () => onTap(t),
                child: Container(
                  width: 132,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(t.icon, size: 22, color: AppColors.primary),
                      Text(
                        t.title(s),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final ToolDef tool;
  final AppStrings s;
  final void Function(ToolDef) onTap;
  const _ToolCard({required this.tool, required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = !tool.comingSoon;
    return GestureDetector(
      onTap: enabled ? () => onTap(tool) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
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
