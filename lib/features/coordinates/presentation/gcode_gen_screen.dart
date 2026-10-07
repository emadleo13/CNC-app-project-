import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/calc_widgets.dart';
import '../domain/gcode_generator.dart';

String _problemText(AppStrings s, GenProblem p) => switch (p) {
      GenProblem.pitch    => s.genErrPitch,
      GenProblem.diameter => s.genErrDiameter,
      GenProblem.zEnd     => s.genErrZEnd,
      GenProblem.holes    => s.genErrHoles,
      GenProblem.bcd      => s.genErrBcd,
      GenProblem.planes   => s.genErrPlanes,
      GenProblem.feed     => s.genErrFeed,
      GenProblem.rpm      => s.genErrRpm,
      GenProblem.peck     => s.genErrPeck,
      GenProblem.tool     => s.genErrTool,
    };

/// A number field's value; the field's formatter has already normalised it.
double _num(TextEditingController c) => double.tryParse(c.text) ?? double.nan;
int _int(TextEditingController c) => double.tryParse(c.text)?.round() ?? -1;

class GcodeGenScreen extends ConsumerWidget {
  const GcodeGenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.toolGcodeGen),
          bottom: TabBar(tabs: [
            Tab(text: s.genThreadTab),
            Tab(text: s.genDrillTab),
          ]),
        ),
        body: const TabBarView(children: [_ThreadTab(), _DrillTab()]),
      ),
    );
  }
}

/// Either the generated program or what is wrong with the inputs.
class _Output extends StatelessWidget {
  final String? program;
  final List<GenProblem> problems;
  final AppStrings s;
  const _Output({required this.program, required this.problems, required this.s});

  @override
  Widget build(BuildContext context) {
    if (problems.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final p in problems)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.error_outline, size: 15, color: AppColors.errorRed),
                const SizedBox(width: 6),
                Expanded(child: Text(_problemText(s, p), style: const TextStyle(fontSize: 13))),
              ]),
            ),
        ]),
      );
    }
    final p = program;
    if (p == null) return const SizedBox.shrink();
    return _ProgramView(program: p);
  }
}

class _ThreadTab extends ConsumerStatefulWidget {
  const _ThreadTab();
  @override
  ConsumerState<_ThreadTab> createState() => _ThreadTabState();
}

class _ThreadTabState extends ConsumerState<_ThreadTab> {
  final _dCtrl = TextEditingController(text: '20');
  final _pCtrl = TextEditingController(text: '1.5');
  final _zCtrl = TextEditingController(text: '-25');
  final _toolCtrl = TextEditingController(text: '1');
  final _rpmCtrl = TextEditingController(text: '800');
  String? _program;
  List<GenProblem> _problems = const [];

