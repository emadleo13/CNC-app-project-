import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/help_card.dart';
import '../data/history_repository.dart';
import '../domain/saved_analysis.dart';
import '../domain/saved_calculation.dart';

final _dateFmt = DateFormat('MMM d · HH:mm');

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _confirmClearAll(AppStrings s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.historyDeleteAll),
        content: Text(s.historyConfirmClear),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.commonClear,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      if (_tabs.index == 0) {
        await ref.read(calculationsProvider.notifier).clearAll();
      } else {
        await ref.read(analysesProvider.notifier).clearAll();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s            = ref.watch(appStringsProvider);
    final calculations = ref.watch(calculationsProvider);
    final analyses     = ref.watch(analysesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.historyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            tooltip: s.historyDeleteAll,
            onPressed: () => _confirmClearAll(s),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.push(RouteNames.settings),
            tooltip: s.navSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: s.historyCalculations),
            Tab(text: s.historyAnalyses),
          ],
        ),
      ),
      body: Column(
        children: [
          HelpCard(title: s.helpHistoryTitle, btnLabel: s.helpBtnLabel, steps: s.helpHistorySteps),
          _RetentionNote(
            text: s.historyRetentionNote
                .replaceAll('{days}', '${kHistoryRetention.inDays}'),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _CalculationsList(items: calculations),
                _AnalysesList(items: analyses),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Calculations tab ──────────────────────────────────────────────────

class _CalculationsList extends ConsumerWidget {
  final List<SavedCalculation> items;
  const _CalculationsList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    if (items.isEmpty) {
      return _EmptyState(
        s: s,
        icon: Icons.speed,
        ctaLabel: s.historyEmptyCtaCalc,
        onCta: () => context.go(RouteNames.calculator),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final c = items[i];
        return Dismissible(
          key: Key('calc_${c.savedAt.millisecondsSinceEpoch}'),
          direction: DismissDirection.endToStart,
          background: const _DismissBackground(),
          onDismissed: (_) =>
              ref.read(calculationsProvider.notifier).deleteAt(i),
          child: _CalcCard(c: c, s: s),
        );
      },
    );
  }
}

class _CalcCard extends StatelessWidget {
  final SavedCalculation c;
  final AppStrings s;
  const _CalcCard({required this.c, required this.s});

  static String _toolLabel(String code) {
    switch (code) {
      case 'end_mill_2fl': return '2fl EM';
      case 'end_mill_4fl': return '4fl EM';
      case 'face_mill':    return 'Face Mill';
      case 'drill_hss':    return 'HSS Drill';
      default:             return code;
    }
  }

  /// 10 → "10", 0.15 → "0.15".
  static String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

  /// Minutes as "1m 05s", like the calculators show it.
  static String _time(double minutes) {
    final total = (minutes * 60).round();
    return '${total ~/ 60}m ${(total % 60).toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final u        = c.units;
    final feedUnit = u == 'mm' ? 'mm/min' : 'in/min';
    final frUnit   = u == 'mm' ? 'mm/rev' : 'in/rev';
    final vcUnit   = u == 'mm' ? 'm/min'  : 'SFM';
    final rpm  = _Metric(label: 'RPM',  value: c.rpm.toString());
    final feed = _Metric(label: 'Feed', value: '${c.feedRatePerMin.toStringAsFixed(1)} $feedUnit');
    final (IconData icon, String title, String details, Widget third) = switch (c.kind) {
      CalcKind.milling => (
        Icons.speed,
        c.materialName,
        '${_toolLabel(c.toolTypeCode)}  ·  ⌀${c.diameter}${c.units}  ·  ${c.flutes}fl',
        _Metric(label: 'Vc', value: '${c.cuttingSpeed.toStringAsFixed(0)} $vcUnit'),
      ),
      CalcKind.turning => (
        Icons.album_outlined,
        s.toolTurning,
        '⌀${_n(c.diameter)} $u  ·  f ${_n(c.feedPerRev)} $frUnit  ·  ap ${_n(c.depth)} $u'
            '  ·  L ${_n(c.length)} $u${c.passes > 1 ? '  ×${c.passes}' : ''}',
        _Metric(label: s.resCutTime, value: _time(c.cutTimeMin)),
      ),
      CalcKind.drilling => (
        Icons.vertical_align_bottom,
        s.toolDrilling,
        '⌀${_n(c.diameter)} $u  ·  f ${_n(c.feedPerRev)} $frUnit  ·  depth ${_n(c.depth)} $u'
            '  ·  ${_n(c.pointAngle)}°',
        _Metric(label: s.resCutTime, value: _time(c.cutTimeMin)),
      ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Text(
                _dateFmt.format(c.savedAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              details,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(children: [
              rpm,
              const SizedBox(width: 16),
              feed,
              const SizedBox(width: 16),
              third,
            ]),
          ],
        ),
      ),
    );
  }
}

/// How long entries are kept, under the help card.
class _RetentionNote extends StatelessWidget {
  final String text;
  const _RetentionNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(value,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            )),
      ],
    );
  }
}

