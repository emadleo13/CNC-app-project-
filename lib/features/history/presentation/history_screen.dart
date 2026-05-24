import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
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
      body: TabBarView(
        controller: _tabs,
        children: [
          _CalculationsList(items: calculations),
          _AnalysesList(items: analyses),
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
    if (items.isEmpty) return _EmptyState(s: s);

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
          child: _CalcCard(c: c),
        );
      },
    );
  }
}

class _CalcCard extends StatelessWidget {
  final SavedCalculation c;
  const _CalcCard({required this.c});

  static String _toolLabel(String code) {
    switch (code) {
      case 'end_mill_2fl': return '2fl EM';
      case 'end_mill_4fl': return '4fl EM';
      case 'face_mill':    return 'Face Mill';
      case 'drill_hss':    return 'HSS Drill';
      default:             return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedUnit = c.units == 'mm' ? 'mm/min' : 'in/min';
    final vcUnit   = c.units == 'mm' ? 'm/min'  : 'SFM';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.speed, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  c.materialName,
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
              '${_toolLabel(c.toolTypeCode)}  ·  ⌀${c.diameter}${c.units}  ·  ${c.flutes}fl',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(children: [
              _Metric(label: 'RPM',  value: c.rpm.toString()),
              const SizedBox(width: 16),
              _Metric(label: 'Feed', value: '${c.feedRatePerMin.toStringAsFixed(1)} $feedUnit'),
              const SizedBox(width: 16),
              _Metric(label: 'Vc',   value: '${c.cuttingSpeed.toStringAsFixed(0)} $vcUnit'),
            ]),
          ],
        ),
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
    if (items.isEmpty) return _EmptyState(s: s);

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

class _EmptyState extends StatelessWidget {
  final AppStrings s;
  const _EmptyState({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(s.historyEmpty,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(s.historyEmptyDesc,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
