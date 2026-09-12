// ─────────────────────────────────────────────────────────────────────────────
// State Machine — Pre-Step 7 Addition
// File: pose_context.dart
// Layer: Shared Context Object — passed to all engines
//
// DESIGN PRINCIPLE (GPT review recommendation — accepted):
//   Without PoseContext, every engine call needs 4-5 individual parameters.
//   As more pose categories are added (wedding, gym, seated, couple), the
//   method signatures become unmanageable.
//
//   PoseContext is the single object that flows through the entire engine pipeline:
//     PoseContext → Engine 5 → Engine 6 → CorrectionCandidateBuilder → Engine 7
//
//   Every engine reads what it needs from PoseContext.
//   Adding a new parameter means adding it to PoseContext ONCE, not to every
//   method signature.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'tracking_profile.dart';
import 'guidance_profile.dart';
import '../guidance/guidance_config.dart';

/// Broad classification of a pose for profile selection and coaching tone.
enum PoseCategory {
  /// Standard upright standing portrait.
  standingPortrait,

  /// User is seated (chair, floor, bench).
  seated,

  /// High-stretch / yoga / flexibility poses.
  yoga,

  /// Dance / dynamic / high-motion poses.
  dance,

  /// Couple or group poses (future — single-subject tracking still applies).
  group,

  /// Custom / uncategorized pose.
  custom,
}

/// Approximate expected camera-to-subject distance.
/// Used by [GlobalAlignmentCheck] to calibrate the target torso scale.
enum CameraDistance {
  /// Full body visible — typical standing portrait.
  /// Approximate: 2.5m – 4m from subject.
  fullBody,

  /// Waist-up / half body visible.
  /// Approximate: 1.5m – 2.5m from subject.
  halfBody,

  /// Head and shoulders only — headshot or close portrait.
  /// Approximate: 0.8m – 1.5m from subject.
  closeUp,
}

/// The shared context object that flows through the entire engine pipeline.
///
/// Create one [PoseContext] when the user selects a pose and confirms Start.
/// Pass the same instance to every engine call — do not create per-frame.
///
/// Usage:
/// ```dart
/// final ctx = PoseContext(
///   poseId: 'pose_001_standing_arms_out',
///   category: PoseCategory.standingPortrait,
///   distance: CameraDistance.fullBody,
///   difficulty: 0.3,
///   targetLandmarks: loadedTargetPose.landmarks,
/// );
///
/// // Pass to engines:
/// final matchResult = poseMatcher.compare(livePose, ctx);
/// final alignResult = alignmentCheck.evaluate(livePose, ctx);
/// final candidates  = candidateBuilder.build(matchResult, ctx);
/// final signal      = decisionEngine.evaluate(candidates, ctx);
/// ```
@immutable
class PoseContext {
  // ── Identification ──────────────────────────────────────────────────────────

  /// Unique identifier for the selected pose.
  /// Matches the key in TargetPose JSON definitions.
  final String poseId;

  /// Human-readable display name of the pose.
  final String poseName;

  /// Broad category — used to auto-select [TrackingProfile] and [GuidanceProfile]
  /// when no explicit override is provided.
  final PoseCategory category;

  /// Expected camera-to-subject distance for this pose.
  /// Used to calibrate the target torso scale in [GlobalAlignmentCheck].
  final CameraDistance distance;

  /// Pose difficulty score [0.0–1.0].
  /// 0.0 = very easy (basic standing). 1.0 = very complex (advanced yoga).
  /// Future: can influence [GuidanceProfile.bandwidthThreshold] dynamically.
  final double difficulty;

  // ── Target Skeleton ─────────────────────────────────────────────────────────

  /// The target pose landmarks in normalized coordinate space.
  /// Loaded from the TargetPose JSON at pose selection time.
  /// Used by Engine 5 (PoseMatcher) and GlobalAlignmentCheck.
  final Map<PoseLandmarkType, PoseLandmark> targetLandmarks;

  /// Target torso length in normalized coordinate space.
  /// Pre-computed from [targetLandmarks] to avoid per-frame recomputation.
  /// Used by [GlobalAlignmentCheck] to compute the live-to-target scale factor.
  final double targetTorsoNormalized;

  // ── Engine Configuration ────────────────────────────────────────────────────

  /// Tracking configuration for this pose session.
  /// If null, the default [TrackingProfile] for [category] is used.
  final TrackingProfile trackingProfile;

  /// Guidance session configuration for this pose.
  /// If null, the default [GuidanceProfile] for [category] is used.
  final GuidanceProfile guidanceProfile;

  /// Engine 6 scoring configuration.
  /// If null, the default [GuidanceConfig] for [category] is used.
  final GuidanceConfig guidanceConfig;

  const PoseContext({
    required this.poseId,
    required this.poseName,
    required this.category,
    required this.distance,
    required this.targetLandmarks,
    this.difficulty = 0.3,
    this.targetTorsoNormalized = 0.25,
    this.trackingProfile = const TrackingProfile(),
    this.guidanceProfile = const GuidanceProfile(),
    this.guidanceConfig = const GuidanceConfig(),
  });

  /// Create a PoseContext with profiles auto-selected from [category].
  factory PoseContext.fromCategory({
    required String poseId,
    required String poseName,
    required PoseCategory category,
    required CameraDistance distance,
    required Map<PoseLandmarkType, PoseLandmark> targetLandmarks,
    double difficulty = 0.3,
    double targetTorsoNormalized = 0.25,
  }) {
    final trackingProfile = _trackingProfileFor(category);
    final guidanceProfile = _guidanceProfileFor(category);
    final guidanceConfig  = _guidanceConfigFor(category);

    return PoseContext(
      poseId: poseId,
      poseName: poseName,
      category: category,
      distance: distance,
      targetLandmarks: targetLandmarks,
      difficulty: difficulty,
      targetTorsoNormalized: targetTorsoNormalized,
      trackingProfile: trackingProfile,
      guidanceProfile: guidanceProfile,
      guidanceConfig: guidanceConfig,
    );
  }

  // ── Profile Auto-Selection ─────────────────────────────────────────────────

  static TrackingProfile _trackingProfileFor(PoseCategory category) {
    switch (category) {
      case PoseCategory.seated:
        return const TrackingProfile(
          minVisibleJoints: 7,  // lower body may be occluded by furniture
          minConfidence: 0.65,
        );
      default:
        return const TrackingProfile(); // portrait defaults
    }
  }

  static GuidanceProfile _guidanceProfileFor(PoseCategory category) {
    switch (category) {
      case PoseCategory.yoga:
        return const GuidanceProfile(
          repositionThreshold: 0.12, // tighter centering for yoga
        );
      case PoseCategory.dance:
        return const GuidanceProfile(
          repositionThreshold: 0.20, // wider tolerance for dynamic poses
        );
      default:
        return const GuidanceProfile(); // portrait defaults
    }
  }

  static GuidanceConfig _guidanceConfigFor(PoseCategory category) {
    switch (category) {
      case PoseCategory.yoga:    return GuidanceConfig.yoga;
      case PoseCategory.dance:   return GuidanceConfig.dance;
      default:                   return GuidanceConfig.portrait;
    }
  }
}
