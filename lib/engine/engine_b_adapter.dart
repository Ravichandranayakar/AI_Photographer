// ============================================================
// Engine B Flutter Adapter — engine_b_adapter.dart
// ============================================================
// Bridges the research Engine B prototype with the Flutter app.
//
// Converts google_mlkit_pose_detection PoseLandmark
//   → RawLandmark (engine_b format)
//   → EngineBResult
//   → SilhouetteResult (for SilhouettePainter, no painter changes needed)
// ============================================================

import 'silhouette/vec2.dart';
import 'silhouette/silhouette_engine.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// Engine B files (lib/engine/silhouette_b/ — mirrors research prototype)
import 'silhouette_b/capsule_body.dart' show RawLandmark, CapsuleBody;
import 'silhouette_b/engine_b.dart' show EngineB;
import 'silhouette_b/contour/v2_csg/csg_extractor.dart';
import 'silhouette_b/capsule_validator.dart';

// ──────────────────────────────────────────────────────────────
// VERSION FLAG — flip to switch between Engine B v1 and v2 CSG.
// Phase 1: kUseV2Csg = true — v1 Polar Binning is FROZEN as baseline.
// ──────────────────────────────────────────────────────────────
const bool kUseV2Csg = true;

// ── Landmark type → int index (matches LandmarkIdx in capsule_body.dart) ─────
// Only PoseLandmarkType values that actually exist in ML Kit are listed.
// Verified against google_mlkit_pose_detection enum.
final Map<PoseLandmarkType, int> _mlkitToIdx = {
  PoseLandmarkType.nose                : 0,
  PoseLandmarkType.leftEyeInner        : 1,
  PoseLandmarkType.leftEye             : 2,
  PoseLandmarkType.leftEyeOuter        : 3,
  PoseLandmarkType.rightEyeInner       : 4,
  PoseLandmarkType.rightEye            : 5,
  PoseLandmarkType.rightEyeOuter       : 6,
  PoseLandmarkType.leftEar             : 7,
  PoseLandmarkType.rightEar            : 8,
  PoseLandmarkType.leftShoulder        : 11,
  PoseLandmarkType.rightShoulder       : 12,
  PoseLandmarkType.leftElbow           : 13,
  PoseLandmarkType.rightElbow          : 14,
  PoseLandmarkType.leftWrist           : 15,
  PoseLandmarkType.rightWrist          : 16,
  PoseLandmarkType.leftPinky           : 17,
  PoseLandmarkType.rightPinky          : 18,
  PoseLandmarkType.leftIndex           : 19,
  PoseLandmarkType.rightIndex          : 20,
  PoseLandmarkType.leftThumb           : 21,
  PoseLandmarkType.rightThumb          : 22,
  PoseLandmarkType.leftHip             : 23,
  PoseLandmarkType.rightHip            : 24,
  PoseLandmarkType.leftKnee            : 25,
  PoseLandmarkType.rightKnee           : 26,
  PoseLandmarkType.leftAnkle           : 27,
  PoseLandmarkType.rightAnkle          : 28,
  PoseLandmarkType.leftHeel            : 29,
  PoseLandmarkType.rightHeel           : 30,
  PoseLandmarkType.leftFootIndex       : 31,
  PoseLandmarkType.rightFootIndex      : 32,
};

// ─────────────────────────────────────────────────────────────────────────────

class EngineBAdapter {
  // Engine B v1 instance (Polar Binning — FROZEN baseline)
  static final EngineB _engineV1 = EngineB(chaikinIterations: 2);

  // Engine B v2 CSG extractor
  static const CsgExtractor _engineV2 = CsgExtractor();

  /// Process one camera frame through Engine B.
  ///
  /// [smoothedLandmarks]: output of FrozenEuroFilter.processPose()
  ///   Raw PIXEL coordinates, already 1-Euro-filtered — NOT normalized.
  /// [torsoPx]: Euclidean distance mid-shoulder → mid-hip in pixels.
  ///
  /// Returns [SilhouetteResult] ready for [SilhouettePainter].
  static SilhouetteResult process({
    required Map<PoseLandmarkType, PoseLandmark> smoothedLandmarks,
    required double torsoPx,
  }) {
    // ── Step 1: Convert ML Kit PoseLandmark → RawLandmark ─────────────────
    var rawMap = <int, RawLandmark>{};
    for (final entry in smoothedLandmarks.entries) {
      final idx = _mlkitToIdx[entry.key];
      if (idx == null) continue;
      final lm = entry.value;
      rawMap[idx] = RawLandmark(lm.x, lm.y, lm.likelihood);
    }
    
    // Apply EMA temporal smoothing to coordinates and confidence
    rawMap = CapsuleValidator.smoothLandmarks(rawMap);

    // ── Step 2: Build capsule skeleton (same for v1 and v2) ───────────────
    if (torsoPx < 10.0) return SilhouetteResult.empty();

    // ── v2 CSG branch ───────────────────────────────────────────────
    if (kUseV2Csg) {
      final capsules = CapsuleBody.build(
        landmarks: rawMap,
        torsoPx: torsoPx,
      );
      if (capsules.length < 3) return SilhouetteResult.empty();

      // Measure extraction time (Success Criterion T5: < 3ms)
      final sw = Stopwatch()..start();
      final csgPath = _engineV2.extract(capsules);
      sw.stop();

      if (csgPath == null) return SilhouetteResult.empty();

      // Count sub-paths (T6: should be 1 = connected body)
      var subPaths = 0;
      for (final _ in csgPath.computeMetrics()) { subPaths++; }

      return SilhouetteResult(
        path: const [],        // v2 uses csgPath — Vec2 list is empty
        inputJoints: capsules.length,
        hullVertices: capsules.length,
        finalVertices: 0,
        csgPath: csgPath,
        extractionUs: sw.elapsedMicroseconds,
        csgSubPaths: subPaths,
        capsuleTelemetry: List.from(CapsuleValidator.currentFrameTelemetry),
      );
    }

    // ── v1 Polar Binning branch (FROZEN baseline) ───────────────────────
    final result = _engineV1.process(landmarks: rawMap, torsoPx: torsoPx);

    if (!result.isValid || !result.isClean) {
      return SilhouetteResult.empty();
    }

    // ── Step 3: Convert Engine B Vec2 → lib Vec2 for SilhouetteResult ─────
    // Engine B uses its own Vec2 from capsule.dart (same structure, different file).
    // We copy x/y into the lib/engine/silhouette/vec2.dart Vec2 type.
    final libPath = result.path.map((p) => Vec2(p.x, p.y)).toList();

    return SilhouetteResult(
      path: libPath,
      inputJoints: result.capsuleCount,
      hullVertices: result.hullVertices,
      finalVertices: result.finalVertices,
    );
  }
}
