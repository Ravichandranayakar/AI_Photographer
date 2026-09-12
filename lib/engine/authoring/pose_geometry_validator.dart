import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/frozen_landmark.dart';
import 'authored_pose.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EDR DECISION — Research Topic 07: Stage 5 — Geometry Validation
// ─────────────────────────────────────────────────────────────────────────────
//
// Operates on NORMALIZED coordinates (after Stage 4).
// In normalized space:
//   - Mid-hip = (0.0, 0.0) → origin
//   - Torso length = 1.0 unit (by definition of LandmarkNormalizer)
//   - Shoulders are at approximately y = -1.0 (above hips)
//   - Ankles are at approximately y = +1.5 to +1.8 (below hips)
//
// Rules are evaluated in normalized torso-length units.
// This makes all thresholds body-size invariant.
//
// REJECT rules: Hard failure — pose is mathematically invalid or upside-down.
// WARN  rules : Soft warnings — pose may be valid but unusual.
// ─────────────────────────────────────────────────────────────────────────────
abstract final class PoseGeometryValidator {
  /// Validates the normalized skeleton for anatomical plausibility.
  static GeometryReport validate(
    Map<PoseLandmarkType, FrozenLandmark> normalizedLandmarks,
  ) {
    final warnings = <String>[];

    final nose = normalizedLandmarks[PoseLandmarkType.nose];
    final leftShoulder =
        normalizedLandmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder =
        normalizedLandmarks[PoseLandmarkType.rightShoulder];
    final leftHip = normalizedLandmarks[PoseLandmarkType.leftHip];
    final rightHip = normalizedLandmarks[PoseLandmarkType.rightHip];
    final leftKnee = normalizedLandmarks[PoseLandmarkType.leftKnee];
    final rightKnee = normalizedLandmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = normalizedLandmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = normalizedLandmarks[PoseLandmarkType.rightAnkle];

    // ── Rule 1: Head above shoulders (REJECT) ────────────────────────────────
    // In our coordinate system, negative Y = above hips.
    // Shoulders should be at approximately y ≈ -1.0.
    // Nose should be even higher (more negative Y) than shoulders.
    if (nose != null && leftShoulder != null) {
      if (nose.y > leftShoulder.y) {
        return GeometryReport(
          passed: false,
          warnings: [
            'REJECT: Nose (y=${nose.y.toStringAsFixed(2)}) is below '
                'left shoulder (y=${leftShoulder.y.toStringAsFixed(2)}). '
                'Pose may be upside-down or ML Kit severely miscalculated.',
          ],
        );
      }
    }

    // ── Rule 2: Shoulders above hips (REJECT) ───────────────────────────────
    // By normalization, hips are at y ≈ 0.0. Shoulders must be negative (above).
    if (leftShoulder != null && leftHip != null) {
      if (leftShoulder.y > 0.2) {
        // Allowing a small 0.2 torso-unit margin for unusual poses.
        return GeometryReport(
          passed: false,
          warnings: [
            'REJECT: Left shoulder (y=${leftShoulder.y.toStringAsFixed(2)}) '
                'is at or below hip level. Normalization may have failed or '
                'the image is severely distorted.',
          ],
        );
      }
    }

    // ── Rule 3: Bilateral shoulder symmetry (WARN) ───────────────────────────
    if (leftShoulder != null && rightShoulder != null) {
      final shoulderDiff = (leftShoulder.y - rightShoulder.y).abs();
      if (shoulderDiff > 0.20) {
        warnings.add(
            'Shoulder height difference of ${shoulderDiff.toStringAsFixed(2)} '
            'torso-units is large. May be a leaning or dynamic pose — verify visually.');
      }
    }

    // ── Rule 4: Knee below hip (WARN) ────────────────────────────────────────
    // Knee should have positive Y (below hips). Exception: lying-down poses.
    if (leftKnee != null && leftHip != null) {
      if (leftKnee.y < leftHip.y - 0.1) {
        warnings.add(
            'Left knee (y=${leftKnee.y.toStringAsFixed(2)}) appears above '
            'left hip (y=${leftHip.y.toStringAsFixed(2)}). '
            'Could be a lying-down pose or ML Kit detection error.');
      }
    }
    if (rightKnee != null && rightHip != null) {
      if (rightKnee.y < rightHip.y - 0.1) {
        warnings.add(
            'Right knee (y=${rightKnee.y.toStringAsFixed(2)}) appears above '
            'right hip (y=${rightHip.y.toStringAsFixed(2)}). '
            'Could be a lying-down pose or ML Kit detection error.');
      }
    }

    // ── Rule 5: Ankle below knee (REJECT if severe) ──────────────────────────
    if (leftAnkle != null && leftKnee != null) {
      if (leftAnkle.y < leftKnee.y - 0.2) {
        return GeometryReport(
          passed: false,
          warnings: [
            'REJECT: Left ankle (y=${leftAnkle.y.toStringAsFixed(2)}) '
                'is significantly above left knee (y=${leftKnee.y.toStringAsFixed(2)}). '
                'This is anatomically impossible in a standing or sitting pose.',
          ],
        );
      }
    }
    if (rightAnkle != null && rightKnee != null) {
      if (rightAnkle.y < rightKnee.y - 0.2) {
        return GeometryReport(
          passed: false,
          warnings: [
            'REJECT: Right ankle (y=${rightAnkle.y.toStringAsFixed(2)}) '
                'is significantly above right knee (y=${rightKnee.y.toStringAsFixed(2)}). '
                'This is anatomically impossible in a standing or sitting pose.',
          ],
        );
      }
    }

    return GeometryReport(passed: true, warnings: warnings);
  }
}
