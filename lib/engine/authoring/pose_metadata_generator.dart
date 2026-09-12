import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/frozen_landmark.dart';
import 'authored_pose.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EDR DECISION — Research Topic 07: Stage 6 — Metadata Generator
// ─────────────────────────────────────────────────────────────────────────────
//
// Derives ALL metadata automatically from the normalized skeleton.
// No manual tagging. Every field has a deterministic mathematical derivation.
//
// Operates on NORMALIZED FrozenLandmarks (post Stage 4).
//
// Outputs:
//   6.1 JointAngles       — body-size invariant angles at each major joint
//   6.2 BalanceMetadata   — CoM position and support polygon check
//   6.3 PoseOrientation   — standing / sitting / kneeling / unknown
//   6.4 Camera Distance   — derived from raw pixel torso/image ratio
//   6.5 Mirror + Symmetry — geometric symmetry of the skeleton
//   6.6 Joint Importance  — how much each joint deviates from neutral
// ─────────────────────────────────────────────────────────────────────────────

/// Full result of Stage 6.
class PoseMetadata {
  final JointAngles jointAngles;
  final BalanceMetadata balance;
  final PoseOrientation orientation;
  final RecommendedCameraDistance recommendedCameraDistance;
  final bool isSymmetric;
  final bool isMirrored;
  final Map<int, double> jointImportanceWeights;

  const PoseMetadata({
    required this.jointAngles,
    required this.balance,
    required this.orientation,
    required this.recommendedCameraDistance,
    required this.isSymmetric,
    required this.isMirrored,
    required this.jointImportanceWeights,
  });
}

abstract final class PoseMetadataGenerator {
  /// Generates all metadata from normalized landmarks + raw image dimensions.
  ///
  /// [normalizedLandmarks]: output of LandmarkNormalizer.normalize().
  /// [rawTorsoPixelLength]: dist(midShoulder_raw, midHip_raw) in pixels.
  ///   Used for camera distance estimation (6.4).
  /// [imageHeight]: original image height in pixels. Used for camera distance.
  static PoseMetadata generate({
    required Map<PoseLandmarkType, FrozenLandmark> normalizedLandmarks,
    required double rawTorsoPixelLength,
    required double imageHeight,
  }) {
    return PoseMetadata(
      jointAngles: _computeJointAngles(normalizedLandmarks),
      balance: _computeBalance(normalizedLandmarks),
      orientation: _classifyOrientation(normalizedLandmarks),
      recommendedCameraDistance:
          _estimateCameraDistance(rawTorsoPixelLength, imageHeight),
      isSymmetric: _computeSymmetry(normalizedLandmarks),
      isMirrored: _detectMirror(normalizedLandmarks),
      jointImportanceWeights:
          _computeJointImportanceWeights(normalizedLandmarks),
    );
  }

  // ── 6.1: Joint Angles ─────────────────────────────────────────────────────
  // Uses the dot product formula: angle = acos(a · b) where a,b are unit vectors.
  // The angle is between vector (parent→joint) and vector (joint→child).
  static JointAngles _computeJointAngles(
      Map<PoseLandmarkType, FrozenLandmark> lms) {
    return JointAngles(
      leftElbow: _angle(
        lms[PoseLandmarkType.leftShoulder],
        lms[PoseLandmarkType.leftElbow],
        lms[PoseLandmarkType.leftWrist],
      ),
      rightElbow: _angle(
        lms[PoseLandmarkType.rightShoulder],
        lms[PoseLandmarkType.rightElbow],
        lms[PoseLandmarkType.rightWrist],
      ),
      leftKnee: _angle(
        lms[PoseLandmarkType.leftHip],
        lms[PoseLandmarkType.leftKnee],
        lms[PoseLandmarkType.leftAnkle],
      ),
      rightKnee: _angle(
        lms[PoseLandmarkType.rightHip],
        lms[PoseLandmarkType.rightKnee],
        lms[PoseLandmarkType.rightAnkle],
      ),
      leftShoulder: _angle(
        // Torso axis as parent: midHip → leftShoulder, then leftShoulder → leftElbow
        FrozenLandmark(x: 0.0, y: 0.0, likelihood: 1.0), // mid-hip = origin
        lms[PoseLandmarkType.leftShoulder],
        lms[PoseLandmarkType.leftElbow],
      ),
      rightShoulder: _angle(
        FrozenLandmark(x: 0.0, y: 0.0, likelihood: 1.0),
        lms[PoseLandmarkType.rightShoulder],
        lms[PoseLandmarkType.rightElbow],
      ),
    );
  }

