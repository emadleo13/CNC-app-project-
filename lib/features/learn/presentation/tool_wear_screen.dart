import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../data/tool_wear_repository.dart';

final _wearProvider = FutureProvider((ref) => ToolWearRepository().getAll());

const _iconMap = <String, IconData>{
  'trending_flat': Icons.trending_flat,
  'blur_circular': Icons.blur_circular,
  'layers': Icons.layers,
  'content_cut': Icons.content_cut,
  'broken_image': Icons.broken_image,
  'grid_on': Icons.grid_on,
  'warning': Icons.warning,
  'grain': Icons.grain,
};

Color _severityColor(String s) => switch (s) {
      'critical' => AppColors.errorRed,
      'warning' => AppColors.warningYellow,
      _ => AppColors.successGreen,
    };

class ToolWearScreen extends ConsumerWidget {
  const ToolWearScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final async = ref.watch(_wearProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.toolWear)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (types) => ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: types.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _WearCard(type: types[i], s: s),
        ),
      ),
    );
  }
}

class _WearCard extends StatelessWidget {
  final ToolWearType type;
  final AppStrings s;
  const _WearCard({required this.type, required this.s});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(type.severity);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(_iconMap[type.icon] ?? Icons.build, color: color),
        title: Text(type.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(type.severity.toUpperCase(),
            style: TextStyle(fontSize: 10, color: color, letterSpacing: 1)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(type.description,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 12),
          _bullets(s.wearCause, type.causes, Icons.error_outline,
              AppColors.warningYellow),
          const SizedBox(height: 10),
          _bullets(s.wearSolution, type.solutions, Icons.lightbulb_outline,
              AppColors.successGreen),
        ],
      ),
    );
  }

  Widget _bullets(
      String title, List<String> items, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: TextStyle(
                fontSize: 11, letterSpacing: 1, color: color)),
        const SizedBox(height: 6),
        ...items.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
              ]),
            )),
      ],
    );
  }
}
