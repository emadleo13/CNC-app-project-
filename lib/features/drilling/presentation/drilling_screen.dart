import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calc/units.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/calc_widgets.dart';
import '../domain/drilling_calculator.dart';

class DrillingScreen extends ConsumerStatefulWidget {
  const DrillingScreen({super.key});

  @override
  ConsumerState<DrillingScreen> createState() => _DrillingScreenState();
}

class _DrillingScreenState extends ConsumerState<DrillingScreen> {
  late UnitSystem _units;

  @override
  void initState() {
    super.initState();
    _units = ref.read(defaultUnitsProvider) == 'imperial'
        ? UnitSystem.imperial
        : UnitSystem.metric;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.toolDrilling),
          actions: [
            CalcUnitToggle(
                units: _units, onChanged: (v) => setState(() => _units = v)),
          ],
          bottom: TabBar(tabs: [
            Tab(text: s.catDrilling.split(' ').first),
            Tab(text: s.sectionTapDrill),
          ]),
        ),
        body: TabBarView(children: [
          _DrillTab(units: _units),
          _TapTab(units: _units),
        ]),
      ),
    );
  }
}

class _DrillTab extends ConsumerStatefulWidget {
  final UnitSystem units;
  const _DrillTab({required this.units});

  @override
  ConsumerState<_DrillTab> createState() => _DrillTabState();
}

class _DrillTabState extends ConsumerState<_DrillTab> {
  double _dia = 8, _vc = 30, _fr = 0.1, _depth = 30, _angle = 118;
  DrillingResult? _result;
  final _diaCtrl = TextEditingController(text: '8');
  final _vcCtrl = TextEditingController(text: '30');
  final _frCtrl = TextEditingController(text: '0.1');
  final _depthCtrl = TextEditingController(text: '30');

  @override
  void dispose() {
    _diaCtrl.dispose();
    _vcCtrl.dispose();
    _frCtrl.dispose();
    _depthCtrl.dispose();
    super.dispose();
  }

  void _calc() {
    setState(() {
      _result = DrillingCalculator.drilling(DrillingInput(
        diameter: _dia,
        cuttingSpeed: _vc,
        feedPerRev: _fr,
        holeDepth: _depth,
        pointAngle: _angle,
        units: widget.units,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final u = widget.units.lengthLabel;
    final vcUnit = widget.units.cuttingSpeedLabel;
    final frUnit = widget.units.isMetric ? 'mm/rev' : 'in/rev';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                      label: 'Depth ($u)',
                      controller: _depthCtrl,
                      onChanged: (v) => _depth = double.tryParse(v) ?? _depth)),
            ]),
            const SizedBox(height: 12),
            CalcSegment<double>(
              label: 'Point angle',
              options: {118.0: '118°', 135.0: '135°', 90.0: '90°'},
              selected: _angle,
              onChanged: (v) => setState(() => _angle = v),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: _calc,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(s.btnCalculate, style: const TextStyle(fontSize: 16)),
            )),
        if (_result != null) ...[
          const SizedBox(height: 16),
          CalcResultCard(title: s.resultTitle, tiles: [
            CalcResultTile(
                label: s.resultRpm,
                value: _result!.rpmFormatted,
                icon: Icons.rotate_right),
            CalcResultTile(
                label: s.resFeedPerMin,
                value: _result!.feedFormatted,
                icon: Icons.arrow_downward),
            CalcResultTile(
                label: s.resPointLength,
                value: _result!.pointLengthFormatted,
                icon: Icons.details),
            CalcResultTile(
                label: s.resCutTime,
                value: _result!.cutTimeFormatted,
                icon: Icons.timer_outlined),
          ]),
        ],
      ],
    );
  }
}

class _TapTab extends ConsumerStatefulWidget {
  final UnitSystem units;
  const _TapTab({required this.units});

  @override
  ConsumerState<_TapTab> createState() => _TapTabState();
}

class _TapTabState extends ConsumerState<_TapTab> {
  double _major = 6, _pitch = 1.0, _pct = 75;
  final _majorCtrl = TextEditingController(text: '6');
  final _pitchCtrl = TextEditingController(text: '1.0');

  @override
  void dispose() {
    _majorCtrl.dispose();
    _pitchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final u = widget.units.lengthLabel;
    final isMetric = widget.units.isMetric;
    // metric: pitch in mm; imperial: field is TPI → convert to inch pitch.
    final pitchInUnits = isMetric ? _pitch : (_pitch > 0 ? 1 / _pitch : 0.0);
    final tapDrill = DrillingCalculator.tapDrill(
      majorDiameter: _major,
      pitch: pitchInUnits,
      threadPercent: _pct,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        CalcSectionCard(
          title: s.sectionTapDrill,
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: CalcNumberField(
                      label: 'Major Ø ($u)',
                      controller: _majorCtrl,
                      onChanged: (v) =>
                          setState(() => _major = double.tryParse(v) ?? _major))),
              const SizedBox(width: 12),
              Expanded(
                  child: CalcNumberField(
                      label: isMetric ? 'Pitch (mm)' : 'TPI',
                      controller: _pitchCtrl,
                      onChanged: (v) =>
                          setState(() => _pitch = double.tryParse(v) ?? _pitch))),
            ]),
            const SizedBox(height: 12),
            CalcSegment<double>(
              label: 'Thread engagement',
              options: {60.0: '60%', 75.0: '75%', 100.0: '100%'},
              selected: _pct,
              onChanged: (v) => setState(() => _pct = v),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        CalcResultCard(title: s.resultTitle, tiles: [
          CalcResultTile(
              label: s.resTapDrill,
              value:
                  '${tapDrill.toStringAsFixed(isMetric ? 2 : 4)} $u',
              icon: Icons.adjust),
        ]),
      ],
    );
  }
}