  /// Returns the angle at [joint] in the triplet [parent → joint → child],
  /// in degrees [0–180]. Returns 180.0 (straight) if any landmark is null.
  static double _angle(
    FrozenLandmark? parent,
    FrozenLandmark? joint,
    FrozenLandmark? child,
  ) {
    if (parent == null || joint == null || child == null) return 180.0;

    // Vector A: parent → joint
    final ax = joint.x - parent.x;
    final ay = joint.y - parent.y;
    // Vector B: joint → child
    final bx = child.x - joint.x;
    final by = child.y - joint.y;

    final magA = math.sqrt(ax * ax + ay * ay);
    final magB = math.sqrt(bx * bx + by * by);

    if (magA < 1e-6 || magB < 1e-6) return 180.0;

    final dot = (ax * bx + ay * by) / (magA * magB);
    // Clamp to [-1, 1] to guard against floating-point errors before acos.
    final clamped = dot.clamp(-1.0, 1.0);
    return math.acos(clamped) * (180.0 / math.pi);
  }

  // ── 6.2: Balance & Center of Mass ─────────────────────────────────────────
  // Volume-weighted average of body segment midpoints.
  // Weights derived from standard biomechanical body segment mass ratios.
  static BalanceMetadata _computeBalance(
      Map<PoseLandmarkType, FrozenLandmark> lms) {
    // Body segment weights (simplified 2D, sum = 1.0)
    // Torso: 0.43, Each Leg: 0.16, Each Arm: 0.06, Head: 0.08 (nose)
    const segments = [
      // [weight, joint1Type, joint2Type]  — CoM = midpoint(joint1, joint2)
      [0.43, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip], // torso
      [0.16, PoseLandmarkType.leftHip, PoseLandmarkType.leftAnkle],    // left leg
      [0.16, PoseLandmarkType.rightHip, PoseLandmarkType.rightAnkle],  // right leg
      [0.06, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftWrist], // left arm
      [0.06, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightWrist], // right arm
    ];

    double comX = 0.0;
    double comY = 0.0;
    double totalWeight = 0.0;

    for (final seg in segments) {
      final weight = seg[0] as double;
      final j1 = lms[seg[1] as PoseLandmarkType];
      final j2 = lms[seg[2] as PoseLandmarkType];
      if (j1 != null && j2 != null) {
        comX += weight * (j1.x + j2.x) / 2.0;
        comY += weight * (j1.y + j2.y) / 2.0;
        totalWeight += weight;
      }
    }

    // Head CoM (nose = head approximate center)
    final nose = lms[PoseLandmarkType.nose];
    if (nose != null) {
      comX += 0.08 * nose.x;
      comY += 0.08 * nose.y;
      totalWeight += 0.08;
    }

    if (totalWeight > 0) {
      comX /= totalWeight;
      comY /= totalWeight;
    }

    // Balance: CoM.x must lie between the two ankles' x coordinates.
    final leftAnkle = lms[PoseLandmarkType.leftAnkle];
    final rightAnkle = lms[PoseLandmarkType.rightAnkle];
    bool isBalanced = true;

    if (leftAnkle != null && rightAnkle != null) {
      final minX = math.min(leftAnkle.x, rightAnkle.x);
      final maxX = math.max(leftAnkle.x, rightAnkle.x);
      // Add a 0.1 torso-unit tolerance for nearly-balanced poses.
      isBalanced = comX >= (minX - 0.1) && comX <= (maxX + 0.1);
    }

    return BalanceMetadata(comX: comX, comY: comY, isBalanced: isBalanced);
  }

  // ── 6.3: Orientation Classification ──────────────────────────────────────
  static PoseOrientation _classifyOrientation(
      Map<PoseLandmarkType, FrozenLandmark> lms) {
    final leftAnkle = lms[PoseLandmarkType.leftAnkle];
    final rightAnkle = lms[PoseLandmarkType.rightAnkle];
    final leftKnee = lms[PoseLandmarkType.leftKnee];
    final rightKnee = lms[PoseLandmarkType.rightKnee];

    if (leftAnkle == null && rightAnkle == null) {
      // No ankle data → cannot determine
      return PoseOrientation.unknown;
    }

    final ankleY = ((leftAnkle?.y ?? 0) + (rightAnkle?.y ?? 0)) / 2.0;
    final kneeY = ((leftKnee?.y ?? 0) + (rightKnee?.y ?? 0)) / 2.0;

    // Standing: ankles are far below hips (positive Y > 1.2 torso-units)
    if (ankleY > 1.2) return PoseOrientation.standing;

    // Kneeling: one ankle near ground, one knee near ground, but ankleY < 1.2
    final kneeAnkleGap = (ankleY - kneeY).abs();
    if (kneeAnkleGap < 0.3 && ankleY > 0.5) return PoseOrientation.kneeling;

    // Sitting: ankles are close to hip level
    if (ankleY < 0.8) return PoseOrientation.sitting;

    return PoseOrientation.unknown;
  }

