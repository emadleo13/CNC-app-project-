import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calc/units.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/calc_widgets.dart';
import '../domain/turning_calculator.dart';

class TurningScreen extends ConsumerStatefulWidget {
  const TurningScreen({super.key});

  @override
  ConsumerState<TurningScreen> createState() => _TurningScreenState();
}

class _TurningScreenState extends ConsumerState<TurningScreen> {
  late UnitSystem _units;
  double _dia = 50, _vc = 200, _fr = 0.2, _len = 100, _ap = 2;
  int _passes = 1;
  TurningResult? _result;

  final _diaCtrl = TextEditingController(text: '50');
  final _vcCtrl = TextEditingController(text: '200');
  final _frCtrl = TextEditingController(text: '0.2');
  final _lenCtrl = TextEditingController(text: '100');
  final _apCtrl = TextEditingController(text: '2');

  @override
  void initState() {
    super.initState();
    _units = ref.read(defaultUnitsProvider) == 'imperial'
        ? UnitSystem.imperial
        : UnitSystem.metric;
  }

  @override
  void dispose() {
    _diaCtrl.dispose();
    _vcCtrl.dispose();
    _frCtrl.dispose();
    _lenCtrl.dispose();
    _apCtrl.dispose();
    super.dispose();
  }

  void _calc() {
    final r = TurningCalculator.calculate(TurningInput(
      workDiameter: _dia,
      cuttingSpeed: _vc,
      feedPerRev: _fr,
      cutLength: _len,
      depthOfCut: _ap,
      passes: _passes,
      units: _units,
    ));
    setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final u = _units.lengthLabel;
    final vcUnit = _units.cuttingSpeedLabel;
    final frUnit = _units.isMetric ? 'mm/rev' : 'in/rev';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.toolTurning),
        actions: [
          CalcUnitToggle(
            units: _units,
            onChanged: (v) => setState(() {
              _units = v;
              _result = null;
            }),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          CalcSectionCard(
            title: s.secInputs,
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: CalcNumberField(
                        label: 'Ø ($u)',
                        controller: _diaCtrl,
                        onChanged: (v) => _dia = double.tryParse(v) ?? _dia)),
                const SizedBox(width: 12),
                Expanded(
                    child: CalcNumberField(
                        label: 'Vc ($vcUnit)',
                        controller: _vcCtrl,
                        onChanged: (v) => _vc = double.tryParse(v) ?? _vc)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: CalcNumberField(
                        label: 'fr ($frUnit)',
                        controller: _frCtrl,
                        onChanged: (v) => _fr = double.tryParse(v) ?? _fr)),
                const SizedBox(width: 12),
                Expanded(
                    child: CalcNumberField(
                        label: 'ap ($u)',
                        controller: _apCtrl,
                        onChanged: (v) => _ap = double.tryParse(v) ?? _ap)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: CalcNumberField(
                        label: 'L ($u)',
                        controller: _lenCtrl,
                        onChanged: (v) => _len = double.tryParse(v) ?? _len)),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Passes'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _passes,
                        isExpanded: true,
                        items: [for (var i = 1; i <= 20; i++) i]
                            .map((p) =>
                                DropdownMenuItem(value: p, child: Text('$p')))
                            .toList(),
                        onChanged: (v) => setState(() => _passes = v ?? 1),
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _calc,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(s.btnCalculate, style: const TextStyle(fontSize: 16)),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            CalcResultCard(
              title: s.resultTitle,
              tiles: [
                CalcResultTile(
                    label: s.resultRpm,
                    value: _result!.rpmFormatted,
                    icon: Icons.rotate_right),
                CalcResultTile(
                    label: s.resFeedPerMin,
                    value: _result!.feedFormatted,
                    icon: Icons.arrow_forward),
                CalcResultTile(
                    label: s.resCutTime,
                    value: _result!.cutTimeFormatted,
                    icon: Icons.timer_outlined),
                CalcResultTile(
                    label: s.resultMrr,
                    value: _result!.mrrFormatted,
                    icon: Icons.trending_up),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
