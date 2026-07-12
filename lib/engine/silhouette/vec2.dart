import 'dart:math' as math;

/// A 2D geometric point/vector used throughout the Silhouette Engine.
///
/// Kept intentionally minimal — only the operations required by the
/// Kinematic Expansion and Chaikin math are defined here.
class Vec2 {
  final double x;
  final double y;

  const Vec2(this.x, this.y);

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator *(double scalar) => Vec2(x * scalar, y * scalar);

  /// Euclidean length of this vector.
  double get length => math.sqrt(x * x + y * y);

  /// Returns true if this vector is effectively zero-length (MediaPipe failure guard).
  bool get isDegenerate => length < 1e-6;

  /// Returns the normalized unit vector.
  /// Caller MUST check [isDegenerate] before calling this.
  Vec2 get normalized {
    final len = length;
    return Vec2(x / len, y / len);
  }

  /// 2D perpendicular normal — 90° counter-clockwise rotation.
  ///
  /// Assumes the topology is traversed in a clockwise perimeter order so that
  /// this formula produces an outward-facing normal. Verify during prototype
  /// validation — if the normal is inward-facing, use [normalCW] instead.
  Vec2 get normalCCW {
    final u = normalized;
    return Vec2(-u.y, u.x);
  }

  /// 2D perpendicular normal — 90° clockwise rotation.
  ///
  /// Use this if [normalCCW] produces inward-facing normals (topology traversal
  /// direction issue). Only one of these two will be correct for a given topology.
  Vec2 get normalCW {
    final u = normalized;
    return Vec2(u.y, -u.x);
  }

  /// Linear interpolation between this vector and [other] at parameter [t ∈ 0..1].
  Vec2 lerp(Vec2 other, double t) =>
      Vec2(x + (other.x - x) * t, y + (other.y - y) * t);

  @override
  String toString() => 'Vec2(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})';
}
