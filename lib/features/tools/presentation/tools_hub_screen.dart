import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/tool_def.dart';
import '../domain/recent_tools.dart';

// Reference counts shown in the hero. Tools is derived; the others mirror the
// entry counts in assets/data/gcode_reference.json and errors.json.
const int _kGcodeCount = 252;
const int _kErrorCount = 273;

/// The calculator "hub": a dashboard hero, quick access, and a grid of every
/// machining tool grouped by category.
class ToolsHubScreen extends ConsumerWidget {
  const ToolsHubScreen({super.key});

  String _greeting(AppStrings s, String name) {
    if (name.trim().isNotEmpty) return '${s.heroHello} ${name.trim()} 👋';
    final h = DateTime.now().hour;
    if (h < 12) return s.greetingMorning;
    if (h < 18) return s.greetingAfternoon;
    return s.greetingEvening;
  }

  String _tipOfDay(AppStrings s) {
    final tips = s.cncTips;
    if (tips.isEmpty) return '';
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return tips[dayOfYear % tips.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s    = ref.watch(appStringsProvider);
    final name = ref.watch(userNameProvider);

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

    // Assemble the scroll children with a running index so every block fades
    // and slides in with a staggered cascade.
    final children = <Widget>[];
    var idx = 0;
    Widget entrance(Widget w) => _Entrance(index: idx++, child: w);

    children.add(entrance(_HeroHeader(
      greeting: _greeting(s, name),
      prompt:   s.heroPrompt,
      s:        s,
    )));
    children.add(entrance(_TipCard(title: s.tipOfDayTitle, tip: _tipOfDay(s))));

    if (recentTools.isNotEmpty) {
      children.add(entrance(_QuickAccessRow(
        tools: recentTools, label: s.quickAccess, s: s, onTap: open,
      )));
    }

    for (final category in ToolCategory.values) {
      final tools = kTools.where((t) => t.category == category).toList();
      if (tools.isEmpty) continue;
      children.add(entrance(_SectionLabel(category.label(s))));
      children.add(GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: tools.map((t) => entrance(_ToolCard(tool: t, s: s, onTap: open))).toList(),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.push(RouteNames.settings),
            tooltip: s.navSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        children: children,
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String greeting;
  final String prompt;
  final AppStrings s;
  const _HeroHeader({required this.greeting, required this.prompt, required this.s});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(prompt,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(children: [
            _StatPill(value: '${kTools.length}', label: s.statTools),
            const SizedBox(width: 10),
            _StatPill(value: '$_kGcodeCount', label: s.statGcodes),
            const SizedBox(width: 10),
            _StatPill(value: '$_kErrorCount', label: s.statErrors),
          ]),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                )),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Tip of the day ──────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final String title;
  final String tip;
  const _TipCard({required this.title, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.info, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    )),
                const SizedBox(height: 5),
                Text(tip,
                    style: const TextStyle(fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label & quick access ────────────────────────────────────────────

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

/// Horizontal strip of recently-opened tools shown near the top of the hub.
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

// ── Tool card ────────────────────────────────────────────────────────────────

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
                    _Badge(label: s.toolComingSoon, color: AppColors.warningYellow)
                  else if (tool.badge != null)
                    _Badge.forTool(tool.badge!, s),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  factory _Badge.forTool(ToolBadge badge, AppStrings s) {
    return switch (badge) {
      ToolBadge.popular => _Badge(label: s.badgePopular, color: AppColors.successGreen),
      ToolBadge.isNew   => _Badge(label: s.badgeNew,     color: AppColors.info),
      ToolBadge.pro     => _Badge(label: s.badgePro,     color: AppColors.primary),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Entrance animation ────────────────────────────────────────────────────────

/// Fades + slides its child up once, after a per-index delay, for a staggered
/// page-entrance cascade. Replays whenever the subtree is rebuilt fresh (e.g.
/// switching back to this tab).
class _Entrance extends StatefulWidget {
  final int index;
  final Widget child;
  const _Entrance({required this.index, required this.child});

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 360));
    _curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    // Cap the stagger so long lists don't trail for too long.
    final delayMs = (40 * widget.index).clamp(0, 600);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(_curved),
        child: widget.child,
      ),
    );
  }
}
