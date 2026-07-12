// ============================================================
// Engine B — Capsule.dart
// Math reference: research/05_body_silhouette/math.md (B1, B5)
// ============================================================
// A 2D capsule = line segment A→B with a radius r.
// This is the fundamental primitive for Engine B.
// Every bone of the human skeleton becomes one Capsule.
// ============================================================

import 'dart:math' as math;

// ── Vec2 (inlined to keep engine_b self-contained for dart run) ────────────
class Vec2 {
  final double x, y;
  const Vec2(this.x, this.y);

  Vec2 operator +(Vec2 o) => Vec2(x + o.x, y + o.y);
  Vec2 operator -(Vec2 o) => Vec2(x - o.x, y - o.y);
  Vec2 operator *(double s) => Vec2(x * s, y * s);

  double get length => math.sqrt(x * x + y * y);
  double dot(Vec2 o) => x * o.x + y * o.y;

  @override
  String toString() => '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

// ─────────────────────────────────────────────────────────────────────────────

class Capsule {
  final Vec2 a;       // Start joint (pixel space)
  final Vec2 b;       // End joint (pixel space)
  final double r;     // Radius (already scaled + confidence-weighted)
  final double weight; // Anatomical weight for Engine C field (not used in B)

  const Capsule({
    required this.a,
    required this.b,
    required this.r,
    required this.weight,
  });

  // ── Equation B1: Capsule Closest Point ─────────────────────────────────
  // t  = clamp( dot(P - A, B - A) / |B - A|^2 , 0, 1 )
  // Q  = A + t * (B - A)
  Vec2 closestPoint(Vec2 p) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final lenSq = dx * dx + dy * dy;
    if (lenSq < 1e-12) return a; // Degenerate: A == B

    final t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lenSq;
    final tc = t.clamp(0.0, 1.0);
    return Vec2(a.x + tc * dx, a.y + tc * dy);
  }

  // ── Equation B1: Shortest Distance from P to Capsule ───────────────────
  // d_i(P) = |P - Q|
  double distanceTo(Vec2 p) {
    final q = closestPoint(p);
    final dx = p.x - q.x;
    final dy = p.y - q.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  // ── Equation B5: Capsule Boundary Points (Stadium Shape) ───────────────
  // Right semicircle at B  (phi: -pi/2 → pi/2)
  // Left  semicircle at A  (phi:  pi/2 → 3pi/2)
  //
  // P = center + r * (cos(phi)*e.x - sin(phi)*e.y,
  //                   cos(phi)*e.y + sin(phi)*e.x)
  // where e = unit direction A→B, and (-e.y, e.x) is the left normal.
  List<Vec2> boundaryPoints({int n = 32}) {
    final points = <Vec2>[];

    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final len = math.sqrt(dx * dx + dy * dy);

    // Degenerate capsule → emit a circle around A
    if (len < 1e-6) {
      for (int i = 0; i < n; i++) {
        final phi = 2 * math.pi * i / n;
        points.add(Vec2(a.x + r * math.cos(phi), a.y + r * math.sin(phi)));
      }
      return points;
    }

    final ex = dx / len; // unit direction A→B
    final ey = dy / len;

    final half = n ~/ 2;

    // Right semicircle at B (phi from -pi/2 to pi/2)
    for (int i = 0; i <= half; i++) {
      final phi = -math.pi / 2 + math.pi * i / half;
      points.add(Vec2(
        b.x + r * (math.cos(phi) * ex - math.sin(phi) * ey),
        b.y + r * (math.cos(phi) * ey + math.sin(phi) * ex),
      ));
    }

    // Left semicircle at A (phi from pi/2 to 3*pi/2)
    for (int i = 0; i <= half; i++) {
      final phi = math.pi / 2 + math.pi * i / half;
      points.add(Vec2(
        a.x + r * (math.cos(phi) * ex - math.sin(phi) * ey),
        a.y + r * (math.cos(phi) * ey + math.sin(phi) * ex),
      ));
    }

    return points;
  }
}
