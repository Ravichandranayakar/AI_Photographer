// ============================================================
// Engine B v2 CSG — csg_extractor.dart
// ============================================================
// Replaces the v1 Polar Binning extractor with a Constructive
// Solid Geometry (CSG) regularized union approach.
//
// Mathematical basis (Requicha & Voelcker, 1977):
//   S = C₁ ∪* C₂ ∪* … ∪* Cₙ
//     = cl(int(C₁ ∪ C₂ ∪ … ∪ Cₙ))
//
// Each Cᵢ is the Minkowski sum of bone Lᵢ ⊕ B(rᵢ) — a stadium
// shape (capsule). Path.combine(PathOperation.union) is the
// Flutter/Skia implementation of the regularized set union.
//
// Post-process: Largest-Connected-Component (LCC) filter.
//   When ML Kit guesses landmark positions off-screen, isolated
//   capsule islands appear. LCC keeps only the largest sub-path
//   (the real body) and discards all satellite islands.
// ============================================================

import 'dart:ui' show Path, PathMetric, PathOperation;
import '../../capsule.dart';
import 'capsule_path_ext.dart';

class CsgExtractor {
  const CsgExtractor();

  /// Extract the outer body contour via Boolean Union + LCC filter.
  ///
  /// Returns a single merged [Path] (the main body) or null if no
  /// valid capsules exist. Disconnected satellite capsules are removed.
  Path? extract(List<Capsule> capsules) {
    // ── Step 1: Convert each capsule to a stadium Flutter Path ─────────────
    final validPaths = <Path>[];
    for (final cap in capsules) {
      if (cap.r >= 1.0) {
        validPaths.add(cap.toFlutterPath());
      }
    }
    if (validPaths.isEmpty) return null;

    // ── Step 2: Binary Tree CSG Union (O(N log N)) ────────────────────────
    // Sequential Path.combine is O(N²) because the left path grows at every
    // step. Binary reduction pairs paths at each level — much faster.
    final merged = _binaryUnion(validPaths);
    if (merged == null) return null;

    // ── Step 3: Largest-Connected-Component filter ────────────────────────
    // Path.combine produces ONE Path object that can contain MULTIPLE
    // disconnected sub-paths when capsules don't overlap each other.
    // We keep only the sub-path with the longest arc length = the body.
    return _keepLargestComponent(merged);
  }

  // ── Private: Binary Tree Reduction ─────────────────────────────────────────
  Path? _binaryUnion(List<Path> paths) {
    if (paths.isEmpty) return null;
    var current = paths;
    while (current.length > 1) {
      final next = <Path>[];
      for (int i = 0; i < current.length; i += 2) {
        if (i + 1 < current.length) {
          next.add(Path.combine(PathOperation.union, current[i], current[i + 1]));
        } else {
          next.add(current[i]); // Odd element carries over unchanged
        }
      }
      current = next;
    }
    return current.first;
  }

  // ── Private: Largest-Connected-Component Filter ─────────────────────────────
  // Path.combine returns ONE Path but it can contain MULTIPLE disconnected
  // sub-paths when capsules don't touch each other (e.g. ML Kit guesses leg
  // positions far below a close-up selfie frame).
  //
  // PathMetrics iterates each sub-path independently. We find the one with
  // the greatest arc length = the main body contour, and extract only that.
  //
  // Research reference: equivalent to OpenCV's connectedComponentsWithStats()
  // which filters blobs by area. We use arc length as the 2D proxy for area.
  Path _keepLargestComponent(Path merged) {
    final metrics = merged.computeMetrics().toList();

    // Single sub-path → already clean, skip filtering.
    if (metrics.length <= 1) return merged;

    // Find sub-path with maximum arc length = the main body.
    PathMetric? largest;
    for (final pm in metrics) {
      if (largest == null || pm.length > largest.length) {
        largest = pm;
      }
    }

    if (largest == null) return merged;

    // Reconstruct a clean Path from only the largest contour.
    // extractPath(0, length) gives the full sub-path as a new Path.
    final clean = largest.extractPath(0, largest.length);
    // Ensure the path is closed (extractPath may not close it explicitly).
    clean.close();
    return clean;
  }

  /// Diagnostic data for the research logger.
  ///
  /// [rawSubPaths]    = sub-path count BEFORE LCC (how many islands existed).
  /// [finalSubPaths]  = sub-path count AFTER LCC (should always be 1).
  Map<String, int> diagnostics(List<Capsule> capsules) {
    final validPaths = <Path>[];
    for (final cap in capsules) {
      if (cap.r >= 1.0) validPaths.add(cap.toFlutterPath());
    }
    if (validPaths.isEmpty) return {'rawSubPaths': 0, 'finalSubPaths': 0, 'capsules': 0};

    final merged = _binaryUnion(validPaths);
    if (merged == null) return {'rawSubPaths': 0, 'finalSubPaths': 0, 'capsules': 0};

    var rawCount = 0;
    for (final _ in merged.computeMetrics()) { rawCount++; }

    final cleaned = _keepLargestComponent(merged);
    var finalCount = 0;
    for (final _ in cleaned.computeMetrics()) { finalCount++; }

    return {
      'rawSubPaths': rawCount,
      'finalSubPaths': finalCount,
      'capsules': capsules.length,
    };
  }
}
