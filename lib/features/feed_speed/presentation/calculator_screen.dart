import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../data/materials_repository.dart';
import '../domain/calculators/milling_calculator.dart';
import '../domain/cut_parameters.dart';
import '../domain/material_spec.dart';
import '../../history/data/history_repository.dart';
import '../../history/domain/saved_calculation.dart';
import '../../subscription/data/subscription_repository.dart';
import 'setup_sheet_screen.dart';
import 'tooling_recs_screen.dart';

final _materialsProvider = FutureProvider<List<MaterialSpec>>((ref) {
  return MaterialsRepository().getAll();
});

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  String? _selectedMaterialCode;
  String _toolTypeCode  = 'end_mill_4fl';
  ToolMaterial _toolMat = ToolMaterial.carbide;
  OperationType _opType = OperationType.roughing;
  late UnitSystem _units;
  int _flutes           = 4;
  double _diameter      = 10.0;
  double _doc           = 2.0;
  double _woc           = 5.0;

  CutParameters? _result;

  final _diameterCtrl = TextEditingController(text: '10');
  final _docCtrl      = TextEditingController(text: '2');
  final _wocCtrl      = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    final saved = ref.read(defaultUnitsProvider);
    _units = saved == 'imperial' ? UnitSystem.imperial : UnitSystem.metric;
  }

  Future<void> _saveToHistory(List<MaterialSpec> materials) async {
    if (_result == null || _selectedMaterialCode == null) return;
    final material = materials.firstWhere((m) => m.code == _selectedMaterialCode);
    final c = SavedCalculation(
      materialName:   material.name,
      toolTypeCode:   _toolTypeCode,
      diameter:       _diameter,
      flutes:         _flutes,
      units:          _units == UnitSystem.metric ? 'mm' : 'in',
      rpm:            _result!.rpm,
      feedRatePerMin: _result!.feedRatePerMin,
      chipLoad:       _result!.chipLoad,
      mrr:            _result!.mrr,
      cuttingSpeed:   _result!.cuttingSpeed,
      savedAt:        DateTime.now(),
    );
    await ref.read(calculationsProvider.notifier).save(c);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ref.read(appStringsProvider).historySaved),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _calculate(List<MaterialSpec> materials) {
    if (_selectedMaterialCode == null) return;
    final material = materials.firstWhere((m) => m.code == _selectedMaterialCode);
    final input = CalculatorInput(
      materialCode:  _selectedMaterialCode!,
      toolTypeCode:  _toolTypeCode,
      toolDiameter:  _diameter,
      flutes:        _flutes,
      toolMaterial:  _toolMat,
      operationType: _opType,
      units:         _units,
      depthOfCut:    _doc,
      widthOfCut:    _woc,
    );
    setState(() => _result = MillingCalculator.calculate(input: input, material: material));
  }

  @override
  void dispose() {
    _diameterCtrl.dispose();
    _docCtrl.dispose();
    _wocCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final materialsAsync = ref.watch(_materialsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.calculatorTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SegmentedButton<UnitSystem>(
              segments: [
                ButtonSegment(value: UnitSystem.metric,   label: Text(s.unitMm)),
                ButtonSegment(value: UnitSystem.imperial, label: Text(s.unitInch)),
              ],
              selected: {_units},
              onSelectionChanged: (v) => setState(() {
                _units = v.first;
                _result = null;
              }),
              style: ButtonStyle(
                textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
                minimumSize: WidgetStateProperty.all(const Size(48, 32)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.push(RouteNames.settings),
            tooltip: s.navSettings,
          ),
        ],
      ),
      body: materialsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data:    (materials) => _buildBody(context, materials, s),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<MaterialSpec> materials, AppStrings s) {
    final unitLabel = _units == UnitSystem.metric ? 'mm' : 'in';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: s.sectionMaterial,
            child: _MaterialSelector(
              materials:    materials,
              selectedCode: _selectedMaterialCode,
              hint:         s.selectMaterial,
              chooseDots:   s.chooseDots,
              onChanged:    (code) => setState(() { _selectedMaterialCode = code; _result = null; }),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: s.sectionTool,
            child: Column(children: [
              _ToolTypeRow(
                selected: _toolTypeCode,
                onChanged: (v) => setState(() { _toolTypeCode = v; _result = null; }),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _NumericField(
                  label: '${s.labelDiameter} ($unitLabel)',
                  controller: _diameterCtrl,
                  onChanged: (v) => setState(() { _diameter = double.tryParse(v) ?? _diameter; _result = null; }),
                )),
                const SizedBox(width: 12),
                Expanded(child: _FluteSelector(
                  value:     _flutes,
                  label:     s.labelFlutes,
                  onChanged: (v) => setState(() { _flutes = v; _result = null; }),
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _SegmentRow<ToolMaterial>(
                  label: s.labelToolMaterial,
                  options: {
                    ToolMaterial.carbide: s.toolMaterialCarbide,
                    ToolMaterial.hss:     s.toolMaterialHss,
                  },
                  selected: _toolMat,
                  onChanged: (v) => setState(() { _toolMat = v; _result = null; }),
                )),
                const SizedBox(width: 12),
                Expanded(child: _SegmentRow<OperationType>(
                  label: s.labelOperation,
                  options: {
                    OperationType.roughing:  s.operationRough,
                    OperationType.finishing: s.operationFinish,
                  },
                  selected: _opType,
                  onChanged: (v) => setState(() { _opType = v; _result = null; }),
                )),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: s.sectionCutParams,
            child: Row(children: [
              Expanded(child: _NumericField(
                label: '${s.labelDoc} ($unitLabel)',
                controller: _docCtrl,
                onChanged: (v) => setState(() { _doc = double.tryParse(v) ?? _doc; _result = null; }),
              )),
              const SizedBox(width: 12),
              Expanded(child: _NumericField(
                label: '${s.labelWoc} ($unitLabel)',
                controller: _wocCtrl,
                onChanged: (v) => setState(() { _woc = double.tryParse(v) ?? _woc; _result = null; }),
              )),
            ]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedMaterialCode != null
                ? () => _calculate(materials)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(s.btnCalculate, style: const TextStyle(fontSize: 16)),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(result: _result!),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _saveToHistory(materials),
              icon:  const Icon(Icons.bookmark_add_outlined, size: 18),
              label: Text(s.historySave),
            ),
            const SizedBox(height: 8),
            _ProActionButtons(
              result:       _result!,
              material:     materials.firstWhere((m) => m.code == _selectedMaterialCode!),
              toolTypeCode: _toolTypeCode,
              diameter:     _diameter,
              flutes:       _flutes,
              units:        _units,
              operation:    _opType,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.2,
            )),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MaterialSelector extends StatelessWidget {
  final List<MaterialSpec> materials;
  final String? selectedCode;
  final String hint;
  final String chooseDots;
  final ValueChanged<String?> onChanged;
  const _MaterialSelector({
    required this.materials, this.selectedCode,
    required this.hint, required this.chooseDots, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: hint),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:         selectedCode,
          hint:          Text(chooseDots),
          isExpanded:    true,
          dropdownColor: AppColors.surfaceAlt,
          items: materials.map((m) => DropdownMenuItem(
            value: m.code,
            child: Text(m.name, overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ToolTypeRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _ToolTypeRow({required this.selected, required this.onChanged});

  static const _types = {
    'end_mill_2fl': '2fl EM',
    'end_mill_4fl': '4fl EM',
    'face_mill':    'Face',
    'drill_hss':    'Drill',
  };

  @override
  Widget build(BuildContext context) {
    return Row(children: _types.entries.map((e) => Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: () => onChanged(e.key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:        selected == e.key ? AppColors.primary : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(6),
            border:       Border.all(color: selected == e.key ? AppColors.primary : AppColors.border),
          ),
          child: Text(e.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      selected == e.key ? AppColors.background : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    ))).toList());
  }
}

class _NumericField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _NumericField({required this.label, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _FluteSelector extends StatelessWidget {
  final int value;
  final String label;
  final ValueChanged<int> onChanged;
  const _FluteSelector({required this.value, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value:         value,
          isExpanded:    true,
          dropdownColor: AppColors.surfaceAlt,
          items: [2, 3, 4, 5, 6].map((f) => DropdownMenuItem(value: f, child: Text('$f'))).toList(),
          onChanged:     (v) => onChanged(v!),
        ),
      ),
    );
  }
}

class _SegmentRow<T> extends StatelessWidget {
  final String label;
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;
  const _SegmentRow({required this.label, required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Row(children: options.entries.map((e) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GestureDetector(
            onTap: () => onChanged(e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color:        selected == e.key ? AppColors.primaryDim : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(6),
                border:       Border.all(color: selected == e.key ? AppColors.primary : AppColors.border),
              ),
              child: Text(e.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:   12,
                  color:      selected == e.key ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ))).toList()),
      ],
    );
  }
}

class _ResultCard extends ConsumerWidget {
  final CutParameters result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
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
              const Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
              const SizedBox(width: 8),
              Text(s.resultTitle, style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _ResultItem(label: s.resultRpm,         value: result.rpmFormatted,          icon: Icons.rotate_right)),
              Expanded(child: _ResultItem(label: s.resultFeedRate,    value: result.feedFormatted,          icon: Icons.arrow_forward)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _ResultItem(label: s.resultChipLoad,    value: result.chipLoadFormatted,      icon: Icons.grain)),
              Expanded(child: _ResultItem(label: s.resultMrr,         value: result.mrrFormatted,           icon: Icons.trending_up)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _ResultItem(label: s.resultCuttingSpeed, value: result.cuttingSpeedFormatted, icon: Icons.speed)),
              Expanded(child: _ResultItem(
                label: s.resultCoolant,
                value: result.coolantRequired ? s.coolantRequired : s.coolantOptional,
                icon: Icons.water_drop,
                valueColor: result.coolantRequired ? AppColors.infoBlue : AppColors.textSecondary,
              )),
            ]),
            if (result.materialNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text(result.materialNotes,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                )),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Pro Action Buttons ───────────────────────────────────────────────────────

class _ProActionButtons extends ConsumerWidget {
  final CutParameters result;
  final MaterialSpec  material;
  final String        toolTypeCode;
  final double        diameter;
  final int           flutes;
  final UnitSystem    units;
  final OperationType operation;
  const _ProActionButtons({
    required this.result,    required this.material,
    required this.toolTypeCode, required this.diameter,
    required this.flutes,    required this.units,
    required this.operation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s    = ref.watch(appStringsProvider);
    final tier = ref.watch(currentTierProvider);
    final isPro = tier.valueOrNull == 'pro' || tier.valueOrNull == 'team';

    return Column(children: [
      // Setup Sheet
      _ProButton(
        label:  s.setupSheetBtn,
        icon:   Icons.description_outlined,
        isPro:  isPro,
        proMsg: s.setupSheetProOnly,
        onTap:  () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => SetupSheetScreen(
            result:      result,
            material:    material,
            toolTypeCode: toolTypeCode,
            diameter:    diameter,
            flutes:      flutes,
            units:       units,
            operation:   operation,
          ),
        )),
        onUpgrade: () => context.push(RouteNames.subscription),
      ),
      const SizedBox(height: 8),
      // Tooling Recommendations
      _ProButton(
        label:  s.toolingBtn,
        icon:   Icons.build_circle_outlined,
        isPro:  isPro,
        proMsg: s.toolingProOnly,
        onTap:  () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ToolingRecsScreen(
            material:  material,
            operation: operation,
            diameter:  diameter,
            flutes:    flutes,
            units:     units,
          ),
        )),
        onUpgrade: () => context.push(RouteNames.subscription),
      ),
    ]);
  }
}

class _ProButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         isPro;
  final String       proMsg;
  final VoidCallback onTap;
  final VoidCallback onUpgrade;
  const _ProButton({
    required this.label,    required this.icon,
    required this.isPro,    required this.proMsg,
    required this.onTap,    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    if (isPro) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon:  Icon(icon, size: 16),
        label: Text(label),
      );
    }
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          ]),
          content: Text(proMsg,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () { Navigator.pop(context); onUpgrade(); },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Upgrade'),
            ),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:        AppColors.warningYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('PRO',
              style: TextStyle(fontSize: 9, color: AppColors.warningYellow, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const _ResultItem({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.bold,
            color:      valueColor ?? AppColors.primary,
            fontFamily: 'JetBrainsMono',
          )),
        ],
      ),
    );
  }
}