// ── Analyses tab ──────────────────────────────────────────────────────

class _AnalysesList extends ConsumerWidget {
  final List<SavedAnalysis> items;
  const _AnalysesList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    if (items.isEmpty) {
      return _EmptyState(
        s: s,
        icon: Icons.code,
        ctaLabel: s.historyEmptyCtaAnalysis,
        onCta: () => context.go(RouteNames.gcodeAnalyzer),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final a = items[i];
        return Dismissible(
          key: Key('analysis_${a.savedAt.millisecondsSinceEpoch}'),
          direction: DismissDirection.endToStart,
          background: const _DismissBackground(),
          onDismissed: (_) =>
              ref.read(analysesProvider.notifier).deleteAt(i),
          child: _AnalysisCard(a: a),
        );
      },
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final SavedAnalysis a;
  const _AnalysisCard({required this.a});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.code, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  a.label,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _dateFmt.format(a.savedAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                _Chip(
                  icon: Icons.settings_outlined,
                  label: a.dialectName,
                  color: AppColors.infoBlue,
                ),
                _Chip(
                  icon: Icons.format_list_numbered,
                  label: '${a.lineCount} lines',
                  color: AppColors.textSecondary,
                ),
                if (a.errorCount > 0)
                  _Chip(
                    icon: Icons.error_outline,
                    label: '${a.errorCount} err',
                    color: AppColors.errorRed,
                  ),
                if (a.warningCount > 0)
                  _Chip(
                    icon: Icons.warning_amber_outlined,
                    label: '${a.warningCount} warn',
                    color: AppColors.warningYellow,
                  ),
                if (a.errorCount == 0 && a.warningCount == 0)
                  const _Chip(
                    icon: Icons.check_circle_outline,
                    label: 'OK',
                    color: AppColors.successGreen,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline, color: AppColors.errorRed),
    );
  }
}

/// A branded badge whose outer ring keeps pulsing outward (radar style),
/// giving the empty state a subtle animated illustration in pure Flutter.
class _PulseBadge extends StatefulWidget {
  final IconData icon;
  const _PulseBadge({required this.icon});

  @override
  State<_PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<_PulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Two expanding rings, offset in phase.
              _ring(_c.value),
              _ring((_c.value + 0.5) % 1.0),
              child!,
            ],
          );
        },
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.14),
          ),
          child: Icon(widget.icon, size: 36, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _ring(double t) {
    final size = 76.0 + t * 56.0;          // 76 → 132
    final opacity = (1.0 - t) * 0.28;       // fade out as it grows
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: opacity),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppStrings s;
  final IconData icon;
  final String ctaLabel;
  final VoidCallback onCta;
  const _EmptyState({
    required this.s,
    required this.icon,
    required this.ctaLabel,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Branded animated badge: a slow "radar" pulse behind the tab icon.
            _PulseBadge(icon: icon),
            const SizedBox(height: 20),
            Text(s.historyEmpty,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(s.historyEmptyDesc,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCta,
              icon: const Icon(Icons.add, size: 18),
              label: Text(ctaLabel),
            ),
          ],
        ),
      ),
    );
  }
}
