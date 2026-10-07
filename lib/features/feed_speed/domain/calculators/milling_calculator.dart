import 'dart:math' as math;
import '../material_spec.dart';
import '../cut_parameters.dart';

class MillingCalculator {
  /// Chip loads in materials.json are per tool type, as charts quote them for
  /// a half-inch tool. Real chip load grows with diameter: about
  /// proportionally for small tools and more slowly above ½" (the shape of
  /// Harvey/Helical tables). Applying the ½" value to a ⅛" end mill fed it
  /// roughly four times too hard.
  static const chipLoadReferenceDiameterIn = 0.5;

  /// Factor applied to the table chip load for a tool of [diameterIn] inches.
  static double chipLoadScale(double diameterIn) {
    if (diameterIn <= 0) return 0;
    const ref = chipLoadReferenceDiameterIn;
    return diameterIn <= ref
        ? diameterIn / ref
        : math.pow(diameterIn / ref, 0.7).toDouble();
  }

  /// [maxRpm] is the machine's spindle limit (0 = none). Above it the RPM is
  /// capped and the feed follows the capped RPM, so the chip load stays right
  /// and only the surface speed drops.
  static CutParameters? calculate({
    required CalculatorInput input,
    required MaterialSpec material,
    int maxRpm = 0,
  }) {
    if (input.toolDiameter <= 0) return null;
    final isMetric = input.units == UnitSystem.metric;
    final speeds = isMetric ? material.cuttingSpeedsMetric : material.cuttingSpeedsImperial;

    final tableSpeed = _selectCuttingSpeed(speeds, input.toolMaterial, input.operationType);
    final requestedRpm = _calculateRpm(tableSpeed, input.toolDiameter, isMetric);
    final limited = maxRpm > 0 && requestedRpm > maxRpm;
    final rpm = limited ? maxRpm : requestedRpm;
    final cuttingSpeed = limited
        ? SpeedFormulas.cuttingSpeed(rpm: rpm, diameter: input.toolDiameter, isMetric: isMetric)
        : tableSpeed;

    // Face-mill chip load belongs to the insert, not the cutter diameter.
    final diameterIn = isMetric ? input.toolDiameter / 25.4 : input.toolDiameter;
    final scale = input.toolTypeCode.contains('face') ? 1.0 : chipLoadScale(diameterIn);
    final chipLoadIn = material.chipLoadFactors.forToolCode(input.toolTypeCode) * scale;
    final chipLoad = isMetric ? chipLoadIn * 25.4 : chipLoadIn;
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
      limitedFromRpm:  limited ? requestedRpm : null,
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
