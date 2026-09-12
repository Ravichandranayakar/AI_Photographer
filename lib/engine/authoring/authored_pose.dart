import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/frozen_landmark.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EDR DECISION — Research Topic 07: Pose Authoring Pipeline
// ─────────────────────────────────────────────────────────────────────────────
//
// File: authored_pose.dart
// Layer: Pipeline Output Model
//
// DESIGN PRINCIPLE:
//   AuthoredPose is the sealed, immutable output of the entire 7-stage pipeline.
//   It contains BOTH the mathematical skeleton (normalizedLandmarks) AND all
//   metadata computed from it. PoseSerializer reads this to generate Dart code.
//
//   Immutability: once the pipeline produces an AuthoredPose, no stage can
//   mutate it. If the developer flips the mirror flag, the pipeline reruns
//   Stage 3–7 and produces a NEW AuthoredPose.
// ─────────────────────────────────────────────────────────────────────────────

/// Whether the full body was captured or only the upper body.
enum BodyCoverage {
  /// Both upper and lower body landmarks are visible (both ankles conf > 0.40).
  full,

  /// Only upper body landmarks are reliable. Lower body joints may be occluded.
  /// Stage 2 flags this. Engine 5 will only compare visible joints at runtime.
  half,
}

/// Rough orientation classification derived from normalized landmark geometry.
enum PoseOrientation { standing, sitting, kneeling, unknown }

/// Photographer's recommended camera setup derived from torso pixel ratio.
enum RecommendedCameraDistance {
  close,   // ~1.0m
  medium,  // ~2.0m
  far,     // ~3.5m
  veryFar, // >4.0m
}

/// Quality report from Stage 2 (Quality Gate).
@immutable
class QualityReport {
  final bool passed;
  final List<String> warnings;
  final bool rejected;
  final String? rejectionReason;

  const QualityReport({
    required this.passed,
    required this.warnings,
    required this.rejected,
    this.rejectionReason,
  });

  factory QualityReport.pass({List<String> warnings = const []}) =>
      QualityReport(passed: true, warnings: warnings, rejected: false);

  factory QualityReport.reject(String reason) => QualityReport(
        passed: false,
        warnings: const [],
        rejected: true,
        rejectionReason: reason,
      );
}

/// Geometry validation report from Stage 5.
@immutable
class GeometryReport {
  final bool passed;
  final List<String> warnings;
  const GeometryReport({required this.passed, required this.warnings});
}

/// Auto-computed joint angles for all major joints. Values in degrees [0–180].
/// Body-size invariant — same angle for a 5ft and 7ft subject in same pose.
@immutable
class JointAngles {
  final double leftElbow;
  final double rightElbow;
  final double leftKnee;
  final double rightKnee;
  final double leftShoulder;
  final double rightShoulder;

  const JointAngles({
    required this.leftElbow,
    required this.rightElbow,
    required this.leftKnee,
    required this.rightKnee,
    required this.leftShoulder,
    required this.rightShoulder,
  });
}

/// Center of Mass and balance assessment from Stage 6.
@immutable
class BalanceMetadata {
  final double comX;
  final double comY;

  /// true = CoM within support polygon (between the feet) → stable pose.
  /// false = dynamic/leaning pose.
  final bool isBalanced;

  const BalanceMetadata({
    required this.comX,
    required this.comY,
    required this.isBalanced,
  });
}

/// The immutable output of the complete 7-stage Pose Authoring Pipeline.
/// Consumed by [PoseSerializer] to generate the final Dart code snippet.
@immutable
class AuthoredPose {
  final String id;
  final String sourceImageName;
  final Map<PoseLandmarkType, FrozenLandmark> normalizedLandmarks;
  final QualityReport qualityReport;
  final GeometryReport geometryReport;
  final double correctedTiltDegrees;
  final BodyCoverage bodyCoverage;
  final PoseOrientation orientation;
  final RecommendedCameraDistance recommendedCameraDistance;
  final JointAngles jointAngles;
  final BalanceMetadata balance;
  final bool isSymmetric;
  final bool isMirrored;

  /// Auto-computed importance weight for each joint [0.30 – 1.50].
  /// Key: PoseLandmarkType.index. Higher = more critical for this specific pose.
  /// Engine 6 reads this at runtime instead of generic BoneRegistry weights.
  final Map<int, double> jointImportanceWeights;

  const AuthoredPose({
    required this.id,
    required this.sourceImageName,
    required this.normalizedLandmarks,
    required this.qualityReport,
    required this.geometryReport,
    required this.correctedTiltDegrees,
    required this.bodyCoverage,
    required this.orientation,
    required this.recommendedCameraDistance,
    required this.jointAngles,
    required this.balance,
    required this.isSymmetric,
    required this.isMirrored,
    required this.jointImportanceWeights,
  });
}
