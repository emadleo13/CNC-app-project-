import 'dart:math' as math;

class ArcPoint {
  final double x;
  final double z;
  const ArcPoint(this.x, this.z);
}

class ArcResult {
  final ArcPoint center;
  final double radius;

  /// Degrees from p1 to p3 along the arc that passes through p2.
  final double sweepAngle;

  /// Direction from p1 through p2 to p3, with X to the right and Z up (as the
  /// preview draws it).
  final bool clockwise;

  /// Start angle of p1 about the centre, radians, same frame.
  final double startAngle;

  const ArcResult({
    required this.center,
    required this.radius,
    required this.sweepAngle,
    required this.clockwise,
    required this.startAngle,
  });
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

    // Angles about the centre. The counter-clockwise sweep from p1 to p3 is
    // the right arc only if p2 lies inside it; otherwise the arc runs the
    // other way. (Always taking the CCW sweep showed 270° for a 90° CW arc.)
    double ccw(double from, double to) {
      var d = (to - from) % (2 * math.pi);
      if (d < 0) d += 2 * math.pi;
      return d;
    }
    final t1 = math.atan2(az - uz, ax - ux);
    final t2 = math.atan2(bz - uz, bx - ux);
    final t3 = math.atan2(cz - uz, cx - ux);
    final ccwSweep = ccw(t1, t3);
    final clockwise = ccw(t1, t2) > ccwSweep;
    final sweep = (clockwise ? 2 * math.pi - ccwSweep : ccwSweep) * 180 / math.pi;

    return ArcResult(
      center: center,
      radius: radius,
      sweepAngle: sweep,
      clockwise: clockwise,
      startAngle: t1,
    );
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
