import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/calc_widgets.dart';
import '../domain/taper_calculator.dart';

class TaperScreen extends ConsumerStatefulWidget {
  const TaperScreen({super.key});

  @override
  ConsumerState<TaperScreen> createState() => _TaperScreenState();
}

class _TaperScreenState extends ConsumerState<TaperScreen> {
  double _d1 = 50, _d2 = 30, _len = 40, _noseR = 0.8;
  TaperResult? _result;
  final _d1Ctrl = TextEditingController(text: '50');
  final _d2Ctrl = TextEditingController(text: '30');
  final _lenCtrl = TextEditingController(text: '40');
  final _rCtrl = TextEditingController(text: '0.8');

  @override
  void initState() {
    super.initState();
    _recalc();
  }

  @override
  void dispose() {
    _d1Ctrl.dispose();
    _d2Ctrl.dispose();
    _lenCtrl.dispose();
    _rCtrl.dispose();
    super.dispose();
  }

  void _recalc() {
    setState(() {
      _result = TaperCalculator.solve(
          d1: _d1, d2: _d2, length: _len, noseR: _noseR);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: Text(s.toolTaper)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          AspectRatio(
            aspectRatio: 2,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: CustomPaint(painter: _TaperPainter(_d1, _d2, _len)),
            ),
          ),
          const SizedBox(height: 16),
          CalcSectionCard(
            title: s.secInputs,
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: CalcNumberField(
                        label: 'D1 (Ø)',
                        controller: _d1Ctrl,
                        onChanged: (v) {
                          _d1 = double.tryParse(v) ?? _d1;
                          _recalc();
                        })),
                const SizedBox(width: 12),
                Expanded(
                    child: CalcNumberField(
                        label: 'D2 (Ø)',
                        controller: _d2Ctrl,
                        onChanged: (v) {
                          _d2 = double.tryParse(v) ?? _d2;
                          _recalc();
                        })),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: CalcNumberField(
                        label: 'L (axial)',
                        controller: _lenCtrl,
                        onChanged: (v) {
                          _len = double.tryParse(v) ?? _len;
                          _recalc();
                        })),
                const SizedBox(width: 12),
                Expanded(
                    child: CalcNumberField(
                        label: 'Nose R',
                        controller: _rCtrl,
                        onChanged: (v) {
                          _noseR = double.tryParse(v) ?? _noseR;
                          _recalc();
                        })),
              ]),
            ]),
          ),
          if (r != null && r.noseRWarning) ...[
            const SizedBox(height: 12),
            _WarnBanner(text: s.taperWarnNoseR),
          ],
          if (r != null) ...[
            const SizedBox(height: 16),
            CalcResultCard(title: s.resCoordinates, tiles: [
              CalcResultTile(
                  label: 'Angle / axis',
                  value: '${r.angleFromAxis.toStringAsFixed(3)}°',
                  icon: Icons.architecture),
              CalcResultTile(
                  label: 'Included',
                  value: '${r.includedAngle.toStringAsFixed(3)}°',
                  icon: Icons.open_in_full),
              CalcResultTile(
                  label: 'Slant length',
                  value: r.slantLength.toStringAsFixed(3),
                  icon: Icons.show_chart),
              CalcResultTile(
                  label: 'Taper ratio',
                  value: r.taperRatio.isInfinite
                      ? '—'
                      : '1 : ${r.taperRatio.toStringAsFixed(2)}',
                  icon: Icons.percent),
              if (r.noseRSetback != null)
                CalcResultTile(
                    label: 'Nose-R Z setback',
                    value: r.noseRSetback!.toStringAsFixed(4),
                    icon: Icons.adjust),
            ]),
          ],
        ],
      ),
    );
  }
}

class _WarnBanner extends StatelessWidget {
  final String text;
  const _WarnBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningYellow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warningYellow),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded,
            color: AppColors.warningYellow, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.warningYellow, fontSize: 12))),
      ]),
    );
  }
}

class _TaperPainter extends CustomPainter {
  final double d1, d2, len;
  _TaperPainter(this.d1, this.d2, this.len);

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 24.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final maxD = [d1, d2, 1.0].reduce((a, b) => a > b ? a : b);
    final scaleX = len > 0 ? w / len : 1.0;
    final scaleY = (h / maxD).clamp(0.0, double.infinity);
    final cz = size.height / 2;

    double px(double z) => pad + z * scaleX;
    double py(double diameter, double sign) => cz - sign * diameter * scaleY / 2;

    final profile = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final axis = Paint()
      ..color = AppColors.textMuted
      ..strokeWidth = 1;

    // Centreline
    canvas.drawLine(Offset(pad, cz), Offset(pad + w, cz), axis);

    // Mirror the taper profile above and below the centreline.
    for (final sign in [1.0, -1.0]) {
      canvas.drawLine(
          Offset(px(0), py(d1, sign)), Offset(px(len), py(d2, sign)), profile);
      canvas.drawLine(Offset(px(0), cz), Offset(px(0), py(d1, sign)), profile);
      canvas.drawLine(
          Offset(px(len), cz), Offset(px(len), py(d2, sign)), profile);
    }
  }

  @override
  bool shouldRepaint(covariant _TaperPainter old) =>
      old.d1 != d1 || old.d2 != d2 || old.len != len;
}
