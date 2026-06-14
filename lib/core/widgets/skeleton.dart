import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A list of pulsing placeholder cards shown while content loads, instead of a
/// bare spinner. A single [AnimationController] drives every placeholder so the
/// effect stays cheap regardless of item count.
class SkeletonList extends StatefulWidget {
  final int count;
  final EdgeInsets padding;
  const SkeletonList({
    super.key,
    this.count = 7,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
  });

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final color = Color.lerp(
          AppColors.surfaceContainerHigh,
          AppColors.surfaceContainerHighest,
          _ctrl.value,
        )!;
        return ListView.separated(
          padding: widget.padding,
          itemCount: widget.count,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, _) => _SkeletonCard(color: color),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final Color color;
  const _SkeletonCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bar(color: color, width: 90, height: 14),
          const SizedBox(height: 10),
          _Bar(color: color, width: double.infinity, height: 12),
          const SizedBox(height: 6),
          _Bar(color: color, width: 200, height: 12),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  const _Bar({required this.color, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
