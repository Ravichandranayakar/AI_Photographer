import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EDR DECISION — Research Topic 07: Stage 3 — Auto-Leveling
// ─────────────────────────────────────────────────────────────────────────────
//
// Problem:
//   A photographer holding the camera at a 5° tilt produces a skeleton where
//   the hips are at a 5° angle. If saved as-is, the user must tilt their body
//   5° to achieve a 100% match. This is wrong.
//
// Solution: Ordinary Procrustes Analysis (OPA) — Hip Axis Alignment.
//   1. Compute the tilt angle θ of the hip axis using atan2.
//   2. Apply a 2D rotation matrix to ALL landmarks to level θ → 0.
//   3. Rotate around the mid-hip centroid so normalization (Stage 4) is clean.
//
// Math (standard 2D rotation matrix):
//   dx = landmark.x - centroid.x
//   dy = landmark.y - centroid.y
//   new_x = centroid.x + dx*cos(-θ) - dy*sin(-θ)
//   new_y = centroid.y + dx*sin(-θ) + dy*cos(-θ)
//
// Note: We use (-θ) to counter-rotate the tilt (undo the camera tilt).
// ─────────────────────────────────────────────────────────────────────────────

/// Utility class that holds the output of [PoseLeveler.level].
class LeveledPose {
  /// The rotation-corrected landmarks (pixel space, pre-normalization).
  final Map<PoseLandmarkType, PoseLandmark> landmarks;

  /// The detected tilt angle in degrees. 0.0 = image was perfectly level.
  /// Stored in [AuthoredPose.correctedTiltDegrees] for debugging.
  final double tiltDegrees;

  const LeveledPose({required this.landmarks, required this.tiltDegrees});
}

abstract final class PoseLeveler {
  /// Applies OPA hip-axis leveling to the raw ML Kit landmarks.
  ///
  /// Returns a [LeveledPose] with all landmark coordinates corrected so that
  /// the line connecting [leftHip] and [rightHip] is perfectly horizontal.
  static LeveledPose level(
    Map<PoseLandmarkType, PoseLandmark> rawLandmarks,
  ) {
    final leftHip = rawLandmarks[PoseLandmarkType.leftHip]!;
    final rightHip = rawLandmarks[PoseLandmarkType.rightHip]!;

    // ── Step 1: Compute hip axis tilt angle ─────────────────────────────────
    // θ = angle of the vector from leftHip to rightHip relative to horizontal.
    // If hips are level → θ = 0.
    // If right hip is higher than left → θ > 0 (counter-clockwise rotation needed).
    final theta =
        math.atan2(rightHip.y - leftHip.y, rightHip.x - leftHip.x);
    final tiltDegrees = theta * (180.0 / math.pi);

    // If tilt is negligible (< 0.5°), skip rotation to avoid floating-point noise.
    if (tiltDegrees.abs() < 0.5) {
      return LeveledPose(landmarks: Map.from(rawLandmarks), tiltDegrees: 0.0);
    }

    // ── Step 2: Compute mid-hip centroid (rotation pivot) ───────────────────
    final cx = (leftHip.x + rightHip.x) / 2.0;
    final cy = (leftHip.y + rightHip.y) / 2.0;

    // We rotate by -θ to undo the tilt.
    final cosA = math.cos(-theta);
    final sinA = math.sin(-theta);

    // ── Step 3: Rotate ALL landmarks ────────────────────────────────────────
    final leveled = <PoseLandmarkType, PoseLandmark>{};

    for (final entry in rawLandmarks.entries) {
      final lm = entry.value;
      final dx = lm.x - cx;
      final dy = lm.y - cy;

      final newX = cx + dx * cosA - dy * sinA;
      final newY = cy + dx * sinA + dy * cosA;

      // PoseLandmark is a ML Kit object. We reconstruct it with corrected x,y.
      // Confidence (likelihood) is unchanged — it's a detection metric, not spatial.
      leveled[entry.key] = PoseLandmark(
        type: entry.key,
        x: newX,
        y: newY,
        z: lm.z,         // z is depth — not affected by 2D in-plane rotation.
        likelihood: lm.likelihood,
      );
    }

    return LeveledPose(landmarks: leveled, tiltDegrees: tiltDegrees);
  }
}
