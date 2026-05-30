import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../calc/units.dart';

/// Reusable building blocks for calculator screens.
///
/// These mirror the private widgets first written for the milling
/// `CalculatorScreen`, promoted to `core` so every new tool (turning,
/// drilling, converters, …) renders with the same industrial look.

/// Titled card wrapping a block of inputs or results.
class CalcSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const CalcSectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Decimal text field used for every numeric input.
class CalcNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool allowNegative;
  const CalcNumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.allowNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: allowNegative,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(allowNegative ? r'[0-9.\-]' : r'[0-9.]'),
        ),
      ],
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}

/// Generic horizontal segmented selector (labelled).
class CalcSegment<T> extends StatelessWidget {
  final String? label;
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;
  const CalcSegment({
    super.key,
    this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: options.entries
          .map((e) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => onChanged(e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected == e.key
                            ? AppColors.primaryDim
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: selected == e.key
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        e.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected == e.key
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
    if (label == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label!,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        row,
      ],
    );
  }
}

/// Metric/Imperial toggle for an [AppBar] actions slot.
class CalcUnitToggle extends StatelessWidget {
  final UnitSystem units;
  final ValueChanged<UnitSystem> onChanged;
  const CalcUnitToggle({super.key, required this.units, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: SegmentedButton<UnitSystem>(
        segments: const [
          ButtonSegment(value: UnitSystem.metric, label: Text('mm')),
          ButtonSegment(value: UnitSystem.imperial, label: Text('in')),
        ],
        selected: {units},
        onSelectionChanged: (v) => onChanged(v.first),
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
          minimumSize: WidgetStateProperty.all(const Size(48, 32)),
        ),
      ),
    );
  }
}

/// A single labelled result value (monospace, accent-coloured).
class CalcResultTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const CalcResultTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppColors.primary,
                fontFamily: 'JetBrainsMono',
              )),
        ],
      ),
    );
  }
}

/// Grid of [CalcResultTile]s, two per row, inside an accented result card.
class CalcResultCard extends StatelessWidget {
  final String title;
  final List<CalcResultTile> tiles;
  final Widget? footer;
  const CalcResultCard({
    super.key,
    required this.title,
    required this.tiles,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(Row(children: [
        Expanded(child: tiles[i]),
        Expanded(
          child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox(),
        ),
      ]));
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 12));
    }
    return Card(
      color: AppColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.primary, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.check_circle,
                  color: AppColors.successGreen, size: 18),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 16),
            ...rows,
            if (footer != null) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
