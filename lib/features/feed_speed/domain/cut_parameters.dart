// `UnitSystem` now lives in core/calc/units.dart and is re-exported here so the
// many existing imports of this file keep compiling unchanged.
import '../../../core/calc/units.dart';
export '../../../core/calc/units.dart' show UnitSystem, UnitSystemX, SpeedFormulas;

enum ToolMaterial { hss, carbide }

enum OperationType { roughing, finishing }

class CalculatorInput {
  final String materialCode;
  final String toolTypeCode;
  final double toolDiameter;
  final int flutes;
  final ToolMaterial toolMaterial;
  final OperationType operationType;
  final UnitSystem units;
  final double depthOfCut;
  final double widthOfCut;

  const CalculatorInput({
    required this.materialCode,
    required this.toolTypeCode,
    required this.toolDiameter,
    required this.flutes,
    required this.toolMaterial,
    required this.operationType,
    required this.units,
    required this.depthOfCut,
    required this.widthOfCut,
  });
}

class CutParameters {
  final int rpm;
  final double feedRatePerMin;
  final double chipLoad;
  final double mrr;
  final double cuttingSpeed;
  final UnitSystem units;
  final String materialNotes;
  final bool coolantRequired;

  const CutParameters({
    required this.rpm,
    required this.feedRatePerMin,
    required this.chipLoad,
    required this.mrr,
    required this.cuttingSpeed,
    required this.units,
    required this.materialNotes,
    required this.coolantRequired,
  });

  String get rpmFormatted => rpm.toString();

  String get feedFormatted {
    final unit = units == UnitSystem.metric ? 'mm/min' : 'in/min';
    return '${feedRatePerMin.toStringAsFixed(1)} $unit';
  }

  String get chipLoadFormatted {
    final unit = units == UnitSystem.metric ? 'mm' : 'in';
    return '${chipLoad.toStringAsFixed(4)} $unit';
  }

  String get mrrFormatted {
    final unit = units == UnitSystem.metric ? 'cm³/min' : 'in³/min';
    return '${mrr.toStringAsFixed(2)} $unit';
  }

  String get cuttingSpeedFormatted {
    final unit = units == UnitSystem.metric ? 'm/min' : 'SFM';
    return '${cuttingSpeed.toStringAsFixed(0)} $unit';
  }
}
