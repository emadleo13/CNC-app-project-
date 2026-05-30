import 'dart:math' as math;

class ArcPoint {
  final double x;
  final double z;
  const ArcPoint(this.x, this.z);
}

class ArcResult {
  final ArcPoint center;
  final double radius;
  final double sweepAngle; // degrees, p1→p3 about the centre
  const ArcResult(
      {required this.center, required this.radius, required this.sweepAngle});
}

class ArcCalculator {
  /// Circumcircle of three points (the "CAD 3-point arc" method): returns the
  /// centre and radius of the arc passing through [p1], [p2], [p3].
  /// Returns null if the points are collinear.
  static ArcResult? threePoint(ArcPoint p1, ArcPoint p2, ArcPoint p3) {
    final ax = p1.x, az = p1.z;
    final bx = p2.x, bz = p2.z;
    final cx = p3.x, cz = p3.z;

    final d = 2 * (ax * (bz - cz) + bx * (cz - az) + cx * (az - bz));
    if (d.abs() < 1e-9) return null; // collinear

    final a2 = ax * ax + az * az;
    final b2 = bx * bx + bz * bz;
    final c2 = cx * cx + cz * cz;

    final ux = (a2 * (bz - cz) + b2 * (cz - az) + c2 * (az - bz)) / d;
    final uz = (a2 * (cx - bx) + b2 * (ax - cx) + c2 * (bx - ax)) / d;
    final center = ArcPoint(ux, uz);
    final radius =
        math.sqrt((ax - ux) * (ax - ux) + (az - uz) * (az - uz));

    final a1 = math.atan2(az - uz, ax - ux);
    final a3 = math.atan2(cz - uz, cx - ux);
    var sweep = (a3 - a1) * 180 / math.pi;
    if (sweep < 0) sweep += 360;

    return ArcResult(center: center, radius: radius, sweepAngle: sweep);
  }

  /// Radius from a chord length and the included (sweep) angle in degrees.
  /// R = chord / (2 · sin(angle/2)).
  static double? radiusFromChord(
      {required double chord, required double sweepDeg}) {
    final half = (sweepDeg / 2) * math.pi / 180;
    final s = math.sin(half);
    if (s.abs() < 1e-9) return null;
    return chord / (2 * s);
  }
}
