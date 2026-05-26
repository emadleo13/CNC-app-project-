import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../data/gcode_repository.dart';

final _gcodeRepoProvider  = Provider((_) => GcodeRepository());
final _gcodeEntriesProvider = FutureProvider<List<GcodeEntry>>((ref) {
  return ref.read(_gcodeRepoProvider).loadAll();
});

// ── brand colours ─────────────────────────────────────────────────────────────
const _brandMeta = {
  'haas':       (label: 'Haas',       bg: Color(0xFF1A3A5C), fg: Color(0xFF6EB5FF)),
  'sinumerik':  (label: 'Siemens',    bg: Color(0xFF1A5C3A), fg: Color(0xFF6EFFC3)),
  'fanuc':      (label: 'FANUC',      bg: Color(0xFF3A1A1A), fg: Color(0xFFFF9F6E)),
  'heidenhain': (label: 'Heidenhain', bg: Color(0xFF3A1A5C), fg: Color(0xFFCF9FFF)),
};

class GcodeReferenceScreen extends ConsumerStatefulWidget {
  const GcodeReferenceScreen({super.key});

  @override
  ConsumerState<GcodeReferenceScreen> createState() => _GcodeReferenceScreenState();
}

class _GcodeReferenceScreenState extends ConsumerState<GcodeReferenceScreen> {
  final _searchCtrl = TextEditingController();
  String _filter    = 'all';
  String _query     = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<GcodeEntry> _applyFilter(List<GcodeEntry> all) {
    final q    = _query.toLowerCase().trim();
    final list = _filter == 'all' ? all : all.where((e) => e.brands.contains(_filter)).toList();
    if (q.isEmpty) return list;
    return list.where((e) =>
      e.code.toLowerCase().contains(q) ||
      e.name.toLowerCase().contains(q) ||
      e.description.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s     = ref.watch(appStringsProvider);
    final async = ref.watch(_gcodeEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.gcodeRefTitle)),
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
                hintText:   s.gcodeRefSearchHint,
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

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Chip(label: s.gcodeRefFilterAll,         value: 'all',          selected: _filter == 'all',          onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _BrandChip(brand: 'haas',       selected: _filter == 'haas',       onTap: () => setState(() => _filter = 'haas')),
                const SizedBox(width: 8),
                _BrandChip(brand: 'sinumerik',  selected: _filter == 'sinumerik',  onTap: () => setState(() => _filter = 'sinumerik')),
                const SizedBox(width: 8),
                _BrandChip(brand: 'fanuc',      selected: _filter == 'fanuc',      onTap: () => setState(() => _filter = 'fanuc')),
                const SizedBox(width: 8),
                _BrandChip(brand: 'heidenhain', selected: _filter == 'heidenhain', onTap: () => setState(() => _filter = 'heidenhain')),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Count chip
          async.whenData((all) {
            final filtered = _applyFilter(all);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${filtered.length} ${s.gcodeRefCount}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            );
          }).value ?? const SizedBox.shrink(),

          // List
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final filtered = _applyFilter(all);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(s.gcodeRefNoResults,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _CodeCard(
                    entry: filtered[i],
                    onTap:  () => _showDetail(ctx, filtered[i], s),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext ctx, GcodeEntry entry, AppStrings s) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize:     0.92,
        minChildSize:     0.35,
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

            // Code + brand badge
            Row(children: [
              _BrandBadge(brand: entry.brand),
            ]),
            const SizedBox(height: 12),

            // Code
            Text(
              entry.code,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),

            // Name
            Text(entry.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // Description
            Text(entry.description,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),

            // Syntax
            if (entry.syntax != null) ...[
              const SizedBox(height: 20),
              Row(children: [
                const Icon(Icons.code, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(s.gcodeRefSyntax,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  entry.syntax!,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    height: 1.6,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],

            // Warning
            if (entry.warning != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        AppColors.warningYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:       Border.all(color: AppColors.warningYellow.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                      size: 16, color: AppColors.warningYellow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.warning!,
                        style: const TextStyle(
                          fontSize: 13, color: AppColors.warningYellow, height: 1.4)),
                    ),
                  ],
                ),
              ),
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
  final String value;
  final bool   selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.value, required this.selected, required this.onTap});

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

class _BrandChip extends StatelessWidget {
  final String brand;
  final bool   selected;
  final VoidCallback onTap;
  const _BrandChip({required this.brand, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = _brandMeta[brand]!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? meta.bg : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(
            color: selected ? meta.fg : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(meta.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? meta.fg : AppColors.textSecondary,
          )),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final GcodeEntry entry;
  final VoidCallback onTap;
  const _CodeCard({required this.entry, required this.onTap});

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
                        Text(
                          entry.code.replaceAll('_lathe', '').replaceAll('_thread', '').replaceAll('_snk', '').replaceAll('_facing', ''),
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _BrandBadge(brand: entry.brand, small: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(entry.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(entry.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (entry.warning != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: const Icon(Icons.warning_amber_outlined,
                    size: 16, color: AppColors.warningYellow),
                ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  final String brand;
  final bool   small;
  const _BrandBadge({required this.brand, this.small = false});

  @override
  Widget build(BuildContext context) {
    final meta = _brandMeta[brand] ??
        (label: brand, bg: const Color(0xFF2A2A2A), fg: const Color(0xFFAAAAAA));
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color:        meta.bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(meta.label,
        style: TextStyle(
          fontSize:   small ? 10 : 11,
          fontWeight: FontWeight.w600,
          color:      meta.fg,
        )),
    );
  }
}