  // ── 6.4: Camera Distance Estimate ─────────────────────────────────────────
  // torsoBodyRatio = rawTorsoPixelLength / imageHeight
  // Calibrated from empirical testing: a full-body portrait at 2m on a standard
  // phone (1080×1920) yields torso ≈ 350px → ratio ≈ 0.18.
  static RecommendedCameraDistance _estimateCameraDistance(
    double rawTorsoPixelLength,
    double imageHeight,
  ) {
    if (imageHeight <= 0) return RecommendedCameraDistance.medium;

    final ratio = rawTorsoPixelLength / imageHeight;

    if (ratio > 0.45) return RecommendedCameraDistance.close;
    if (ratio > 0.25) return RecommendedCameraDistance.medium;
    if (ratio > 0.10) return RecommendedCameraDistance.far;
    return RecommendedCameraDistance.veryFar;
  }

  // ── 6.5: Mirror and Symmetry Detection ───────────────────────────────────
  // In normalized space, a perfectly symmetric pose has:
  //   leftShoulder.x + rightShoulder.x ≈ 0.0  (they cancel out around origin)
  static bool _computeSymmetry(Map<PoseLandmarkType, FrozenLandmark> lms) {
    final ls = lms[PoseLandmarkType.leftShoulder];
    final rs = lms[PoseLandmarkType.rightShoulder];
    final lh = lms[PoseLandmarkType.leftHip];
    final rh = lms[PoseLandmarkType.rightHip];

    if (ls == null || rs == null || lh == null || rh == null) return false;

    final shoulderSum = (ls.x + rs.x).abs();
    final hipSum = (lh.x + rh.x).abs();

    // Symmetric if both sums are within 0.05 torso-units of zero.
    return shoulderSum < 0.05 && hipSum < 0.05;
  }

  // In our normalized space, left side (subject's left) has positive X.
  // If the right wrist has positive X, the subject's right arm is on the
  // positive side — the pose may have been captured mirror-reversed.
  static bool _detectMirror(Map<PoseLandmarkType, FrozenLandmark> lms) {
    final leftWrist = lms[PoseLandmarkType.leftWrist];
    final rightWrist = lms[PoseLandmarkType.rightWrist];

    if (leftWrist == null || rightWrist == null) return false;

    // Expected: leftWrist.x > rightWrist.x (left side = positive X in our system)
    // If the opposite is true, pose is likely mirrored.
    return rightWrist.x > leftWrist.x;
  }

  // ── 6.6: Joint Importance Weights ─────────────────────────────────────────
  // Algorithm:
  //   1. Define neutral T-pose positions in normalized space.
  //   2. For each joint, compute displacement from neutral.
  //   3. Normalize all displacements to [0.0 – 1.0].
  //   4. importanceWeight = 0.30 + (0.70 * normalizedDisplacement)
  //      (floor of 0.30: no joint is ever fully ignored)
  //   5. Apply 1.5x boost for core joints (hip, shoulder).
  static Map<int, double> _computeJointImportanceWeights(
      Map<PoseLandmarkType, FrozenLandmark> lms) {
    // T-pose neutral positions in normalized space (torso-length units).
    // These are approximate reference positions for a person standing arms-out.
    const neutralPositions = <PoseLandmarkType, (double, double)>{
      PoseLandmarkType.leftShoulder:  (0.30, -1.00),
      PoseLandmarkType.rightShoulder: (-0.30, -1.00),
      PoseLandmarkType.leftElbow:     (0.70, -1.00),
      PoseLandmarkType.rightElbow:    (-0.70, -1.00),
      PoseLandmarkType.leftWrist:     (1.10, -1.00),
      PoseLandmarkType.rightWrist:    (-1.10, -1.00),
      PoseLandmarkType.leftHip:       (0.18, 0.00),
      PoseLandmarkType.rightHip:      (-0.18, 0.00),
      PoseLandmarkType.leftKnee:      (0.18, 0.90),
      PoseLandmarkType.rightKnee:     (-0.18, 0.90),
      PoseLandmarkType.leftAnkle:     (0.18, 1.80),
      PoseLandmarkType.rightAnkle:    (-0.18, 1.80),
    };

    const coreJoints = {
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    };

    final displacements = <PoseLandmarkType, double>{};

    for (final entry in neutralPositions.entries) {
      final lm = lms[entry.key];
      if (lm == null) continue;

      final nx = entry.value.$1;
      final ny = entry.value.$2;
      final dx = lm.x - nx;
      final dy = lm.y - ny;
      displacements[entry.key] = math.sqrt(dx * dx + dy * dy);
    }

    if (displacements.isEmpty) return {};

    // Normalize to [0, 1]
    final maxDisp = displacements.values.reduce(math.max);
    if (maxDisp < 1e-6) {
      // All joints at neutral — flat importance
      return displacements
          .map((type, _) => MapEntry(type.index, 0.30));
    }

    final weights = <int, double>{};
    for (final entry in displacements.entries) {
      final normalized = entry.value / maxDisp;
      double weight = 0.30 + (0.70 * normalized);

      if (coreJoints.contains(entry.key)) {
        weight = (weight * 1.5).clamp(0.30, 1.50);
      } else {
        weight = weight.clamp(0.30, 1.00);
      }

      weights[entry.key.index] = weight;
    }

    return weights;
  }
}
