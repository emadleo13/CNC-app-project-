import 'dart:math' as math;
import '../material_spec.dart';
import '../cut_parameters.dart';

class MillingCalculator {
  static CutParameters? calculate({
    required CalculatorInput input,
    required MaterialSpec material,
  }) {
    if (input.toolDiameter <= 0) return null;
    final isMetric = input.units == UnitSystem.metric;
    final speeds = isMetric ? material.cuttingSpeedsMetric : material.cuttingSpeedsImperial;

    final cuttingSpeed = _selectCuttingSpeed(speeds, input.toolMaterial, input.operationType);
    final rpm = _calculateRpm(cuttingSpeed, input.toolDiameter, isMetric);
    final baseChipLoad = material.chipLoadFactors.forToolCode(input.toolTypeCode);
    final chipLoad = isMetric ? baseChipLoad * 25.4 : baseChipLoad;
    final feedRate = rpm * input.flutes * chipLoad;

    final doc = input.depthOfCut;
    final woc = input.widthOfCut;
    final mrr = _calculateMrr(woc, doc, feedRate, isMetric);

    return CutParameters(
      rpm:             rpm,
      feedRatePerMin:  feedRate,
      chipLoad:        chipLoad,
      mrr:             mrr,
      cuttingSpeed:    cuttingSpeed,
      units:           input.units,
      materialNotes:   material.notes,
      coolantRequired: material.coolantRequired,
    );
  }

  /// RPM = (Vc × 1000) / (π × D)  [metric, Vc in m/min, D in mm]
  /// RPM = (SFM × 3.82) / D        [imperial, D in inches]
  static int _calculateRpm(double cuttingSpeed, double diameter, bool isMetric) {
    if (isMetric) {
      return ((cuttingSpeed * 1000) / (math.pi * diameter)).round();
    } else {
      return ((cuttingSpeed * 3.82) / diameter).round();
    }
  }

  /// MRR = WOC × DOC × Feed  [units³/min]
  static double _calculateMrr(double woc, double doc, double feedRate, bool isMetric) {
    final raw = woc * doc * feedRate;
    // Convert from mm³/min to cm³/min for readability
    return isMetric ? raw / 1000.0 : raw;
  }

  static double _selectCuttingSpeed(
    CuttingSpeedSet speeds,
    ToolMaterial toolMaterial,
    OperationType opType,
  ) {
    if (toolMaterial == ToolMaterial.carbide) {
      return opType == OperationType.roughing ? speeds.carbideRough : speeds.carbideFinish;
    } else {
      return opType == OperationType.roughing ? speeds.hssRough : speeds.hssFinish;
    }
  }
}
