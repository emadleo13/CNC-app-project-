import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/calc_widgets.dart';
import '../domain/true_position_calculator.dart';

class TruePositionScreen extends ConsumerStatefulWidget {
  const TruePositionScreen({super.key});

  @override
  ConsumerState<TruePositionScreen> createState() =>
      _TruePositionScreenState();
}

class _TruePositionScreenState extends ConsumerState<TruePositionScreen> {
  double _tx = 25, _ty = 25, _mx = 25.05, _my = 24.97, _tol = 0.2;
  double _actual = 10.1, _mc = 10.0;
  MaterialCondition _cond = MaterialCondition.mmc;

  final _txCtrl = TextEditingController(text: '25');
  final _tyCtrl = TextEditingController(text: '25');
  final _mxCtrl = TextEditingController(text: '25.05');
  final _myCtrl = TextEditingController(text: '24.97');
  final _tolCtrl = TextEditingController(text: '0.2');
  final _actualCtrl = TextEditingController(text: '10.1');
  final _mcCtrl = TextEditingController(text: '10.0');

  @override
  void dispose() {
    for (final c in [
      _txCtrl,
      _tyCtrl,
      _mxCtrl,
      _myCtrl,
      _tolCtrl,
      _actualCtrl,
      _mcCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final r = TruePositionCalculator.calculate(
      trueX: _tx,
      trueY: _ty,
      measuredX: _mx,
      measuredY: _my,
      statedTolerance: _tol,
      condition: _cond,
      actualSize: _actual,
      mcSize: _mc,
    );

    return Scaffold(
      appBar: AppBar(title: Text(s.toolTruePosition)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          CalcSectionCard(
            title: 'True / Measured (X, Y)',
            child: Column(children: [
              Row(children: [
                Expanded(child: _f('True X', _txCtrl, (v) => _tx = v)),
                const SizedBox(width: 12),
                Expanded(child: _f('True Y', _tyCtrl, (v) => _ty = v)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _f('Meas X', _mxCtrl, (v) => _mx = v)),
                const SizedBox(width: 12),
                Expanded(child: _f('Meas Y', _myCtrl, (v) => _my = v)),
              ]),
              const SizedBox(height: 12),
              _f('Position tolerance', _tolCtrl, (v) => _tol = v),
            ]),
          ),
          const SizedBox(height: 12),
          CalcSectionCard(
            title: 'Bonus tolerance',
            child: Column(children: [
              CalcSegment<MaterialCondition>(
                options: const {
                  MaterialCondition.rfs: 'RFS',
                  MaterialCondition.mmc: 'MMC',
                  MaterialCondition.lmc: 'LMC',
                },
                selected: _cond,
                onChanged: (v) => setState(() => _cond = v),
              ),
              if (_cond != MaterialCondition.rfs) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _f('Actual size', _actualCtrl, (v) => _actual = v)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _f(
                          _cond == MaterialCondition.mmc ? 'MMC size' : 'LMC size',
                          _mcCtrl,
                          (v) => _mc = v)),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          CalcResultCard(
            title: s.resultTitle,
            tiles: [
              CalcResultTile(
                  label: s.resDeviation,
                  value:
                      '${r.deviationX.toStringAsFixed(3)}, ${r.deviationY.toStringAsFixed(3)}',
                  icon: Icons.open_with),
              CalcResultTile(
                  label: 'True position Ø',
                  value: r.truetPosition.toStringAsFixed(4),
                  icon: Icons.gps_fixed),
              CalcResultTile(
                  label: 'Bonus',
                  value: r.bonus.toStringAsFixed(4),
                  icon: Icons.add_circle_outline),
              CalcResultTile(
                  label: 'Allowed',
                  value: r.totalTolerance.toStringAsFixed(4),
                  icon: Icons.rule),
            ],
            footer: Row(children: [
              Icon(
                  r.withinTolerance
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: r.withinTolerance
                      ? AppColors.successGreen
                      : AppColors.errorRed,
                  size: 18),
              const SizedBox(width: 8),
              Text(
                r.withinTolerance ? 'WITHIN TOLERANCE' : 'OUT OF TOLERANCE',
                style: TextStyle(
                    color: r.withinTolerance
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                    fontWeight: FontWeight.bold),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _f(String label, TextEditingController c, ValueChanged<double> set) {
    return CalcNumberField(
      label: label,
      controller: c,
      allowNegative: true,
      onChanged: (v) {
        final d = double.tryParse(v);
        if (d != null) setState(() => set(d));
      },
    );
  }
}
