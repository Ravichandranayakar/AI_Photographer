import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'authored_pose.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EDR DECISION — Research Topic 07: Stage 2 — Quality Gate
// ─────────────────────────────────────────────────────────────────────────────
//
// Runs 3 independent checks in sequence. Fail-fast on hard rejections.
// Warnings are collected and attached to the QualityReport — they do NOT
// stop the pipeline; they inform the developer.
//
// Check 1 — Visibility  : Core joint confidence must exceed 0.85.
// Check 2 — Geometry    : Bone length ratios must be within human bounds.
//                         (WARN only — 2D projection causes foreshortening)
// Check 3 — Coverage    : Is the full body visible? Flags half-body poses.
// ─────────────────────────────────────────────────────────────────────────────
abstract final class PoseQualityGate {
  /// Minimum likelihood required for any CORE joint (hip/shoulder).
  static const double _coreConfidenceFloor = 0.85;

  /// Minimum likelihood for DISTAL joints (ankle/wrist) to count as visible.
  static const double _distalVisibilityFloor = 0.40;

  /// Human anatomical ratio bounds (validated against BlazePose benchmarks).
  /// upperArm / torso
  static const double _upperArmRatioMin = 0.40;
  static const double _upperArmRatioMax = 0.75;

  /// thigh / torso
  static const double _thighRatioMin = 0.65;
  static const double _thighRatioMax = 1.10;

  /// Runs all quality checks. Returns a [QualityReport] and detected [BodyCoverage].
  static ({QualityReport report, BodyCoverage coverage}) run(
    Map<PoseLandmarkType, PoseLandmark> rawLandmarks,
  ) {
    final warnings = <String>[];

    // ── Check 1: Visibility ─────────────────────────────────────────────────
    final leftShoulder = rawLandmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = rawLandmarks[PoseLandmarkType.rightShoulder];
    final leftHip = rawLandmarks[PoseLandmarkType.leftHip];
    final rightHip = rawLandmarks[PoseLandmarkType.rightHip];

    // Shoulders must be strictly visible (0.85)
    if (leftShoulder == null || leftShoulder.likelihood < _coreConfidenceFloor ||
        rightShoulder == null || rightShoulder.likelihood < _coreConfidenceFloor) {
      return (
        report: QualityReport.reject(
            'Shoulder below confidence floor. Ensure upper body is visible.'),
        coverage: BodyCoverage.half,
      );
    }

    // Hips can have lower confidence (0.30) to support waist-up photos where 
    // the hips are slightly outside the bottom of the camera frame.
    if (leftHip == null || leftHip.likelihood < 0.30 ||
        rightHip == null || rightHip.likelihood < 0.30) {
      return (
        report: QualityReport.reject(
            'Hips not found (likelihood < 0.30). Photo is cropped too high (headshot). '
            'The engine mathematically requires the torso length to work.'),
        coverage: BodyCoverage.half,
      );
    } 
    
    if (leftHip.likelihood < _coreConfidenceFloor || rightHip.likelihood < _coreConfidenceFloor) {
      warnings.add(
          'Hip confidence is low. '
          'Photo is likely cropped at the waist. Normalization will rely on ML Kit estimation.');
    }

    // ── Check 2: Geometry (WARN only) ───────────────────────────────────────
    // Variables leftShoulder, rightShoulder, leftHip, rightHip are non-null here.
    final leftElbow = rawLandmarks[PoseLandmarkType.leftElbow];
    final leftKnee = rawLandmarks[PoseLandmarkType.leftKnee];

    final midShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    final midShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final midHipX = (leftHip.x + rightHip.x) / 2;
    final midHipY = (leftHip.y + rightHip.y) / 2;

    final torsoLength = _dist(midShoulderX, midShoulderY, midHipX, midHipY);

    if (torsoLength < 1.0) {
      warnings.add(
          'Torso is very short in pixel space (px). '
          'Subject may be too far from camera.');
    }

    if (leftElbow != null && torsoLength > 1.0) {
      final upperArmLen =
          _dist(leftShoulder.x, leftShoulder.y, leftElbow.x, leftElbow.y);
      final ratio = upperArmLen / torsoLength;
      if (ratio < _upperArmRatioMin || ratio > _upperArmRatioMax) {
        warnings.add(
            'Left upper arm / torso ratio () is outside '
            'expected human bounds [ – ]. '
            'May be due to arm pointing toward/away from camera (foreshortening).');
      }
    }

    if (leftKnee != null && torsoLength > 1.0) {
      final thighLen =
          _dist(leftHip.x, leftHip.y, leftKnee.x, leftKnee.y);
      final ratio = thighLen / torsoLength;
      if (ratio < _thighRatioMin || ratio > _thighRatioMax) {
        warnings.add(
            'Left thigh / torso ratio () is outside '
            'expected human bounds [ – ]. '
            'May be a sitting pose or foreshortening from camera angle.');
      }
    }

    // ── Check 3: Coverage ───────────────────────────────────────────────────
    final leftAnkle = rawLandmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = rawLandmarks[PoseLandmarkType.rightAnkle];

    final anklesVisible =
        (leftAnkle?.likelihood ?? 0.0) >= _distalVisibilityFloor ||
            (rightAnkle?.likelihood ?? 0.0) >= _distalVisibilityFloor;

    final coverage = anklesVisible ? BodyCoverage.full : BodyCoverage.half;

    if (coverage == BodyCoverage.half) {
      warnings.add(
          'Ankle joints not visible (confidence < ). '
          'Flagging as HALF_BODY pose. Engine 5 will compare only visible joints.');
    }

    return (report: QualityReport.pass(warnings: warnings), coverage: coverage);
  }

  static double _dist(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }
}
