import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Defines the category of movement dynamics for a joint.
enum FilterProfile {
  core,
  primary,
  extremity,
}

/// Holds the tuning parameters for the 1 Euro Filter.
class FilterConfig {
  final double minCutoff;
  final double beta;
  final double derivativeCutoff;

  const FilterConfig({
    required this.minCutoff,
    required this.beta,
    this.derivativeCutoff = 1.0,
  });
}

/// Maps physical human joints to their mathematical smoothing profiles.
abstract final class JointProfileRegistry {
  /// Production Configuration v1.0 — Validated by Benchmark Suite 1 (2026-07-09)
  /// Core (Hip) variance met target threshold (0.000003 < 0.005).
  /// Extremity dynamic range confirmed no perceptible lag (range = 1.6003).
  /// Do NOT modify without re-running Benchmark Suite 1 and logging results in tuning.md.
  static const Map<FilterProfile, FilterConfig> profiles = {
    FilterProfile.core: FilterConfig(minCutoff: 0.1, beta: 0.005),
    FilterProfile.primary: FilterConfig(minCutoff: 0.5, beta: 0.01),
    FilterProfile.extremity: FilterConfig(minCutoff: 1.0, beta: 0.05),
  };

  static FilterProfile getProfileForJoint(PoseLandmarkType type) {
    switch (type) {
      // Core Anchors: Need maximum stability to anchor the Normalizer scale/translation.
      case PoseLandmarkType.leftShoulder:
      case PoseLandmarkType.rightShoulder:
      case PoseLandmarkType.leftHip:
      case PoseLandmarkType.rightHip:
        return FilterProfile.core;
      
      // Primary: Balanced.
      case PoseLandmarkType.leftElbow:
      case PoseLandmarkType.rightElbow:
      case PoseLandmarkType.leftKnee:
      case PoseLandmarkType.rightKnee:
        return FilterProfile.primary;
        
      // Extremities: Fast moving, prioritize zero lag over perfect smoothness.
      case PoseLandmarkType.leftWrist:
      case PoseLandmarkType.rightWrist:
      case PoseLandmarkType.leftAnkle:
      case PoseLandmarkType.rightAnkle:
      case PoseLandmarkType.leftHeel:
      case PoseLandmarkType.rightHeel:
      case PoseLandmarkType.leftFootIndex:
      case PoseLandmarkType.rightFootIndex:
      case PoseLandmarkType.leftPinky:
      case PoseLandmarkType.rightPinky:
      case PoseLandmarkType.leftIndex:
      case PoseLandmarkType.rightIndex:
      case PoseLandmarkType.leftThumb:
      case PoseLandmarkType.rightThumb:
        return FilterProfile.extremity;
        
      // Face / Default
      default:
        return FilterProfile.primary;
    }
  }

  static FilterConfig getConfigForJoint(PoseLandmarkType type) {
    return profiles[getProfileForJoint(type)]!;
  }
}
