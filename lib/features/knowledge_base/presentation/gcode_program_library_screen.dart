import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/help_card.dart';
import '../data/gcode_programs_repository.dart';
import '../domain/gcode_program.dart';

final _programsRepoProvider = Provider((_) => GcodeProgramsRepository());
final _programsProvider = FutureProvider<List<GcodeProgram>>((ref) {
  return ref.read(_programsRepoProvider).loadAll();
});

const _difficultyColors = {
  'beginner':     AppColors.successGreen,
  'intermediate': AppColors.warningYellow,
  'advanced':     AppColors.errorRed,
};

String _categoryLabel(AppStrings s, String category) => switch (category) {
  'circles'   => s.progCatCircles,
  'pockets'   => s.progCatPockets,
  'drilling'  => s.progCatDrilling,
  'spirals'   => s.progCatSpirals,
  'engraving' => s.progCatEngraving,
  'contours'  => s.progCatContours,
  'facing'    => s.progCatFacing,
  'turning'   => s.progCatTurning,
  _           => category,
};

String _difficultyLabel(AppStrings s, String difficulty) => switch (difficulty) {
  'beginner'     => s.progLibBeginner,
  'intermediate' => s.progLibIntermediate,
  'advanced'     => s.progLibAdvanced,
  _              => difficulty,
};

const _categories = ['circles', 'pockets', 'drilling', 'spirals', 'engraving', 'contours', 'facing', 'turning'];

class GcodeProgramLibraryScreen extends ConsumerStatefulWidget {
  const GcodeProgramLibraryScreen({super.key});

  @override
  ConsumerState<GcodeProgramLibraryScreen> createState() => _GcodeProgramLibraryScreenState();
}

class _GcodeProgramLibraryScreenState extends ConsumerState<GcodeProgramLibraryScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';
  String _query  = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<GcodeProgram> _applyFilter(List<GcodeProgram> all) {
    final q    = _query.toLowerCase().trim();
    final list = _filter == 'all' ? all : all.where((p) => p.category == _filter).toList();
    if (q.isEmpty) return list;
    return list.where((p) =>
      p.title.toLowerCase().contains(q) ||
      p.description.toLowerCase().contains(q) ||
      p.code.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s     = ref.watch(appStringsProvider);
    final async = ref.watch(_programsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.progLibTitle)),
      body: Column(
        children: [
          HelpCard(title: s.helpProgLibTitle, btnLabel: s.helpBtnLabel, steps: s.helpProgLibSteps),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged:  (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText:   s.progLibSearchHint,
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

          async.whenData((all) {
            final filtered = _applyFilter(all);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${filtered.length} ${s.progLibCount}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            );
          }).value ?? const SizedBox.shrink(),

          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final filtered = _applyFilter(all);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(s.progLibNoResults,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _ProgramCard(
                    program: filtered[i],
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

  void _showDetail(BuildContext ctx, GcodeProgram program, AppStrings s) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize:     0.94,
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
              _DifficultyBadge(difficulty: program.difficulty, s: s),
              const SizedBox(width: 8),
              _CategoryBadge(label: _categoryLabel(s, program.category)),
            ]),
            const SizedBox(height: 12),

            Text(program.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            Text(program.description,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),

            const SizedBox(height: 20),
            Row(children: [
              const Icon(Icons.code, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(s.progLibCodeLabel,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
                tooltip: s.progLibCopy,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: program.code));
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(s.progLibCopied),
                      duration: const Duration(seconds: 2),
                    ));
                  }
                },
              ),
            ]),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                program.code,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  height: 1.6,
                  color: AppColors.gcodeValue,
                ),
              ),
            ),

            if (program.notes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.warningYellow),
                const SizedBox(width: 6),
                Text(s.progLibNotesLabel,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warningYellow)),
              ]),
              const SizedBox(height: 8),
              ...program.notes.map((note) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 5, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(note,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                    ),
                  ],
                ),
              )),
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

class _DifficultyBadge extends StatelessWidget {
  final String     difficulty;
  final AppStrings s;
  const _DifficultyBadge({required this.difficulty, required this.s});

  @override
  Widget build(BuildContext context) {
    final color = _difficultyColors[difficulty] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(_difficultyLabel(s, difficulty),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final GcodeProgram program;
  final AppStrings   s;
  final VoidCallback onTap;
  const _ProgramCard({required this.program, required this.s, required this.onTap});

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _DifficultyBadge(difficulty: program.difficulty, s: s),
                        const SizedBox(width: 8),
                        _CategoryBadge(label: _categoryLabel(s, program.category)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(program.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(program.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
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
}
