import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/calc_widgets.dart';
import '../domain/arc_calculator.dart';

class ArcScreen extends ConsumerStatefulWidget {
  const ArcScreen({super.key});

  @override
  ConsumerState<ArcScreen> createState() => _ArcScreenState();
}

class _ArcScreenState extends ConsumerState<ArcScreen> {
  final _p = [
    [TextEditingController(text: '0'), TextEditingController(text: '0')],
    [TextEditingController(text: '10'), TextEditingController(text: '10')],
    [TextEditingController(text: '20'), TextEditingController(text: '0')],
  ];

  ArcResult? _result;

  @override
  void initState() {
    super.initState();
    _recalc();
  }

  @override
  void dispose() {
    for (final pair in _p) {
      pair[0].dispose();
      pair[1].dispose();
    }
    super.dispose();
  }

  ArcPoint _point(int i) => ArcPoint(
        double.tryParse(_p[i][0].text) ?? 0,
        double.tryParse(_p[i][1].text) ?? 0,
      );

  void _recalc() {
    setState(() {
      _result =
          ArcCalculator.threePoint(_point(0), _point(1), _point(2));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: Text(s.toolArc)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (r != null)
            AspectRatio(
              aspectRatio: 1.4,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: CustomPaint(
                  painter: _ArcPainter(
                      [_point(0), _point(1), _point(2)], r),
                ),
              ),
            ),
          const SizedBox(height: 16),
          CalcSectionCard(
            title: '3-point arc (X, Z)',
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  Row(children: [
                    SizedBox(
                        width: 28,
                        child: Text('P${i + 1}',
                            style: const TextStyle(
                                color: AppColors.textSecondary))),
                    Expanded(
                        child: CalcNumberField(
                            label: 'X',
                            controller: _p[i][0],
                            allowNegative: true,
                            onChanged: (_) => _recalc())),
                    const SizedBox(width: 12),
                    Expanded(
                        child: CalcNumberField(
                            label: 'Z',
                            controller: _p[i][1],
                            allowNegative: true,
                            onChanged: (_) => _recalc())),
                  ]),
                  if (i < 2) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (r == null)
            Text(s.gcodeRefNoResults,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary))
          else
            CalcResultCard(title: s.resCoordinates, tiles: [
              CalcResultTile(
                  label: 'Center X',
                  value: r.center.x.toStringAsFixed(4),
                  icon: Icons.gps_fixed),
              CalcResultTile(
                  label: 'Center Z',
                  value: r.center.z.toStringAsFixed(4),
                  icon: Icons.gps_fixed),
              CalcResultTile(
                  label: 'Radius',
                  value: r.radius.toStringAsFixed(4),
                  icon: Icons.radio_button_unchecked),
              CalcResultTile(
                  label: 'Sweep',
                  value: '${r.sweepAngle.toStringAsFixed(2)}°',
                  icon: Icons.rotate_left),
            ]),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final List<ArcPoint> pts;
  final ArcResult result;
  _ArcPainter(this.pts, this.result);

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 20.0;
    // Bounds covering the points and the circle.
    final xs = [...pts.map((p) => p.x), result.center.x + result.radius, result.center.x - result.radius];
    final zs = [...pts.map((p) => p.z), result.center.z + result.radius, result.center.z - result.radius];
    final minX = xs.reduce((a, b) => a < b ? a : b);
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    final minZ = zs.reduce((a, b) => a < b ? a : b);
    final maxZ = zs.reduce((a, b) => a > b ? a : b);
    final spanX = (maxX - minX).abs() < 1e-6 ? 1 : maxX - minX;
    final spanZ = (maxZ - minZ).abs() < 1e-6 ? 1 : maxZ - minZ;
    final scale =
        ((size.width - pad * 2) / spanX).clamp(0.0, double.infinity) <
                ((size.height - pad * 2) / spanZ)
            ? (size.width - pad * 2) / spanX
            : (size.height - pad * 2) / spanZ;

    Offset map(double x, double z) =>
        Offset(pad + (x - minX) * scale, size.height - pad - (z - minZ) * scale);

    final circlePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
        map(result.center.x, result.center.z), result.radius * scale, circlePaint);

    final ptPaint = Paint()..color = AppColors.warningYellow;
    for (final p in pts) {
      canvas.drawCircle(map(p.x, p.z), 4, ptPaint);
    }
    final cPaint = Paint()..color = AppColors.successGreen;
    canvas.drawCircle(map(result.center.x, result.center.z), 3, cPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => true;
}
