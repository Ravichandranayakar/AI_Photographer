import 'silhouette/vec2.dart';
import 'silhouette/silhouette_engine.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// Engine B files (lib/engine/silhouette_b/ — mirrors research prototype)
import 'silhouette_b/capsule_body.dart' show RawLandmark, CapsuleBody;
import 'silhouette_b/engine_b.dart' show EngineB;
import 'silhouette_b/contour/v2_csg/csg_extractor.dart';
import 'silhouette_b/capsule_validator.dart';
import 'models/frozen_landmark.dart';

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

    return _runEngineB(rawMap, torsoPx);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TARGET POSE GHOST — Engine B on denormalized FrozenLandmarks
  // ─────────────────────────────────────────────────────────────────────────
  //
  // PURPOSE:
  //   Runs the SAME Engine B capsule pipeline on the selected target pose,
  //   but with the pose rescaled to the USER's body size and anchored at the
  //   user's real hip position on screen.
  //
  // MATH:
  //   FrozenLandmark (x, y) are normalized to torso-length units, centered at
  //   mid-hip. To convert back to pixel space:
  //
  //     pixelX = anchorPxX + (lm.x * torsoPx)
  //     pixelY = anchorPxY + (lm.y * torsoPx)
  //
  //   where anchorPxX/Y = mid-hip pixel position from the live camera frame.
  //
  // RESULT:
  //   The same SilhouetteResult format as the live silhouette, but shaped to
  //   the target pose at the user's body scale — ready to draw with the
  //   ghost-style cyan painter.
  // ─────────────────────────────────────────────────────────────────────────
  static SilhouetteResult processTargetPose({
    required Map<PoseLandmarkType, FrozenLandmark> targetPose,
    required double anchorPxX,   // mid-hip X in ML Kit pixel space
    required double anchorPxY,   // mid-hip Y in ML Kit pixel space
    required double torsoPx,     // user's live torso length in pixels
    required double imageHeight, // ML Kit image height (for clamping)
    bool mirrorX = false,        // If true, flip the pose horizontally (for front camera)
  }) {
    if (torsoPx < 10.0) return SilhouetteResult.empty();

    // Denormalize: FrozenLandmark (normalized) → RawLandmark (pixel space)
    final rawMap = <int, RawLandmark>{};
    for (final entry in targetPose.entries) {
      final idx = _mlkitToIdx[entry.key];
      if (idx == null) continue;
      final lm = entry.value;
      
      double confidence = lm.likelihood;

      // Re-project into pixel space using user's anchor + scale
      // If mirrored (front camera), invert the X offset so the pose visually matches the thumbnail
      final px = anchorPxX + (mirrorX ? -lm.x : lm.x) * torsoPx;
      final py = anchorPxY + (lm.y * torsoPx);
      rawMap[idx] = RawLandmark(px, py, confidence);
    }

    // Run same Engine B pipeline (NO EMA smoothing — target is static)
    return _runEngineB(rawMap, torsoPx);
  }


  // ── Shared Engine B runner ─────────────────────────────────────────────────
  static SilhouetteResult _runEngineB(Map<int, RawLandmark> rawMap, double torsoPx) {
    if (torsoPx < 10.0) return SilhouetteResult.empty();

    // ── Half-Body Pose / Invisible Legs Heuristic ────────────────────────
    // If the knee confidence is extremely low (< 0.2), ML Kit is just wildly 
    // guessing its location (often squishing it unnaturally close to the hip).
    // In this case, we force the confidence of the entire leg to 0.0 so Engine B 
    // skips the leg capsules entirely, creating a clean "open" bottom edge.
    void killLeg(int kneeIdx, int ankleIdx, int heelIdx, int footIdx) {
      if ((rawMap[kneeIdx]?.confidence ?? 0) < 0.2) {
        if (rawMap.containsKey(kneeIdx)) rawMap[kneeIdx] = RawLandmark(rawMap[kneeIdx]!.x, rawMap[kneeIdx]!.y, 0.0);
        if (rawMap.containsKey(ankleIdx)) rawMap[ankleIdx] = RawLandmark(rawMap[ankleIdx]!.x, rawMap[ankleIdx]!.y, 0.0);
        if (rawMap.containsKey(heelIdx)) rawMap[heelIdx] = RawLandmark(rawMap[heelIdx]!.x, rawMap[heelIdx]!.y, 0.0);
        if (rawMap.containsKey(footIdx)) rawMap[footIdx] = RawLandmark(rawMap[footIdx]!.x, rawMap[footIdx]!.y, 0.0);
      }
    }
    
    killLeg(
      _mlkitToIdx[PoseLandmarkType.leftKnee]!,
      _mlkitToIdx[PoseLandmarkType.leftAnkle]!,
      _mlkitToIdx[PoseLandmarkType.leftHeel]!,
      _mlkitToIdx[PoseLandmarkType.leftFootIndex]!,
    );
    
    killLeg(
      _mlkitToIdx[PoseLandmarkType.rightKnee]!,
      _mlkitToIdx[PoseLandmarkType.rightAnkle]!,
      _mlkitToIdx[PoseLandmarkType.rightHeel]!,
      _mlkitToIdx[PoseLandmarkType.rightFootIndex]!,
    );

    // ── Step 2: Build capsule skeleton (same for v1 and v2) ───────────────

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
    final libPath = result.path.map((p) => Vec2(p.x, p.y)).toList();

    return SilhouetteResult(
      path: libPath,
      inputJoints: result.capsuleCount,
      hullVertices: result.hullVertices,
      finalVertices: result.finalVertices,
    );
  }
}