  @override
  void dispose() {
    for (final c in [_dCtrl, _pCtrl, _zCtrl, _toolCtrl, _rpmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _generate() {
    final d = _num(_dCtrl), p = _num(_pCtrl), z = _num(_zCtrl);
    final tool = _int(_toolCtrl), rpm = _int(_rpmCtrl);
    final problems = GcodeGenerator.checkThread(
        majorDiameter: d, pitch: p, zEnd: z, tool: tool, rpm: rpm);
    setState(() {
      _problems = problems;
      _program = problems.isEmpty
          ? GcodeGenerator.threadG76(majorDiameter: d, pitch: p, zEnd: z, tool: tool, rpm: rpm)
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        CalcSectionCard(
          title: s.secInputs,
          child: Column(children: [
            Row(children: [
              Expanded(child: CalcNumberField(label: s.genMajorDia, controller: _dCtrl, onChanged: (_) {})),
              const SizedBox(width: 12),
              Expanded(child: CalcNumberField(label: s.genPitch, controller: _pCtrl, onChanged: (_) {})),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: CalcNumberField(label: s.genZEnd, controller: _zCtrl,
                  allowNegative: true, onChanged: (_) {})),
              const SizedBox(width: 12),
              Expanded(child: CalcNumberField(label: s.genTool, controller: _toolCtrl, onChanged: (_) {})),
            ]),
            const SizedBox(height: 12),
            CalcNumberField(label: s.genRpm, controller: _rpmCtrl, onChanged: (_) {}),
          ]),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _generate,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(s.btnGenerate, style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        _Output(program: _program, problems: _problems, s: s),
      ],
    );
  }
}

class _DrillTab extends ConsumerStatefulWidget {
  const _DrillTab();
  @override
  ConsumerState<_DrillTab> createState() => _DrillTabState();
}

class _DrillTabState extends ConsumerState<_DrillTab> {
  String _cycle = 'G83';
  int _holes = 6;
  final _bcdCtrl = TextEditingController(text: '100');
  final _angleCtrl = TextEditingController(text: '0');
  final _zCtrl = TextEditingController(text: '-15');
  final _rCtrl = TextEditingController(text: '2');
  final _clearCtrl = TextEditingController(text: '25');
  final _peckCtrl = TextEditingController(text: '3');
  final _feedCtrl = TextEditingController(text: '120');
  final _toolCtrl = TextEditingController(text: '1');
  final _rpmCtrl = TextEditingController(text: '1000');
  String? _program;
  List<GenProblem> _problems = const [];

  @override
  void dispose() {
    for (final c in [_bcdCtrl, _angleCtrl, _zCtrl, _rCtrl, _clearCtrl, _peckCtrl,
        _feedCtrl, _toolCtrl, _rpmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _generate() {
    final bcd = _num(_bcdCtrl), angle = _num(_angleCtrl), z = _num(_zCtrl);
    final r = _num(_rCtrl), clear = _num(_clearCtrl), peck = _num(_peckCtrl);
    final feed = _num(_feedCtrl);
    final tool = _int(_toolCtrl), rpm = _int(_rpmCtrl);
    final problems = GcodeGenerator.checkBoltCircle(
      cycle: _cycle, holes: _holes, boltCircleDiameter: bcd, rPlane: r,
      zDepth: z, feed: feed, peck: peck, clearanceZ: clear, tool: tool, rpm: rpm,
    );
    setState(() {
      _problems = problems;
      _program = problems.isEmpty
          ? GcodeGenerator.boltCircleDrill(
              cycle: _cycle, holes: _holes, boltCircleDiameter: bcd,
              centerX: 0, centerY: 0, startAngleDeg: angle.isNaN ? 0 : angle,
              rPlane: r, zDepth: z, feed: feed, peck: peck,
              clearanceZ: clear, tool: tool, rpm: rpm,
            )
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        CalcSectionCard(
          title: s.secInputs,
          child: Column(children: [
            CalcSegment<String>(
              options: const {'G81': 'G81', 'G83': 'G83 Q'},
              selected: _cycle,
              onChanged: (v) => setState(() => _cycle = v),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(labelText: s.genHoles),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _holes,
                      isExpanded: true,
                      items: [for (var i = 2; i <= 24; i++) i]
                          .map((h) => DropdownMenuItem(value: h, child: Text('$h')))
                          .toList(),
                      onChanged: (v) => setState(() => _holes = v ?? 6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: CalcNumberField(label: s.genBcd, controller: _bcdCtrl, onChanged: (_) {})),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: CalcNumberField(label: s.genDepth, controller: _zCtrl,
                  allowNegative: true, onChanged: (_) {})),
              const SizedBox(width: 12),
              Expanded(child: CalcNumberField(label: s.genRPlane, controller: _rCtrl,
                  allowNegative: true, onChanged: (_) {})),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: CalcNumberField(label: s.genClearance, controller: _clearCtrl,
                  allowNegative: true, onChanged: (_) {})),
              const SizedBox(width: 12),
              Expanded(child: _cycle == 'G83'
                  ? CalcNumberField(label: s.genPeck, controller: _peckCtrl, onChanged: (_) {})
                  : CalcNumberField(label: s.genStartAngle, controller: _angleCtrl,
                      allowNegative: true, onChanged: (_) {})),
            ]),
            if (_cycle == 'G83') ...[
              const SizedBox(height: 12),
              CalcNumberField(label: s.genStartAngle, controller: _angleCtrl,
                  allowNegative: true, onChanged: (_) {}),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: CalcNumberField(label: s.genFeed, controller: _feedCtrl, onChanged: (_) {})),
              const SizedBox(width: 12),
              Expanded(child: CalcNumberField(label: s.genTool, controller: _toolCtrl, onChanged: (_) {})),
            ]),
            const SizedBox(height: 12),
            CalcNumberField(label: s.genRpm, controller: _rpmCtrl, onChanged: (_) {}),
          ]),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _generate,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(s.btnGenerate, style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        _Output(program: _program, problems: _problems, s: s),
      ],
    );
  }
}

class _ProgramView extends ConsumerWidget {
  final String program;
  const _ProgramView({required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Shown with every program: these are starting points, not proven code.
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.warningYellow.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warningYellow.withValues(alpha: 0.35)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warningYellow),
          const SizedBox(width: 8),
          Expanded(child: Text(s.genVerifyWarning,
            style: const TextStyle(fontSize: 12.5, height: 1.45))),
        ]),
      ),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(s.resProgram.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: program));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(s.gcodeCopied),
                        duration: const Duration(seconds: 1)),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(s.btnCopy),
              ),
            ]),
            const SizedBox(height: 8),
            SelectableText(program,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.gcodeValue)),
          ],
        ),
      ),
    ]);
  }
}
