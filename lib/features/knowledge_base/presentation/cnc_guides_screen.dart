import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/help_card.dart';
import '../data/guides_repository.dart';
import '../domain/cnc_guide.dart';

final _guidesRepoProvider = Provider((_) => GuidesRepository());
final _guidesProvider = FutureProvider<List<CncGuide>>((ref) {
  return ref.read(_guidesRepoProvider).loadAll();
});

const _guideIcons = {
  'precision_manufacturing': Icons.precision_manufacturing_outlined,
  'grid_3x3':                Icons.grid_3x3,
  'my_location':             Icons.my_location_outlined,
  'build_circle':            Icons.build_circle_outlined,
  'handyman':                Icons.handyman_outlined,
  'code':                    Icons.code,
  'speed':                   Icons.speed_outlined,
  'autorenew':               Icons.autorenew,
  'health_and_safety':       Icons.health_and_safety_outlined,
  'settings':                Icons.settings_outlined,
};

const _categories = [
  'machine_basics', 'axes_coordinates', 'tooling', 'work_holding',
  'gcode_basics', 'speeds_feeds', 'lathe_basics', 'safety',
];

String _categoryLabel(AppStrings s, String category) => switch (category) {
  'machine_basics'    => s.guideCatMachineBasics,
  'axes_coordinates'  => s.guideCatAxesCoordinates,
  'tooling'           => s.guideCatTooling,
  'work_holding'      => s.guideCatWorkHolding,
  'gcode_basics'      => s.guideCatGcodeBasics,
  'speeds_feeds'      => s.guideCatSpeedsFeeds,
  'lathe_basics'      => s.guideCatLatheBasics,
  'safety'            => s.guideCatSafety,
  _                   => category,
};

class CncGuidesScreen extends ConsumerStatefulWidget {
  const CncGuidesScreen({super.key});

  @override
  ConsumerState<CncGuidesScreen> createState() => _CncGuidesScreenState();
}

class _CncGuidesScreenState extends ConsumerState<CncGuidesScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';
  String _query  = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CncGuide> _applyFilter(List<CncGuide> all) {
    final q    = _query.toLowerCase().trim();
    final list = _filter == 'all' ? all : all.where((g) => g.category == _filter).toList();
    if (q.isEmpty) return list;
    return list.where((g) =>
      g.title.toLowerCase().contains(q) ||
      g.summary.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s     = ref.watch(appStringsProvider);
    final async = ref.watch(_guidesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.guidesTitle)),
      body: Column(
        children: [
          HelpCard(title: s.helpGuidesTitle, btnLabel: s.helpBtnLabel, steps: s.helpGuidesSteps),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged:  (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText:   s.guidesSearchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
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

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Chip(label: s.progLibFilterAll, selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                for (final cat in _categories) ...[
                  const SizedBox(width: 8),
                  _Chip(label: _categoryLabel(s, cat), selected: _filter == cat, onTap: () => setState(() => _filter = cat)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final filtered = _applyFilter(all);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(s.guidesNoResults,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _GuideCard(
                    guide: filtered[i],
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

  void _showDetail(BuildContext ctx, CncGuide guide, AppStrings s) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize:     0.95,
        minChildSize:     0.4,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
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

            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color:        AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_guideIcons[guide.icon] ?? Icons.menu_book_outlined,
                  size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_categoryLabel(s, guide.category),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    Text(guide.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            for (final section in guide.sections) ...[
              Text(section.heading,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(section.body,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool   selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

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
          border:       Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : AppColors.textSecondary,
          )),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final CncGuide     guide;
  final AppStrings   s;
  final VoidCallback onTap;
  const _GuideCard({required this.guide, required this.s, required this.onTap});

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
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color:        AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_guideIcons[guide.icon] ?? Icons.menu_book_outlined,
                  size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_categoryLabel(s, guide.category),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(guide.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(guide.summary,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
