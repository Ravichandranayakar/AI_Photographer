import 'vec2.dart';

/// Phase B of the Silhouette Pipeline: Chaikin Subdivision.
///
/// Converts the blocky Kinematic Control Polygon into a smooth, skin-like
/// closed contour by recursively cutting every corner at a 25%/75% ratio.
///
/// Mathematical reference: research/05_body_silhouette/math.md — Stage 3
///
/// Convergence: As iterations → ∞, this converges to a quadratic B-Spline.
/// At 3–4 iterations, the result is perceptually indistinguishable from
/// the limit curve.
///
/// Self-intersection guarantee:
/// Chaikin preserves the convex hull of the control polygon, greatly reducing
/// the risk of self-intersection. The result can still self-intersect if the
/// INPUT hull is invalid — hence the Confidence Gate and Bisector steps in
/// KinematicHull are critical prerequisites.
abstract final class ChaikinEngine {
  /// Applies Chaikin corner-cutting to the given closed polygon [hull].
  ///
  /// [iterations] — number of subdivision passes (default 3, max 4).
  ///   3 iterations: N → 8N points
  ///   4 iterations: N → 16N points
  ///
  /// The input polygon is treated as a CLOSED loop — the last vertex connects
  /// back to the first.
  ///
  /// Returns the smoothed closed polygon. Returns [hull] unchanged if it has
  /// fewer than 3 points (cannot subdivide a degenerate polygon).
  static List<Vec2> subdivide(List<Vec2> hull, {int iterations = 3}) {
    if (hull.length < 3) return hull;

    List<Vec2> current = List<Vec2>.from(hull);

    for (int iter = 0; iter < iterations; iter++) {
      final int n = current.length;
      final List<Vec2> next = List<Vec2>.filled(n * 2, const Vec2(0, 0));

      for (int k = 0; k < n; k++) {
        final Vec2 vA = current[k];
        final Vec2 vB = current[(k + 1) % n]; // Closed loop wrap

        // q_k = (3/4) v_k + (1/4) v_{k+1}
        next[k * 2] = Vec2(
          0.75 * vA.x + 0.25 * vB.x,
          0.75 * vA.y + 0.25 * vB.y,
        );

        // r_k = (1/4) v_k + (3/4) v_{k+1}
        next[k * 2 + 1] = Vec2(
          0.25 * vA.x + 0.75 * vB.x,
          0.25 * vA.y + 0.75 * vB.y,
        );
      }

      current = next;
    }

    return current;
  }
}
