import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calc/units.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/calc_widgets.dart';

class ConvertersScreen extends ConsumerStatefulWidget {
  const ConvertersScreen({super.key});

  @override
  ConsumerState<ConvertersScreen> createState() => _ConvertersScreenState();
}

class _ConvertersScreenState extends ConsumerState<ConvertersScreen> {
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
          title: Text(s.toolConverters),
          actions: [
            CalcUnitToggle(
                units: _units, onChanged: (v) => setState(() => _units = v)),
          ],
          bottom: TabBar(
            tabs: [Tab(text: s.convTabSpeed), Tab(text: s.convTabFeed)],
          ),
        ),
        body: TabBarView(
          children: [
            _SpeedConverter(units: _units),
            _FeedConverter(units: _units),
          ],
        ),
      ),
    );
  }
}

/// SFM/Vc ↔ RPM, given a diameter.
class _SpeedConverter extends ConsumerStatefulWidget {
  final UnitSystem units;
  const _SpeedConverter({required this.units});

  @override
  ConsumerState<_SpeedConverter> createState() => _SpeedConverterState();
}

class _SpeedConverterState extends ConsumerState<_SpeedConverter> {
  bool _toRpm = true; // true: speed→rpm, false: rpm→speed
  double _dia = 10, _value = 100;
  final _diaCtrl = TextEditingController(text: '10');
  final _valCtrl = TextEditingController(text: '100');

  @override
  void dispose() {
    _diaCtrl.dispose();
    _valCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final isMetric = widget.units.isMetric;
    final u = widget.units.lengthLabel;
    final speedUnit = widget.units.cuttingSpeedLabel;

    String result;
    if (_toRpm) {
      final rpm = SpeedFormulas.rpm(
          cuttingSpeed: _value, diameter: _dia, isMetric: isMetric);
      result = '$rpm RPM';
    } else {
      final sp = SpeedFormulas.cuttingSpeed(
          rpm: _value.round(), diameter: _dia, isMetric: isMetric);
      result = '${sp.toStringAsFixed(1)} $speedUnit';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        CalcSegment<bool>(
          options: {true: '$speedUnit → RPM', false: 'RPM → $speedUnit'},
          selected: _toRpm,
          onChanged: (v) => setState(() => _toRpm = v),
        ),
        const SizedBox(height: 16),
        CalcNumberField(
            label: 'Ø ($u)',
            controller: _diaCtrl,
            onChanged: (v) => setState(() => _dia = double.tryParse(v) ?? _dia)),
        const SizedBox(height: 12),
        CalcNumberField(
            label: _toRpm ? 'Vc ($speedUnit)' : 'RPM',
            controller: _valCtrl,
            onChanged: (v) =>
                setState(() => _value = double.tryParse(v) ?? _value)),
        const SizedBox(height: 20),
        _BigResult(label: s.resultTitle, value: result),
      ],
    );
  }
}

/// feed/rev ↔ feed/min, given RPM.
class _FeedConverter extends ConsumerStatefulWidget {
  final UnitSystem units;
  const _FeedConverter({required this.units});

  @override
  ConsumerState<_FeedConverter> createState() => _FeedConverterState();
}

class _FeedConverterState extends ConsumerState<_FeedConverter> {
  bool _toPerMin = true; // fr→fpm or fpm→fr
  double _rpm = 1000, _value = 0.2;
  final _rpmCtrl = TextEditingController(text: '1000');
  final _valCtrl = TextEditingController(text: '0.2');

  @override
  void dispose() {
    _rpmCtrl.dispose();
    _valCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final perRev = widget.units.isMetric ? 'mm/rev' : 'in/rev';
    final perMin = widget.units.feedLabel;

    String result;
    if (_toPerMin) {
      final fpm =
          SpeedFormulas.feedPerMin(rpm: _rpm.round(), feedPerRev: _value);
      result = '${fpm.toStringAsFixed(1)} $perMin';
    } else {
      final fr =
          SpeedFormulas.feedPerRev(feedPerMin: _value, rpm: _rpm.round());
      result = '${fr.toStringAsFixed(4)} $perRev';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        CalcSegment<bool>(
          options: {true: '$perRev → $perMin', false: '$perMin → $perRev'},
          selected: _toPerMin,
          onChanged: (v) => setState(() => _toPerMin = v),
        ),
        const SizedBox(height: 16),
        CalcNumberField(
            label: 'RPM',
            controller: _rpmCtrl,
            onChanged: (v) => setState(() => _rpm = double.tryParse(v) ?? _rpm)),
        const SizedBox(height: 12),
        CalcNumberField(
            label: _toPerMin ? 'fr ($perRev)' : 'F ($perMin)',
            controller: _valCtrl,
            onChanged: (v) =>
                setState(() => _value = double.tryParse(v) ?? _value)),
        const SizedBox(height: 20),
        _BigResult(label: s.resultTitle, value: result),
      ],
    );
  }
}

class _BigResult extends StatelessWidget {
  final String label;
  final String value;
  const _BigResult({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: 'JetBrainsMono')),
        ],
      ),
    );
  }
}
