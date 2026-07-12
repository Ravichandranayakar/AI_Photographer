import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/frozen_landmark.dart';

/// Transforms raw ML Kit [PoseLandmark] coordinates into normalized
/// [FrozenLandmark] coordinates using Mid-Hip Translation + Torso-Length Scaling.
///
/// ─────────────────────────────────────────────────────────────────────────────
/// EDR DECISION — Research Topic 02: Skeleton Normalization
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Decision: Mid-Hip Translation + Torso-Length Scaling.
///
/// Rationale:
///   The human torso (mid-shoulder to mid-hip) is the rigid geometric anchor
///   of the skeleton. Its pixel-length in the camera frame changes ONLY when
///   the user physically moves toward or away from the camera.
///   By contrast, a bounding-box scale factor collapses the moment a user
///   raises their arms, corrupting every normalized coordinate.
///
/// Rejected Alternative: Bounding-box scaling.
///   Fatal flaw: Expanding limbs inflate the bounding box, causing the math
///   to falsely interpret the skeleton as shrinking, destroying score stability.
///
/// Locked Math:
///
///   Anchors:
///     mid_hip_x      = (left_hip.x + right_hip.x) / 2
///     mid_hip_y      = (left_hip.y + right_hip.y) / 2
///     mid_shoulder_x = (left_shoulder.x + right_shoulder.x) / 2
///     mid_shoulder_y = (left_shoulder.y + right_shoulder.y) / 2
///
///   Torso Length (scale denominator S):
///     S = √((mid_shoulder_x - mid_hip_x)² + (mid_shoulder_y - mid_hip_y)²)
///
///   Normalized coordinates for every landmark i:
///     X_normalized_i = (X_raw_i - mid_hip_x) / S
///     Y_normalized_i = (Y_raw_i - mid_hip_y) / S
///
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class LandmarkNormalizer {
  /// The minimum torso length (in screen-space) required for normalization
  /// to be considered geometrically valid.
  ///
  /// If the user is not in the frame or is too far away, the torso projects
  /// to near-zero pixels and division would produce meaningless values.
  static const double _minTorsoLengthThreshold = 0.03;

  /// Normalizes a raw ML Kit [Pose] into a [Map] of [FrozenLandmark] objects.
  ///
  /// Input: A [Pose] object as returned by the ML Kit Pose Detector.
  ///   - Coordinates are raw pixel values relative to the input image frame.
  ///
  /// Output: A [Map<PoseLandmarkType, FrozenLandmark>] where all coordinates
  ///   are in the normalized Frozen geometric space (mid-hip origin, torso scale).
  ///
  /// Returns [null] if normalization is geometrically impossible. This occurs when:
  ///   1. Any of the four anchor joints (shoulders, hips) are missing.
  ///   2. The computed torso length falls below [_minTorsoLengthThreshold],
  ///      indicating the subject is not meaningfully present in the frame.
  static Map<PoseLandmarkType, FrozenLandmark>? normalize(
      Map<PoseLandmarkType, PoseLandmark> landmarks) {

    // ── Step 1: Extract the four geometric anchors ────────────────────────────
    final PoseLandmark? leftShoulder =
        landmarks[PoseLandmarkType.leftShoulder];
    final PoseLandmark? rightShoulder =
        landmarks[PoseLandmarkType.rightShoulder];
    final PoseLandmark? leftHip = landmarks[PoseLandmarkType.leftHip];
    final PoseLandmark? rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return null;
    }

    // ── Step 2: Calculate mid-hip (translation origin) ────────────────────────
    final double midHipX = (leftHip.x + rightHip.x) / 2.0;
    final double midHipY = (leftHip.y + rightHip.y) / 2.0;

    // ── Step 3: Calculate torso length (scale denominator S) ──────────────────
    final double midShoulderX = (leftShoulder.x + rightShoulder.x) / 2.0;
    final double midShoulderY = (leftShoulder.y + rightShoulder.y) / 2.0;

    final double torsoLength = math.sqrt(
      math.pow(midShoulderX - midHipX, 2) +
          math.pow(midShoulderY - midHipY, 2),
    );

    // ── Guard: Abort if torso is not geometrically meaningful ─────────────────
    if (torsoLength < _minTorsoLengthThreshold) {
      return null;
    }

    // ── Refinement 2: Handle Camera Roll (Device Tilt) ────────────────────────
    // Calculate the angle of the shoulder line to determine device tilt.
    // We use left - right so that dx is positive when facing the camera.
    final double dxShoulders = leftShoulder.x - rightShoulder.x;
    final double dyShoulders = leftShoulder.y - rightShoulder.y;
    final double tiltAngle = math.atan2(dyShoulders, dxShoulders);
    
    final double cosTilt = math.cos(tiltAngle);
    final double sinTilt = math.sin(tiltAngle);

    // ── Step 4: Apply normalization to every landmark ─────────────────────────
    final Map<PoseLandmarkType, FrozenLandmark> normalized = {};

    for (final MapEntry<PoseLandmarkType, PoseLandmark> entry
        in landmarks.entries) {
      // 1. Translation (Mid-Hip Origin)
      final double tx = entry.value.x - midHipX;
      final double ty = entry.value.y - midHipY;
      
      // 2. Scaling (Torso-Length)
      final double sx = tx / torsoLength;
      final double sy = ty / torsoLength;

      // 3. Rotation (Subtract tilt angle to level the skeleton)
      // Rot(-tiltAngle):
      // x' = x * cos(tilt) + y * sin(tilt)
      // y' = -x * sin(tilt) + y * cos(tilt)
      final double rx = (sx * cosTilt) + (sy * sinTilt);
      final double ry = -(sx * sinTilt) + (sy * cosTilt);

      normalized[entry.key] = FrozenLandmark(
        x: rx,
        y: ry,
        likelihood: entry.value.likelihood,
      );
    }

    return normalized;
  }
}
