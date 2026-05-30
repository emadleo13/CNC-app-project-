import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/calc_widgets.dart';
import '../domain/gcode_generator.dart';

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
          bottom: const TabBar(tabs: [
            Tab(text: 'G76 Thread'),
            Tab(text: 'Drill BCD'),
          ]),
        ),
        body: const TabBarView(children: [_ThreadTab(), _DrillTab()]),
      ),
    );
  }
}

class _ThreadTab extends ConsumerStatefulWidget {
  const _ThreadTab();
  @override
  ConsumerState<_ThreadTab> createState() => _ThreadTabState();
}

class _ThreadTabState extends ConsumerState<_ThreadTab> {
  double _d = 20, _pitch = 1.5, _zEnd = -25;
  final double _first = 0.3;
  String? _program;
  final _dCtrl = TextEditingController(text: '20');
  final _pCtrl = TextEditingController(text: '1.5');
  final _zCtrl = TextEditingController(text: '-25');

  @override
  void dispose() {
    _dCtrl.dispose();
    _pCtrl.dispose();
    _zCtrl.dispose();
    super.dispose();
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
              Expanded(
                  child: CalcNumberField(
                      label: 'Major Ø',
                      controller: _dCtrl,
                      onChanged: (v) => _d = double.tryParse(v) ?? _d)),
              const SizedBox(width: 12),
              Expanded(
                  child: CalcNumberField(
                      label: 'Pitch',
                      controller: _pCtrl,
                      onChanged: (v) => _pitch = double.tryParse(v) ?? _pitch)),
            ]),
            const SizedBox(height: 12),
            CalcNumberField(
                label: 'Z end',
                controller: _zCtrl,
                allowNegative: true,
                onChanged: (v) => _zEnd = double.tryParse(v) ?? _zEnd),
          ]),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => setState(() => _program = GcodeGenerator.threadG76(
                majorDiameter: _d,
                pitch: _pitch,
                zEnd: _zEnd,
                firstDepth: _first,
              )),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(s.btnGenerate, style: const TextStyle(fontSize: 16)),
          ),
        ),
        if (_program != null) ...[
          const SizedBox(height: 16),
          _ProgramView(program: _program!),
        ],
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
  double _bcd = 100, _z = -15, _feed = 120;
  final double _r = 2;
  String? _program;
  final _bcdCtrl = TextEditingController(text: '100');
  final _zCtrl = TextEditingController(text: '-15');
  final _feedCtrl = TextEditingController(text: '120');

  @override
  void dispose() {
    _bcdCtrl.dispose();
    _zCtrl.dispose();
    _feedCtrl.dispose();
    super.dispose();
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
              options: const {'G81': 'G81', 'G83': 'G83 peck'},
              selected: _cycle,
              onChanged: (v) => setState(() => _cycle = v),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Holes'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _holes,
                      isExpanded: true,
                      items: [for (var i = 2; i <= 24; i++) i]
                          .map((h) =>
                              DropdownMenuItem(value: h, child: Text('$h')))
                          .toList(),
                      onChanged: (v) => setState(() => _holes = v ?? 6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: CalcNumberField(
                      label: 'BCD Ø',
                      controller: _bcdCtrl,
                      onChanged: (v) => _bcd = double.tryParse(v) ?? _bcd)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: CalcNumberField(
                      label: 'Z depth',
                      controller: _zCtrl,
                      allowNegative: true,
                      onChanged: (v) => _z = double.tryParse(v) ?? _z)),
              const SizedBox(width: 12),
              Expanded(
                  child: CalcNumberField(
                      label: 'Feed',
                      controller: _feedCtrl,
                      onChanged: (v) => _feed = double.tryParse(v) ?? _feed)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () =>
              setState(() => _program = GcodeGenerator.boltCircleDrill(
                    cycle: _cycle,
                    holes: _holes,
                    boltCircleDiameter: _bcd,
                    centerX: 0,
                    centerY: 0,
                    startAngleDeg: 0,
                    rPlane: _r,
                    zDepth: _z,
                    feed: _feed,
                  )),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(s.btnGenerate, style: const TextStyle(fontSize: 16)),
          ),
        ),
        if (_program != null) ...[
          const SizedBox(height: 16),
          _ProgramView(program: _program!),
        ],
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
    return Container(
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
              style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.gcodeValue)),
        ],
      ),
    );
  }
}
