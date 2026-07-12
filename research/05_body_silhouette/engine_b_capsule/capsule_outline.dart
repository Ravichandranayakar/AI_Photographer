// ============================================================
// Engine B — CapsuleOutline.dart
// Math reference: research/05_body_silhouette/math.md (B5, B6)
// ============================================================
// Extracts the OUTER SURFACE of the union of all capsules.
//
// Algorithm:
//   1. Generate N boundary points per capsule (Equation B5)
//   2. Filter: keep only points NOT inside any other capsule (Equation B6)
//   3. Bin by polar angle from body centroid (72 bins = 5° each)
//      → take the outermost point in each bin
//   4. Return ordered polygon (ready for Chaikin smoothing)
//
// This approach is fundamentally different from Engine A.
// Engine A: hardcoded joint traversal order (breaks on non-canonical poses)
// Engine B: discovers the outline by testing which pixels are
//           truly on the outer surface — pose-independent.
// ============================================================

import 'dart:math' as math;
import 'capsule.dart';

class CapsuleOutline {
  // 120 bins = 3° per bin — better resolution for arm separation
  static const int _nBins = 120;

  // Equation B6 buffer: a point is "inside" if dist < r * _eps.
  // Loosened from 0.97 → 0.85 so arm boundary points adjacent to the
  // torso capsule are NOT filtered out (arms-at-sides visibility fix).
  static const double _eps = 0.85;

  // Number of boundary points to generate per capsule (Equation B5).
  // Doubled from 32 → 64 to eliminate sparse coverage spikes at wrist/ankle tips.
  static const int _pointsPerCapsule = 64;

  /// Extract the outer silhouette polygon from the capsule list.
  /// Returns an ordered list of Vec2 in polar angle order (CCW),
  /// or empty list if fewer than 3 capsules are present.
  static List<Vec2> extract(List<Capsule> capsules) {
    if (capsules.isEmpty) return [];

    // ── Step 1: Generate all boundary candidate points ───────────────────
    // Total candidates: up to 17 capsules × 34 points = 578 candidates
    final candidates = <_CandidatePoint>[];
    for (int ci = 0; ci < capsules.length; ci++) {
      final pts = capsules[ci].boundaryPoints(n: _pointsPerCapsule);
      for (final p in pts) {
        candidates.add(_CandidatePoint(p, ci));
      }
    }

    if (candidates.isEmpty) return [];

    // ── Step 2: Filter — Equation B6 ─────────────────────────────────────
    // A boundary point from capsule i is on the TRUE OUTER SURFACE
    // if it is NOT inside any other capsule j.
    // d_j(P) >= r_j * _eps   for all j != i
    final outerPoints = <Vec2>[];
    for (final cp in candidates) {
      bool isInterior = false;
      for (int ci = 0; ci < capsules.length; ci++) {
        if (ci == cp.capsuleIndex) continue;
        final cap = capsules[ci];
        if (cap.distanceTo(cp.point) < cap.r * _eps) {
          isInterior = true;
          break;
        }
      }
      if (!isInterior) outerPoints.add(cp.point);
    }

    if (outerPoints.length < 3) {
      // Fallback: if too many points got filtered (very close/overlapping capsules),
      // use all candidate points — some interior contamination is acceptable for the
      // research prototype.
      outerPoints.clear();
      outerPoints.addAll(candidates.map((c) => c.point));
    }

    // ── Step 3: Compute centroid from CAPSULE CENTERS (not boundary points) ─
    // CRITICAL FIX: Using the average of filtered outer points as centroid
    // causes the reference to drift toward dense areas (e.g., between the legs
    // in a wide stance), making polar bins see leg gaps as outward — producing
    // the W-shape inward spike artifacts seen in testing.
    // Using capsule A/B midpoints gives a stable, pose-independent centroid.
    double cx = 0, cy = 0;
    for (final cap in capsules) {
      cx += (cap.a.x + cap.b.x) / 2.0;
      cy += (cap.a.y + cap.b.y) / 2.0;
    }
    cx /= capsules.length;
    cy /= capsules.length;

    // ── Step 4: Polar binning — keep outermost point per 5° sector ───────
    // This eliminates duplicate close points and sorts the polygon correctly.
    final binPoints = List<Vec2?>.filled(_nBins, null);
    final binDists = List<double>.filled(_nBins, -1.0);

    for (final p in outerPoints) {
      final dx = p.x - cx;
      final dy = p.y - cy;
      // atan2 returns -pi..pi; shift to 0..2pi
      final angle = (math.atan2(dy, dx) + 2 * math.pi) % (2 * math.pi);
      final dist = math.sqrt(dx * dx + dy * dy);

      final binIdx = (angle / (2 * math.pi) * _nBins).floor() % _nBins;

      if (dist > binDists[binIdx]) {
        binDists[binIdx] = dist;
        binPoints[binIdx] = p;
      }
    }

    // ── Step 5: Collect non-null bins in angular order ────────────────────
    final hull = <Vec2>[];
    for (int i = 0; i < _nBins; i++) {
      final p = binPoints[i];
      if (p != null) hull.add(p);
    }

    // Need at least 3 points for a valid polygon
    if (hull.length < 3) return [];

    return hull;
  }

  // ── Diagnostic: count outer vs total points ────────────────────────────
  static Map<String, int> diagnostics(List<Capsule> capsules) {
    final candidates = <_CandidatePoint>[];
    for (int ci = 0; ci < capsules.length; ci++) {
      for (final p in capsules[ci].boundaryPoints(n: _pointsPerCapsule)) {
        candidates.add(_CandidatePoint(p, ci));
      }
    }

    int outerCount = 0;
    for (final cp in candidates) {
      bool isInterior = false;
      for (int ci = 0; ci < capsules.length; ci++) {
        if (ci == cp.capsuleIndex) continue;
        if (capsules[ci].distanceTo(cp.point) < capsules[ci].r * _eps) {
          isInterior = true;
          break;
        }
      }
      if (!isInterior) outerCount++;
    }

    return {
      'totalCandidates': candidates.length,
      'outerSurface': outerCount,
      'filtered': candidates.length - outerCount,
    };
  }
}

// Internal: associates a boundary point with the capsule it belongs to
class _CandidatePoint {
  final Vec2 point;
  final int capsuleIndex;
  const _CandidatePoint(this.point, this.capsuleIndex);
}
