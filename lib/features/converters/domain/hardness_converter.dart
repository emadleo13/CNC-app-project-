/// Approximate steel hardness conversion (per ASTM E140 / SAE J417 charts).
///
/// Values are interpolated between table rows. Conversions are approximations
/// valid for carbon and low-alloy steels — never exact across all materials.
enum HardnessScale { hrc, hv, hb, tensileMPa }

class HardnessRow {
  final double hrc;
  final double hv;
  final double? hb; // Brinell unreliable at the very top of the range
  final double? tensileMPa; // correlation breaks down above ~HRC 56
  const HardnessRow(this.hrc, this.hv, this.hb, this.tensileMPa);

  double? value(HardnessScale s) => switch (s) {
        HardnessScale.hrc => hrc,
        HardnessScale.hv => hv,
        HardnessScale.hb => hb,
        HardnessScale.tensileMPa => tensileMPa,
      };
}

class HardnessResult {
  final double? hrc;
  final double? hv;
  final double? hb;
  final double? tensileMPa;
  const HardnessResult({this.hrc, this.hv, this.hb, this.tensileMPa});

  double? get tensileKsi => tensileMPa == null ? null : tensileMPa! * 0.145038;
}

class HardnessConverter {
  // (HRC, HV, HB, Tensile MPa) — monotonically increasing.
  static const List<HardnessRow> _table = [
    HardnessRow(20, 238, 226, 770),
    HardnessRow(22, 248, 235, 800),
    HardnessRow(24, 257, 247, 840),
    HardnessRow(26, 272, 258, 890),
    HardnessRow(28, 286, 271, 950),
    HardnessRow(30, 302, 286, 1010),
    HardnessRow(32, 318, 302, 1080),
    HardnessRow(34, 336, 319, 1140),
    HardnessRow(36, 354, 336, 1210),
    HardnessRow(38, 372, 353, 1290),
    HardnessRow(40, 392, 371, 1370),
    HardnessRow(42, 412, 390, 1460),
    HardnessRow(44, 434, 409, 1550),
    HardnessRow(46, 458, 432, 1650),
    HardnessRow(48, 484, 455, 1760),
    HardnessRow(50, 513, 481, 1880),
    HardnessRow(52, 544, 509, 2010),
    HardnessRow(54, 577, 540, 2150),
    HardnessRow(56, 613, 573, null),
    HardnessRow(58, 653, 611, null),
    HardnessRow(60, 697, 654, null),
    HardnessRow(62, 746, 694, null),
    HardnessRow(64, 800, null, null),
    HardnessRow(65, 832, null, null),
  ];

  /// Convert [value] given in scale [from] to all other scales.
  /// Returns null if the value is outside the supported range.
  static HardnessResult? convert(double value, HardnessScale from) {
    final rows = _table.where((r) => r.value(from) != null).toList();
    final lo = rows.first.value(from)!;
    final hi = rows.last.value(from)!;
    if (value < lo || value > hi) return null;

    // Find bracketing rows on the `from` column.
    for (var i = 0; i < rows.length - 1; i++) {
      final a = rows[i];
      final b = rows[i + 1];
      final av = a.value(from)!;
      final bv = b.value(from)!;
      if (value >= av && value <= bv) {
        final t = bv == av ? 0.0 : (value - av) / (bv - av);
        return HardnessResult(
          hrc: _lerp(a.hrc, b.hrc, t),
          hv: _lerp(a.hv, b.hv, t),
          hb: _lerpN(a.hb, b.hb, t),
          tensileMPa: _lerpN(a.tensileMPa, b.tensileMPa, t),
        );
      }
    }
    return null;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double? _lerpN(double? a, double? b, double t) =>
      (a == null || b == null) ? null : _lerp(a, b, t);
}
