import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calc/units.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/calc_widgets.dart';
import '../domain/part_weight_calculator.dart';

/// Common material densities in g/cm³.
const _densities = <String, double>{
  'Steel': 7.85,
  'Stainless': 8.00,
  'Aluminium': 2.70,
  'Brass': 8.50,
  'Cast iron': 7.20,
  'Titanium': 4.51,
  'Copper': 8.96,
  'Plastic': 1.20,
};

class PartWeightScreen extends ConsumerStatefulWidget {
  const PartWeightScreen({super.key});

  @override
  ConsumerState<PartWeightScreen> createState() => _PartWeightScreenState();
}

class _PartWeightScreenState extends ConsumerState<PartWeightScreen> {
  late UnitSystem _units;
  StockShape _shape = StockShape.roundBar;
  String _material = 'Steel';
  double _a = 50, _b = 20, _c = 100;

  final _aCtrl = TextEditingController(text: '50');
  final _bCtrl = TextEditingController(text: '20');
  final _cCtrl = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _units = ref.read(defaultUnitsProvider) == 'imperial'
        ? UnitSystem.imperial
        : UnitSystem.metric;
  }

  @override
  void dispose() {
    _aCtrl.dispose();
    _bCtrl.dispose();
    _cCtrl.dispose();
    super.dispose();
  }

  // Per-shape dimension labels; null = field hidden.
  (String, String?, String) _labels(String u) => switch (_shape) {
        StockShape.roundBar => ('Ø ($u)', null, 'Length ($u)'),
        StockShape.tube => ('OD ($u)', 'ID ($u)', 'Length ($u)'),
        StockShape.hexBar => ('AF ($u)', null, 'Length ($u)'),
        StockShape.square => ('Side ($u)', null, 'Length ($u)'),
        StockShape.rectBar => ('Width ($u)', 'Height ($u)', 'Length ($u)'),
        StockShape.sheet => ('Width ($u)', 'Length ($u)', 'Thick ($u)'),
        StockShape.plate => ('Width ($u)', 'Length ($u)', 'Thick ($u)'),
      };

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final u = _units.lengthLabel;
    final density = _densities[_material]!;
    final labels = _labels(u);

    final grams = PartWeightCalculator.grams(
        shape: _shape,
        a: _a,
        b: _b,
        c: _c,
        densityGCm3: density,
        units: _units);
    final lbs = PartWeightCalculator.pounds(
        shape: _shape,
        a: _a,
        b: _b,
        c: _c,
        densityGCm3: density,
        units: _units);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.toolWeight),
        actions: [
          CalcUnitToggle(
              units: _units, onChanged: (v) => setState(() => _units = v)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          CalcSectionCard(
            title: s.secInputs,
            child: Column(children: [
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Shape'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<StockShape>(
                    value: _shape,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceAlt,
                    items: StockShape.values
                        .map((sh) => DropdownMenuItem(
                            value: sh, child: Text(sh.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _shape = v ?? _shape),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Material'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _material,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceAlt,
                    items: _densities.keys
                        .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                                '$m  (${_densities[m]!.toStringAsFixed(2)} g/cm³)')))
                        .toList(),
                    onChanged: (v) => setState(() => _material = v ?? _material),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: CalcNumberField(
                        label: labels.$1,
                        controller: _aCtrl,
                        onChanged: (v) =>
                            setState(() => _a = double.tryParse(v) ?? _a))),
                if (labels.$2 != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                      child: CalcNumberField(
                          label: labels.$2!,
                          controller: _bCtrl,
                          onChanged: (v) =>
                              setState(() => _b = double.tryParse(v) ?? _b))),
                ],
              ]),
              const SizedBox(height: 12),
              CalcNumberField(
                  label: labels.$3,
                  controller: _cCtrl,
                  onChanged: (v) =>
                      setState(() => _c = double.tryParse(v) ?? _c)),
            ]),
          ),
          const SizedBox(height: 16),
          CalcResultCard(title: s.resultTitle, tiles: [
            CalcResultTile(
                label: 'Grams',
                value: grams.toStringAsFixed(1),
                icon: Icons.scale_outlined),
            CalcResultTile(
                label: 'Kilograms',
                value: (grams / 1000).toStringAsFixed(3),
                icon: Icons.fitness_center),
            CalcResultTile(
                label: 'Pounds',
                value: lbs.toStringAsFixed(3),
                icon: Icons.line_weight),
          ]),
        ],
      ),
    );
  }
}
