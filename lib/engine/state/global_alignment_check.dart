// ─────────────────────────────────────────────────────────────────────────────
// State Machine — Step 4
// File: global_alignment_check.dart
// Layer: Gate Function — runs in GLOBAL_ALIGNMENT state only
//
// DESIGN PRINCIPLE:
//   GlobalAlignmentCheck is a pure, stateless gate function.
//   It receives the detected pose and target pose, and returns pass/fail
//   with a human-readable hint for the UI.
//
//   It also computes the Target Scale Factor (Q5 resolution):
//     scaleFactor = liveTorso / targetTorso clamped to [0.5, 2.0]
//   This is used by Engine B when rendering the target ghost outline.
//
// WHAT IT CHECKS:
//   1. Body orientation: is the user roughly facing the camera?
//   2. Torso tilt: is the torso roughly vertical?
//   3. Shoulder level: are shoulders roughly horizontal?
//   4. Whole-body position: is center-of-mass close to the target center?
//      (If off by more than repositionThreshold → reposition hint, not alignment failure)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'guidance_profile.dart';

/// Specific classification of WHY the alignment check passed or failed.
///
/// Engine 7 uses this to choose the correct visual indicator.
/// The state machine uses it to set the [StateMachineFrame.uiHint].
enum AlignmentStatus {
  /// All checks passed. Transition to [AppState.jointGuidance] is allowed.
  aligned,

  /// User's body is not fully visible — step back or adjust camera.
  notEnoughVisible,

  /// User appears to be turned sideways — instruct to face the camera.
  facingAway,

  /// User needs to turn slightly to their left (from camera's perspective).
  turnLeft,

  /// User needs to turn slightly to their right (from camera's perspective).
  turnRight,

  /// Shoulders are tilted — instruct to level shoulders.
  levelShoulders,

  /// Hips are tilted — instruct to level hips.
  levelHips,

  /// User is too far from camera — move closer.
  moveCloser,

  /// User is too close to camera — step back.
  stepBack,

  /// Whole body is off-center to the left — step to the right.
  stepRight,

  /// Whole body is off-center to the right — step to the left.
  stepLeft,
}

/// Rich result from a global alignment evaluation.
///
/// Replaces the old pass/fail + hint string model.
/// Engine 7 reads [status] to choose a visual indicator.
/// The state machine reads [passed] to decide if [AppState.jointGuidance] is allowed.
@immutable
class AlignmentResult {
  /// Specific classification of the alignment result.
  final AlignmentStatus status;

  /// True when [status] == [AlignmentStatus.aligned].
  /// Convenience getter — the state machine uses this for transition decisions.
  bool get passed => status == AlignmentStatus.aligned;

  /// Human-readable hint derived from [status].
  /// Engine 7 can display this as a text overlay.
  String get hint {
    switch (status) {
      case AlignmentStatus.aligned:        return '';
      case AlignmentStatus.notEnoughVisible: return 'Step back so your full body is visible';
      case AlignmentStatus.facingAway:     return 'Turn to face the camera';
      case AlignmentStatus.turnLeft:       return 'Turn slightly to your left';
      case AlignmentStatus.turnRight:      return 'Turn slightly to your right';
      case AlignmentStatus.levelShoulders: return 'Keep your shoulders level';
      case AlignmentStatus.levelHips:      return 'Keep your hips level';
      case AlignmentStatus.moveCloser:     return 'Step a little closer';
      case AlignmentStatus.stepBack:       return 'Step back a little';
      case AlignmentStatus.stepRight:      return 'Step to your right';
      case AlignmentStatus.stepLeft:       return 'Step to your left';
    }
  }

  /// Scale factor derived from the torso length ratio.
  /// Multiply target ghost offsets by this to scale to the user's body size.
  /// Formula: (liveTorso / targetTorso).clamp(0.5, 2.0)
  final double scaleFactor;

  /// Center-of-mass offset in normalized space [0.0–1.0].
  /// Used to trigger [CorrectionIntent.reposition] when above repositionThreshold.
  final double centerOfMassOffset;

  const AlignmentResult({
    required this.status,
    required this.scaleFactor,
    this.centerOfMassOffset = 0.0,
  });

  /// Convenience constructor for a passing result.
  const AlignmentResult.pass({
    required this.scaleFactor,
    this.centerOfMassOffset = 0.0,
  }) : status = AlignmentStatus.aligned;

  /// Convenience constructor for a failing result.
  const AlignmentResult.fail({
    required AlignmentStatus reason,
    required this.scaleFactor,
    this.centerOfMassOffset = 0.0,
  }) : status = reason;
}


/// Stateless gate function. Run every frame in [AppState.globalAlignment].
///
/// Check body orientation, torso verticality, and shoulder level before
/// allowing the state machine to enter [AppState.jointGuidance].
class GlobalAlignmentCheck {
  const GlobalAlignmentCheck();

