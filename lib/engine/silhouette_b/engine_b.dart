// ============================================================
// Engine B — engine_b.dart
// ============================================================
// Top-level orchestrator for the Capsule + Offset Curves engine.
//
// Pipeline:
//   Raw pixel landmarks (from 1 Euro Filter)
//       │
//       ▼
//   CapsuleBody.build()   ← 17 capsules (B2, B3, B4)
//       │
//       ▼
//   CapsuleOutline.extract()  ← outer surface (B5, B6)
//       │
//       ▼
//   ChaikinB.subdivide()  ← 2 iterations
//       │
//       ▼
//   EngineBResult (List<Vec2> path)
//
// Note: ChaikinB is a self-contained copy of the Chaikin algorithm
// so this file can be used both standalone (dart run evaluator) and
// in Flutter (after copying to lib/engine/silhouette_b/).
// ============================================================

import 'capsule.dart';
import 'capsule_body.dart';
import 'capsule_outline.dart';

// ── Chaikin Subdivision (inlined — identical math to lib/engine/silhouette/chaikin_engine.dart) ──
// For each edge (vk, vk+1):
//   q_k = 3/4 * vk + 1/4 * vk+1
//   r_k = 1/4 * vk + 3/4 * vk+1
class ChaikinB {
  static List<Vec2> subdivide(List<Vec2> points, {int iterations = 2}) {
    if (points.length < 3) return points;
    var current = points;
    for (int iter = 0; iter < iterations; iter++) {
      final next = <Vec2>[];
      final n = current.length;
      for (int i = 0; i < n; i++) {
        final v0 = current[i];
        final v1 = current[(i + 1) % n];
        next.add(Vec2(0.75 * v0.x + 0.25 * v1.x, 0.75 * v0.y + 0.25 * v1.y));
        next.add(Vec2(0.25 * v0.x + 0.75 * v1.x, 0.25 * v0.y + 0.75 * v1.y));
      }
      current = next;
    }
    return current;
  }
}

// ── Engine B Result ──────────────────────────────────────────────────────────

class EngineBResult {
  /// The final ordered polygon path (pixel coordinates).
  /// Feed this directly to SilhouettePainter for rendering.
  final List<Vec2> path;

  /// Diagnostic data for benchmark
  final int capsuleCount;
  final int candidatePointCount;
  final int outerSurfaceCount;
  final int hullVertices;    // After polar binning
  final int finalVertices;   // After Chaikin

  const EngineBResult({
    required this.path,
    required this.capsuleCount,
    required this.candidatePointCount,
    required this.outerSurfaceCount,
    required this.hullVertices,
    required this.finalVertices,
  });

  factory EngineBResult.empty() => const EngineBResult(
    path: [],
    capsuleCount: 0,
    candidatePointCount: 0,
    outerSurfaceCount: 0,
    hullVertices: 0,
    finalVertices: 0,
  );

  bool get isValid => path.length >= 3;

  // Check for any NaN or Infinity in the path (ε-guard validation)
  bool get isClean => path.every(
    (p) => p.x.isFinite && p.y.isFinite,
  );

  @override
  String toString() => [
    'EngineBResult(',
    '  capsules=$capsuleCount',
    '  candidates=$candidatePointCount',
    '  outerSurface=$outerSurfaceCount',
    '  hullVertices=$hullVertices',
    '  finalVertices=$finalVertices',
    '  isValid=$isValid  isClean=$isClean',
    ')',
  ].join('\n');
}

// ── Engine B Orchestrator ────────────────────────────────────────────────────

class EngineB {
  // How many Chaikin iterations to apply.
  // 2 iterations = good smoothing without excessive shrinkage.
  final int chaikinIterations;

  const EngineB({this.chaikinIterations = 2});

  /// Process one frame of landmarks.
  ///
  /// [landmarks] : Map<int index, RawLandmark> — raw pixel coordinates.
  /// [torsoPx]   : Euclidean distance mid-shoulder to mid-hip in pixels.
  EngineBResult process({
    required Map<int, RawLandmark> landmarks,
    required double torsoPx,
  }) {
    // Guard: need a valid torso measurement
    if (torsoPx < 10.0) return EngineBResult.empty();

    // ── Stage 1: Build capsules ─────────────────────────────────────────
    final capsules = CapsuleBody.build(
      landmarks: landmarks,
      torsoPx: torsoPx,
    );
    if (capsules.length < 3) return EngineBResult.empty();

    // ── Stage 2: Outer surface diagnostics (for benchmark report) ───────
    final diag = CapsuleOutline.diagnostics(capsules);

    // ── Stage 3: Extract outer surface polygon ──────────────────────────
    final hull = CapsuleOutline.extract(capsules);
    if (hull.length < 3) return EngineBResult.empty();

    // ── Stage 4: Chaikin smoothing ───────────────────────────────────────
    final smoothPath = ChaikinB.subdivide(hull, iterations: chaikinIterations);

    return EngineBResult(
      path: smoothPath,
      capsuleCount: capsules.length,
      candidatePointCount: diag['totalCandidates'] ?? 0,
      outerSurfaceCount: diag['outerSurface'] ?? 0,
      hullVertices: hull.length,
      finalVertices: smoothPath.length,
    );
  }
}
