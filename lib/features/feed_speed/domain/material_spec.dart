class CuttingSpeedSet {
  final double hssRough;
  final double hssFinish;
  final double carbideRough;
  final double carbideFinish;

  const CuttingSpeedSet({
    required this.hssRough,
    required this.hssFinish,
    required this.carbideRough,
    required this.carbideFinish,
  });

  factory CuttingSpeedSet.fromJson(Map<String, dynamic> json, bool isMetric) {
    final key = isMetric ? 'm_per_min' : 'sfm';
    return CuttingSpeedSet(
      hssRough:      (json['hss_rough'][key] as num).toDouble(),
      hssFinish:     (json['hss_finish'][key] as num).toDouble(),
      carbideRough:  (json['carbide_rough'][key] as num).toDouble(),
      carbideFinish: (json['carbide_finish'][key] as num).toDouble(),
    );
  }
}

class ChipLoadFactors {
  final double endMill2fl;
  final double endMill4fl;
  final double drill;
  final double faceMill;

  const ChipLoadFactors({
    required this.endMill2fl,
    required this.endMill4fl,
    required this.drill,
    required this.faceMill,
  });

  factory ChipLoadFactors.fromJson(Map<String, dynamic> json) {
    return ChipLoadFactors(
      endMill2fl: (json['end_mill_2fl'] as num).toDouble(),
      endMill4fl: (json['end_mill_4fl'] as num).toDouble(),
      drill:      (json['drill'] as num).toDouble(),
      faceMill:   (json['face_mill'] as num).toDouble(),
    );
  }

  double forToolCode(String toolCode) {
    if (toolCode.contains('drill')) return drill;
    if (toolCode.contains('face')) return faceMill;
    if (toolCode.contains('2fl') || toolCode.contains('ball_nose_2fl')) return endMill2fl;
    return endMill4fl;
  }
}

class MaterialSpec {
  final String code;
  final String name;
  final String nameFa;
  final String category;
  final int hardnessBhn;
  final CuttingSpeedSet cuttingSpeedsMetric;
  final CuttingSpeedSet cuttingSpeedsImperial;
  final ChipLoadFactors chipLoadFactors;
  final bool coolantRequired;
  final String notes;

  const MaterialSpec({
    required this.code,
    required this.name,
    required this.nameFa,
    required this.category,
    required this.hardnessBhn,
    required this.cuttingSpeedsMetric,
    required this.cuttingSpeedsImperial,
    required this.chipLoadFactors,
    required this.coolantRequired,
    required this.notes,
  });

  factory MaterialSpec.fromJson(Map<String, dynamic> json) {
    return MaterialSpec(
      code:                 json['code'] as String,
      name:                 json['name'] as String,
      nameFa:               json['name_fa'] as String,
      category:             json['category'] as String,
      hardnessBhn:          json['hardness_bhn'] as int,
      cuttingSpeedsMetric:  CuttingSpeedSet.fromJson(json['cutting_speeds'] as Map<String, dynamic>, true),
      cuttingSpeedsImperial:CuttingSpeedSet.fromJson(json['cutting_speeds'] as Map<String, dynamic>, false),
      chipLoadFactors:      ChipLoadFactors.fromJson(json['chip_load_factors'] as Map<String, dynamic>),
      coolantRequired:      json['coolant_required'] as bool,
      notes:                json['notes'] as String,
    );
  }
}