  /// Evaluate the detected pose against the target normalized landmarks.
  ///
  /// [detectedPose] — ML Kit detected pose for the current frame.
  /// [targetTorsoNormalized] — target pose torso length in normalized units.
  ///   Stored as a constant in each TargetPose definition.
  ///   Default 0.25 matches the current FrozenLandmark coordinate system.
  /// [guidanceProfile] — contains repositionThreshold.
  AlignmentResult evaluate({
    required Pose detectedPose,
    double targetTorsoNormalized = 0.25,
    GuidanceProfile guidanceProfile = const GuidanceProfile(),
  }) {
    final landmarks = detectedPose.landmarks;

    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    // Guard: if core landmarks are missing, we cannot check alignment
    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null) {
      return const AlignmentResult.fail(
        reason: AlignmentStatus.notEnoughVisible,
        scaleFactor: 1.0,
      );
    }

    // ── Compute Scale Factor (Q5 resolution) ─────────────────────────────────
    final scaleFactor = _computeScaleFactor(
      leftShoulder: leftShoulder,
      rightShoulder: rightShoulder,
      leftHip: leftHip,
      rightHip: rightHip,
      targetTorsoNormalized: targetTorsoNormalized,
    );

    // ── Check 1: Shoulder width sanity (facing camera vs sideways) ──────────
    final shoulderWidth = (rightShoulder.x - leftShoulder.x).abs();
    final torsoHeight = _torsoHeight(
      leftShoulder: leftShoulder,
      rightShoulder: rightShoulder,
      leftHip: leftHip,
      rightHip: rightHip,
    );

    // If shoulders are very narrow relative to torso height, user is sideways
    if (shoulderWidth < torsoHeight * 0.25) {
      return AlignmentResult.fail(
        reason: AlignmentStatus.facingAway,
        scaleFactor: scaleFactor,
      );
    }

    // ── Check 2: Shoulder level (not heavily tilted) ─────────────────────────
    final shoulderTiltDeg = _angleDegrees(
      dx: rightShoulder.x - leftShoulder.x,
      dy: rightShoulder.y - leftShoulder.y,
    );
    if (shoulderTiltDeg.abs() > 20.0) {
      return AlignmentResult.fail(
        reason: AlignmentStatus.levelShoulders,
        scaleFactor: scaleFactor,
      );
    }

    // ── Check 3: Hip level (not heavily tilted) ───────────────────────────────
    final hipTiltDeg = _angleDegrees(
      dx: rightHip.x - leftHip.x,
      dy: rightHip.y - leftHip.y,
    );
    if (hipTiltDeg.abs() > 20.0) {
      return AlignmentResult.fail(
        reason: AlignmentStatus.levelHips,
        scaleFactor: scaleFactor,
      );
    }

    // ── Check 4: Whole-body center of mass (reposition gate) ─────────────────
    // Center-of-mass offset is returned but does NOT fail alignment.
    // The state machine can use it to emit CorrectionIntent.reposition.
    final userCenterX = (leftShoulder.x + rightShoulder.x + leftHip.x + rightHip.x) / 4;
    final userCenterY = (leftShoulder.y + rightShoulder.y + leftHip.y + rightHip.y) / 4;

    // Target center is assumed to be at 0.5, 0.5 in normalized space (centered in frame).
    // This is a simplification — Step 6 will refine this with actual target landmark position.
    final centerOffsetX = userCenterX - 0.5;
    final centerOffsetY = userCenterY - 0.5;
    final centerOfMassOffset = math.sqrt(centerOffsetX * centerOffsetX + centerOffsetY * centerOffsetY);

    // All checks passed.
    return AlignmentResult.pass(
      scaleFactor: scaleFactor,
      centerOfMassOffset: centerOfMassOffset,
    );
  }

  // ── Private Helpers ─────────────────────────────────────────────────────────

  /// Compute the scale factor using the torso length ratio.
  /// (Q5 resolution from frozen_ai_state_machine.md)
  double _computeScaleFactor({
    required PoseLandmark leftShoulder,
    required PoseLandmark rightShoulder,
    required PoseLandmark leftHip,
    required PoseLandmark rightHip,
    required double targetTorsoNormalized,
  }) {
    final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipMidX = (leftHip.x + rightHip.x) / 2;
    final hipMidY = (leftHip.y + rightHip.y) / 2;

    final dx = shoulderMidX - hipMidX;
    final dy = shoulderMidY - hipMidY;
    final liveTorso = math.sqrt(dx * dx + dy * dy);

    if (liveTorso < 0.01 || targetTorsoNormalized < 0.01) return 1.0;

    return (liveTorso / targetTorsoNormalized).clamp(0.5, 2.0);
  }

  double _torsoHeight({
    required PoseLandmark leftShoulder,
    required PoseLandmark rightShoulder,
    required PoseLandmark leftHip,
    required PoseLandmark rightHip,
  }) {
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipMidY = (leftHip.y + rightHip.y) / 2;
    return (hipMidY - shoulderMidY).abs();
  }

  /// Returns the absolute tilt angle in degrees relative to horizontal [0, 90].
  double _angleDegrees({required double dx, required double dy}) {
    return math.atan2(dy.abs(), dx.abs()) * 180 / math.pi;
  }
}
