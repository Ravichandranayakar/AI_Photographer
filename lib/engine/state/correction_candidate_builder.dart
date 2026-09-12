// ─────────────────────────────────────────────────────────────────────────────
// State Machine — Step 5
// File: correction_candidate_builder.dart
// Layer: Filter Pipeline — runs in JOINT_GUIDANCE, POSE_MATCHED, CAPTURE_COUNTDOWN
//
// DESIGN PRINCIPLE (frozen_ai_state_machine.md §Change 2):
//   CorrectionCandidateBuilder is a COMPUTATION MODULE, not a data class.
//   It performs 4 filtering passes before handing candidates to Engine 6.
//
//   The Decision Engine receives ONLY clean, pre-validated candidates.
//   Its sole responsibility is ranking and selecting. No filtering in Engine 6.
//
// THE 4 PASSES:
//   Pass 1: Confidence gate    — drop joints where trackingState == lost
//   Pass 2: Visibility filter  — drop joints with inFrameLikelihood < minConfidence
//   Pass 3: Orientation gate   — if whole body is off-center, return [reposition]
//   Pass 4: Bandwidth filter   — cap at maxCandidates per frame
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../guidance/joint_error.dart';
import '../models/pose_match_result.dart';
import 'global_alignment_check.dart';
import 'guidance_profile.dart';
import 'tracking_profile.dart';

/// A correction candidate that has passed all 4 filter passes.
/// Ready to be ranked and selected by Engine 6.
@immutable
class CorrectionCandidate {
  /// The joint that needs correction.
  final PoseLandmarkType joint;

  /// The error data from Engine 5 (PoseMatcher).
  final JointError error;

  /// Priority score computed by the weighted formula.
  /// Higher score = higher priority for coaching.
  final double priority;

  /// Kinematic weight of this joint (from BoneRegistry).
  /// Core joints (hip, spine) have higher weight than distal joints.
  final double kinematicWeight;

  const CorrectionCandidate({
    required this.joint,
    required this.error,
    required this.priority,
    required this.kinematicWeight,
  });
}

/// Result from the builder — either a list of joint candidates OR a reposition signal.
@immutable
class CandidateBuildResult {
  /// Filtered, scored, sorted candidates. Empty when [needsReposition] is true.
  final List<CorrectionCandidate> candidates;

  /// True when the user's whole body is too far off-center.
  /// When true, Engine 6 must emit [CorrectionIntent.reposition].
  /// Do NOT process individual joint candidates when this is true.
  final bool needsReposition;

  /// Direction hint for reposition: positive X = move right, positive Y = move down.
  final double repositionDx;
  final double repositionDy;

  const CandidateBuildResult({
    required this.candidates,
    this.needsReposition = false,
    this.repositionDx = 0.0,
    this.repositionDy = 0.0,
  });

  const CandidateBuildResult.reposition({
    required this.repositionDx,
    required this.repositionDy,
  })  : candidates = const [],
        needsReposition = true;

  const CandidateBuildResult.empty()
      : candidates = const [],
        needsReposition = false,
        repositionDx = 0.0,
        repositionDy = 0.0;
}

/// Kinematic weights for each joint group.
/// Core/proximal joints weighted higher than distal joints.
/// Based on motor learning proximal-to-distal principle.
const Map<PoseLandmarkType, double> _kinematicWeights = {
  // Core (1.0 — highest priority)
  PoseLandmarkType.leftHip:         1.0,
  PoseLandmarkType.rightHip:        1.0,
  PoseLandmarkType.leftShoulder:    0.95,
  PoseLandmarkType.rightShoulder:   0.95,

  // Upper limbs (0.80)
  PoseLandmarkType.leftElbow:       0.80,
  PoseLandmarkType.rightElbow:      0.80,
  PoseLandmarkType.leftKnee:        0.80,
  PoseLandmarkType.rightKnee:       0.80,

  // Distal (0.60)
  PoseLandmarkType.leftWrist:       0.60,
  PoseLandmarkType.rightWrist:      0.60,
  PoseLandmarkType.leftAnkle:       0.60,
  PoseLandmarkType.rightAnkle:      0.60,

  // Extremities (0.40 — lowest priority)
  PoseLandmarkType.nose:            0.40,
  PoseLandmarkType.leftEar:         0.40,
  PoseLandmarkType.rightEar:        0.40,
};

