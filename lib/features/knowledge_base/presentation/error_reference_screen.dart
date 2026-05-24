import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../data/errors_repository.dart';
import '../domain/error_alarm.dart';

final _errorsRepoProvider = Provider((_) => ErrorsRepository());

final _errorsProvider = FutureProvider<List<ErrorAlarm>>((ref) async {
  return ref.read(_errorsRepoProvider).loadAll();
});

class ErrorReferenceScreen extends ConsumerStatefulWidget {
  const ErrorReferenceScreen({super.key});

  @override
  ConsumerState<ErrorReferenceScreen> createState() => _ErrorReferenceScreenState();
}

class _ErrorReferenceScreenState extends ConsumerState<ErrorReferenceScreen> {
  final _searchCtrl = TextEditingController();
  String _filter    = 'all';
  String _query     = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ErrorAlarm> _applyFilter(List<ErrorAlarm> all) {
    final q    = _query.toLowerCase().trim();
    final list = _filter == 'all' ? all : all.where((a) => a.machine == _filter).toList();
    if (q.isEmpty) return list;
    return list.where((a) =>
      a.code.toLowerCase().contains(q) ||
      a.title.toLowerCase().contains(q) ||
      a.description.toLowerCase().contains(q) ||
      a.possibleCauses.any((c) => c.toLowerCase().contains(q)) ||
      a.solutions.any((s) => s.toLowerCase().contains(q))
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s       = ref.watch(appStringsProvider);
    final async   = ref.watch(_errorsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.errRefTitle)),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged:  (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText:    s.errRefSearchHint,
                prefixIcon:  const Icon(Icons.search, size: 20),
                suffixIcon:  _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(label: s.errRefFilterAll,         value: 'all',          selected: _filter == 'all',          onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(label: s.errRefFilterHaas,        value: 'haas',         selected: _filter == 'haas',         onTap: () => setState(() => _filter = 'haas')),
                const SizedBox(width: 8),
                _FilterChip(label: s.errRefFilterSiemens,     value: 'sinumerik',    selected: _filter == 'sinumerik',    onTap: () => setState(() => _filter = 'sinumerik')),
                const SizedBox(width: 8),
                _FilterChip(label: s.errRefFilterFanuc,       value: 'fanuc',        selected: _filter == 'fanuc',        onTap: () => setState(() => _filter = 'fanuc')),
                const SizedBox(width: 8),
                _FilterChip(label: s.errRefFilterHeidenhain,  value: 'heidenhain',   selected: _filter == 'heidenhain',   onTap: () => setState(() => _filter = 'heidenhain')),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // List
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final filtered = _applyFilter(all);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(s.errRefNoResults,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _AlarmCard(
                    alarm: filtered[i],
                    s: s,
                    onTap: () => _showDetail(ctx, filtered[i], s),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext ctx, ErrorAlarm alarm, AppStrings s) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize:     0.95,
        minChildSize:     0.4,
        expand:           false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Code + machine badge
            Row(children: [
              _MachineBadge(machine: alarm.machine),
              const SizedBox(width: 8),
              _SeverityBadge(severity: alarm.severity, s: s),
            ]),
            const SizedBox(height: 12),

            // Title
            Text('${alarm.machine == 'haas' ? 'ALARM' : 'ALARM'} ${alarm.code}',
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize:   13,
                color:      AppColors.textSecondary,
              )),
            const SizedBox(height: 4),
            Text(alarm.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // Description
            Text(alarm.description,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 20),

            // Causes
            _DetailSection(
              title: s.errRefCauses,
              icon:  Icons.help_outline,
              color: AppColors.warningYellow,
              items: alarm.possibleCauses,
            ),
            const SizedBox(height: 16),

            // Solutions
            _DetailSection(
              title: s.errRefSolutions,
              icon:  Icons.build_outlined,
              color: AppColors.successGreen,
              items: alarm.solutions,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool   selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label, required this.value,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final ErrorAlarm alarm;
  final AppStrings s;
  final VoidCallback onTap;
  const _AlarmCard({required this.alarm, required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Severity dot
              Container(
                width: 10, height: 10,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  color: _severityColor(alarm.severity),
                  shape: BoxShape.circle,
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _machinePrefix(alarm.machine, alarm.code),
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize:   12,
                            color:      AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MachineBadge(machine: alarm.machine, small: true),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alarm.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alarm.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  static String _machinePrefix(String machine, String code) => switch (machine) {
    'haas'       => 'Haas $code',
    'sinumerik'  => 'SNK $code',
    'fanuc'      => 'FANUC $code',
    'heidenhain' => 'TNC $code',
    _            => code,
  };

  Color _severityColor(String severity) => switch (severity) {
    'info'     => AppColors.primary,
    'warning'  => AppColors.warningYellow,
    'error'    => AppColors.errorRed,
    'critical' => const Color(0xFFFF3B30),
    _          => AppColors.textMuted,
  };
}

class _MachineBadge extends StatelessWidget {
  final String machine;
  final bool   small;
  const _MachineBadge({required this.machine, this.small = false});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (machine) {
      'haas'       => ('Haas',       const Color(0xFF1A3A5C), const Color(0xFF6EB5FF)),
      'sinumerik'  => ('Siemens',    const Color(0xFF1A5C3A), const Color(0xFF6EFFC3)),
      'fanuc'      => ('FANUC',      const Color(0xFF3A1A1A), const Color(0xFFFF9F6E)),
      'heidenhain' => ('Heidenhain', const Color(0xFF3A1A5C), const Color(0xFFCF9FFF)),
      _            => (machine,      const Color(0xFF2A2A2A), const Color(0xFFAAAAAA)),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color:        bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize:   small ? 10 : 11,
          fontWeight: FontWeight.w600,
          color:      fg,
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  final AppStrings s;
  const _SeverityBadge({required this.severity, required this.s});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (severity) {
      'info'     => (s.errRefSeverityInfo,     AppColors.primary),
      'warning'  => (s.errRefSeverityWarning,  AppColors.warningYellow),
      'error'    => (s.errRefSeverityError,     AppColors.errorRed),
      'critical' => (s.errRefSeverityCritical, const Color(0xFFFF3B30)),
      _          => ('?', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String       title;
  final IconData     icon;
  final Color        color;
  final List<String> items;
  const _DetailSection({
    required this.title, required this.icon,
    required this.color, required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: color, letterSpacing: 0.3,
            )),
        ]),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20, height: 20,
                margin: const EdgeInsets.only(right: 8, top: 1),
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${e.key + 1}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ),
              Expanded(
                child: Text(e.value,
                  style: const TextStyle(fontSize: 13, height: 1.5)),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
