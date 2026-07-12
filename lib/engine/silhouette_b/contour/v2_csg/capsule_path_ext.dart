// ============================================================
// Engine B v2 CSG — capsule_path_ext.dart
// ============================================================
// Extension on [Capsule] that converts the pure-math primitive
// to a Flutter Path (stadium / 2D capsule shape).
//
// Mathematical basis:
//   A 2D capsule = Minkowski sum of segment L_i and disk B(r_i).
//   In path terms: a rectangle with two semicircular end caps.
//
// Architecture note:
//   This file intentionally lives OUTSIDE capsule.dart so that
//   the core math primitive stays Flutter-free (usable in
//   dart run evaluators without a Flutter toolchain).
//
// Called ONLY by CsgExtractor. The painter never calls this directly.
// ============================================================

import 'dart:math' as math;
import 'dart:ui';           // Path, Rect — Flutter rendering primitives
import '../../capsule.dart';

extension CapsulePathExt on Capsule {
  /// Convert this capsule to a closed Flutter [Path] (stadium shape).
  ///
  /// Math: Minkowski sum of segment A→B and disk B(r).
  ///
  /// Stadium geometry:
  ///
  ///        ____
  ///       /    \       ← semicircle cap at B (forward end)
  ///  _____|    |_____
  /// |               |  ← rectangular body
  ///  ‾‾‾‾‾|    |‾‾‾‾‾
  ///       \____/       ← semicircle cap at A (rear end)
  ///
  /// The returned path is a single closed contour, ready for
  /// [Path.combine] with [PathOperation.union].
  Path toFlutterPath() {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final len = math.sqrt(dx * dx + dy * dy);

    // ── Degenerate: zero-length segment → circle ─────────────────────────
    if (len < 1e-6) {
      final p = Path()..addOval(Rect.fromCircle(
          center: Offset(a.x, a.y), radius: r));
      return p;
    }

    // ── Unit axis vector A→B ──────────────────────────────────────────────
    final ex = dx / len;
    final ey = dy / len;

    // ── Perpendicular offset of length r (rotated 90° CCW) ───────────────
    final nx = -ey * r;
    final ny =  ex * r;

    // ── Stadium path assembly ─────────────────────────────────────────────
    // Axis angle for arc start computation
    final axisAngle = math.atan2(ey, ex);

    // Bounding squares for the end-cap arcs (centred on B and A)
    final capBRect = Rect.fromCircle(center: Offset(b.x, b.y), radius: r);
    final capARect = Rect.fromCircle(center: Offset(a.x, a.y), radius: r);

    // Cap at B starts at (axis - π/2) and sweeps π clockwise
    final capBStart = axisAngle - math.pi / 2;
    // Cap at A starts at (axis + π/2) and sweeps π clockwise
    final capAStart = axisAngle + math.pi / 2;

    final path = Path();

    // Start at top-left corner: A - normal
    path.moveTo(a.x - nx, a.y - ny);

    // Top edge → top-right corner: B - normal
    path.lineTo(b.x - nx, b.y - ny);

    // Right cap at B: π-radian arc (clockwise)
    // Starts exactly at B - normal, sweeps π, ends at B + normal
    path.arcTo(capBRect, capBStart, math.pi, false);

    // Bottom edge → bottom-left corner: A + normal
    path.lineTo(a.x + nx, a.y + ny);

    // Left cap at A: π-radian arc (clockwise)
    // Starts exactly at A + normal, sweeps π, ends at A - normal
    path.arcTo(capARect, capAStart, math.pi, false);

    path.close();
    return path;
  }
}