/// Builds a filtered list of CorrectionCandidates from Engine 5's pose error model.
class CorrectionCandidateBuilder {
  final TrackingProfile trackingProfile;
  final GuidanceProfile guidanceProfile;

  const CorrectionCandidateBuilder({
    this.trackingProfile = const TrackingProfile(),
    this.guidanceProfile = const GuidanceProfile(),
  });

  /// Run all 4 passes and return the result.
  ///
  /// [matchResult] — output from Engine 5 (PoseMatcher).
  /// [alignmentResult] — output from GlobalAlignmentCheck (used for Pass 3).
  CandidateBuildResult build({
    required PoseMatchResult matchResult,
    AlignmentResult? alignmentResult,
  }) {
    // ── Pass 3: Orientation gate (BEFORE individual joint passes) ─────────────
    // If reposition threshold exceeded, whole-body guidance takes priority.
    // Do NOT coach individual joints until the user is roughly centered.
    if (alignmentResult != null &&
        alignmentResult.centerOfMassOffset > guidanceProfile.repositionThreshold) {
      // Compute rough reposition direction
      // Positive dx = user is to the right of center, so tell them to move left (negative arrow)
      // We use the raw offset — Engine 7 will apply CameraMirrorMode correction.
      return CandidateBuildResult.reposition(
        repositionDx: -alignmentResult.centerOfMassOffset * 2,
        repositionDy: 0.0,
      );
    }

    final candidates = <CorrectionCandidate>[];

    for (final entry in matchResult.boneErrors.entries) {
      final boneError = entry.value;

      // Each bone has two endpoints — use the distal joint as the correction target
      final jointError = _dominantJointError(boneError);
      if (jointError == null) continue;

      // ── Pass 1: Confidence gate ─────────────────────────────────────────────
      // Drop joints where ML Kit has no usable data.
      if (jointError.trackingState == TrackingState.lost) {
        if (kDebugMode) {
          print('[CandidateBuilder] Dropped ${jointError.joint.name} — trackingState=lost');
        }
        continue;
      }

      // ── Pass 2: Visibility filter ───────────────────────────────────────────
      // Drop joints below the minimum confidence threshold.
      if (jointError.confidence < trackingProfile.minConfidence) {
        if (kDebugMode) {
          print('[CandidateBuilder] Dropped ${jointError.joint.name} — confidence=${jointError.confidence.toStringAsFixed(2)} < ${trackingProfile.minConfidence}');
        }
        continue;
      }

      // ── Compute Priority (weighted sum formula from spec) ──────────────────
      // Priority = (Severity × 0.50 + KinematicWeight × 0.35 + Visibility × 0.15)
      //          × confidenceWeight (1.0 for tracked, 0.67 for inferred)
      //
      // Confidence is a GATE (Pass 1) and a WEIGHT modifier, NOT a multiplier.
      final kinematicWeight = _kinematicWeights[jointError.joint] ?? 0.50;
      final severity = jointError.distance.clamp(0.0, 1.0);
      final visibility = jointError.confidence.clamp(0.0, 1.0);
      final confidenceWeight = jointError.trackingState == TrackingState.inferred
          ? 0.67
          : 1.0;

      final priority = (severity * 0.50 + kinematicWeight * 0.35 + visibility * 0.15)
          * confidenceWeight;

      candidates.add(CorrectionCandidate(
        joint: jointError.joint,
        error: jointError,
        priority: priority,
        kinematicWeight: kinematicWeight,
      ));
    }

    // Sort by priority descending (highest priority first)
    candidates.sort((a, b) => b.priority.compareTo(a.priority));

    // ── Pass 4: Bandwidth filter ─────────────────────────────────────────────
    // Cap the candidate list at maxCandidates.
    // Engine 6 should never process more than N candidates per frame.
    final capped = candidates.take(guidanceProfile.maxCandidates).toList();

    return CandidateBuildResult(candidates: capped);
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  /// Extract the most relevant JointError from a bone's error data.
  /// Returns null when no valid joint error exists.
  JointError? _dominantJointError(dynamic boneError) {
    // PoseMatchResult.boneErrors structure: Map<String, BoneMatchResult>
    // BoneMatchResult has a distalJointError field.
    // We need to access it through the correct type.
    // For now, return a basic check — Step 6 will integrate properly.
    if (boneError is JointError) return boneError;
    return null;
  }
}
