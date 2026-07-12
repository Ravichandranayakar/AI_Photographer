import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Defines a single skeletal bone as a directed connection between two
/// ML Kit [PoseLandmarkType] joints, with its kinematic hierarchy weight.
///
/// A bone vector is: end_landmark.position - start_landmark.position.
/// This vector represents the direction and relative length of the bone,
/// which is the input to the Cosine Similarity calculation in [PoseMatcher].
class BoneDefinition {
  /// Human-readable name for logging and guidance (e.g., 'left_humerus').
  final String name;

  /// The proximal (closer to torso) landmark of this bone.
  final PoseLandmarkType startLandmark;

  /// The distal (further from torso) landmark of this bone.
  final PoseLandmarkType endLandmark;

  /// Kinematic hierarchy weight for the weighted score equation.
  ///
  /// Tiers (locked in EDR v3.2):
  ///   Core (spine, shoulders, hips): 0.5
  ///   Primary (humerus, femur):      0.3
  ///   Secondary (forearms, calves):  0.2
  final double weight;

  const BoneDefinition({
    required this.name,
    required this.startLandmark,
    required this.endLandmark,
    required this.weight,
  });
}

/// The complete, locked skeletal bone registry for the Frozen Intelligence Engine.
///
/// Defines every bone tracked during pose matching, organized by kinematic tier.
/// The weight matrix ensures structural integrity: a user cannot score highly
/// on a pose if their core alignment is wrong, even with perfect wrist positions.
///
/// EDR Reference: Research Decision 03_pose_matching
abstract final class BoneRegistry {
  static const double _coreWeight = 0.5;
  static const double _primaryWeight = 0.3;
  static const double _secondaryWeight = 0.2;

  /// All bones evaluated by the [PoseMatcher] on every frame.
  /// The list is ordered from core to extremities.
  static const List<BoneDefinition> all = [
    // ─────────────────────────────────────────────────────────────────
    // CORE TIER  (weight: 0.5)
    // The skeleton's rigid foundation. Misalignment here is fatal to the score.
    // ─────────────────────────────────────────────────────────────────
    BoneDefinition(
      name: 'clavicle',
      startLandmark: PoseLandmarkType.leftShoulder,
      endLandmark: PoseLandmarkType.rightShoulder,
      weight: _coreWeight,
    ),
    BoneDefinition(
      name: 'pelvis',
      startLandmark: PoseLandmarkType.leftHip,
      endLandmark: PoseLandmarkType.rightHip,
      weight: _coreWeight,
    ),
    BoneDefinition(
      name: 'left_torso',
      startLandmark: PoseLandmarkType.leftShoulder,
      endLandmark: PoseLandmarkType.leftHip,
      weight: _coreWeight,
    ),
    BoneDefinition(
      name: 'right_torso',
      startLandmark: PoseLandmarkType.rightShoulder,
      endLandmark: PoseLandmarkType.rightHip,
      weight: _coreWeight,
    ),

    // ─────────────────────────────────────────────────────────────────
    // PRIMARY TIER  (weight: 0.3)
    // Major limb segments. Verifies the broad shape of the pose.
    // ─────────────────────────────────────────────────────────────────
    BoneDefinition(
      name: 'left_humerus',
      startLandmark: PoseLandmarkType.leftShoulder,
      endLandmark: PoseLandmarkType.leftElbow,
      weight: _primaryWeight,
    ),
    BoneDefinition(
      name: 'right_humerus',
      startLandmark: PoseLandmarkType.rightShoulder,
      endLandmark: PoseLandmarkType.rightElbow,
      weight: _primaryWeight,
    ),
    BoneDefinition(
      name: 'left_femur',
      startLandmark: PoseLandmarkType.leftHip,
      endLandmark: PoseLandmarkType.leftKnee,
      weight: _primaryWeight,
    ),
    BoneDefinition(
      name: 'right_femur',
      startLandmark: PoseLandmarkType.rightHip,
      endLandmark: PoseLandmarkType.rightKnee,
      weight: _primaryWeight,
    ),

    // ─────────────────────────────────────────────────────────────────
    // SECONDARY TIER  (weight: 0.2)
    // Distal segments. Refines the score once core and primary are correct.
    // ─────────────────────────────────────────────────────────────────
    BoneDefinition(
      name: 'left_forearm',
      startLandmark: PoseLandmarkType.leftElbow,
      endLandmark: PoseLandmarkType.leftWrist,
      weight: _secondaryWeight,
    ),
    BoneDefinition(
      name: 'right_forearm',
      startLandmark: PoseLandmarkType.rightElbow,
      endLandmark: PoseLandmarkType.rightWrist,
      weight: _secondaryWeight,
    ),
    BoneDefinition(
      name: 'left_calf',
      startLandmark: PoseLandmarkType.leftKnee,
      endLandmark: PoseLandmarkType.leftAnkle,
      weight: _secondaryWeight,
    ),
    BoneDefinition(
      name: 'right_calf',
      startLandmark: PoseLandmarkType.rightKnee,
      endLandmark: PoseLandmarkType.rightAnkle,
      weight: _secondaryWeight,
    ),
  ];
}
