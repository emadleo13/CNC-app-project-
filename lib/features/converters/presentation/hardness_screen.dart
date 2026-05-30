import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/calc_widgets.dart';
import '../domain/hardness_converter.dart';

class HardnessScreen extends ConsumerStatefulWidget {
  const HardnessScreen({super.key});

  @override
  ConsumerState<HardnessScreen> createState() => _HardnessScreenState();
}

class _HardnessScreenState extends ConsumerState<HardnessScreen> {
  HardnessScale _scale = HardnessScale.hrc;
  double _value = 45;
  final _ctrl = TextEditingController(text: '45');

  static const _scaleLabels = {
    HardnessScale.hrc: 'HRC',
    HardnessScale.hv: 'HV',
    HardnessScale.hb: 'HB',
    HardnessScale.tensileMPa: 'MPa',
  };

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final result = HardnessConverter.convert(_value, _scale);

    return Scaffold(
      appBar: AppBar(title: Text(s.toolHardness)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          CalcSectionCard(
            title: s.hardEnterValue,
            child: Column(children: [
              CalcSegment<HardnessScale>(
                options: _scaleLabels,
                selected: _scale,
                onChanged: (v) => setState(() => _scale = v),
              ),
              const SizedBox(height: 12),
              CalcNumberField(
                label: _scaleLabels[_scale]!,
                controller: _ctrl,
                onChanged: (v) =>
                    setState(() => _value = double.tryParse(v) ?? _value),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (result == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.gcodeRefNoResults,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
            )
          else
            CalcResultCard(
              title: s.resultTitle,
              tiles: [
                CalcResultTile(
                    label: 'Rockwell C',
                    value: result.hrc == null
                        ? '—'
                        : '${result.hrc!.toStringAsFixed(1)} HRC',
                    icon: Icons.diamond_outlined),
                CalcResultTile(
                    label: 'Vickers',
                    value: result.hv == null
                        ? '—'
                        : '${result.hv!.round()} HV',
                    icon: Icons.change_history),
                CalcResultTile(
                    label: 'Brinell',
                    value: result.hb == null
                        ? '—'
                        : '${result.hb!.round()} HB',
                    icon: Icons.circle_outlined),
                CalcResultTile(
                    label: 'Tensile',
                    value: result.tensileMPa == null
                        ? '—'
                        : '${result.tensileMPa!.round()} MPa',
                    icon: Icons.fitness_center),
              ],
            ),
        ],
      ),
    );
  }
}
