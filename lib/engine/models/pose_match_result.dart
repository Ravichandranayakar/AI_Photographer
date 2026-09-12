import 'package:flutter/foundation.dart';

import '../guidance/joint_error.dart';

/// The output of a single pose match computation from [PoseMatcher].
///
/// Contains the aggregated total score, per-bone similarity scores, and
/// the full [Pose Error Model] ([boneErrors]) enabling the Guidance Engine
/// (Engine 6) to calculate the Bottleneck joint and correction vector.
///
/// ─────────────────────────────────────────────────────────────────────────
/// EDR DECISION — Research Topic 06: Guidance Engine
/// ─────────────────────────────────────────────────────────────────────────
///
/// The [boneErrors] map is the contract between Engine 5 (Pose Comparison)
/// and Engine 6 (Decision Engine). Engine 5 populates it. Engine 6 reads it.
/// Neither Engine 7 nor the UI should ever access [boneErrors] directly.
/// ─────────────────────────────────────────────────────────────────────────
@immutable
class PoseMatchResult {
  /// The overall pose similarity score, clamped to [0.0 – 1.0].
  /// 0.0 = no match. 1.0 = perfect match.
  ///
  /// This value feeds into the Pose Score Engine for smoothing before
  /// display. It is NOT the raw value shown to the user.
  final double score;

  /// Per-bone similarity scores used by the Guidance Engine.
  ///
  /// Key: [BoneDefinition.name] (e.g., 'left_humerus').
  /// Value: Cosine similarity for that bone, mapped to [0.0 – 1.0].
  ///        0.0 means either a terrible match, OR the bone was confidence-gated.
  final Map<String, double> boneScores;

  /// The Pose Error Model — mathematical error vectors for every bone.
  ///
  /// Key: [BoneDefinition.name] (e.g., 'left_humerus').
  /// Value: [JointError] containing dx, dy, distance, confidence, frameIndex.
  ///
  /// This is the primary input to Engine 6 (Decision Engine). It carries
  /// not just HOW BAD a joint is, but exactly WHICH DIRECTION and HOW FAR
  /// it needs to move to reach the target pose.
  ///
  /// Will be an empty map if the frame was fully confidence-gated.
  final Map<String, JointError> boneErrors;

  /// The sum of (weight * confidence) for all bones that passed the
  /// confidence gate in this frame.
  ///
  /// A value significantly below the theoretical maximum indicates heavy
  /// occlusion — used to de-prioritize the score display during poor visibility.
  final double effectiveWeight;

  const PoseMatchResult({
    required this.score,
    required this.boneScores,
    required this.boneErrors,
    required this.effectiveWeight,
  });

  /// Returns true if the user's body is sufficiently visible to produce a
  /// reliable match score. Uses a threshold of 30% of the maximum possible weight.
  bool get isReliable => effectiveWeight > 0.3;

  @override
  String toString() =>
      'PoseMatchResult(score: ${(score * 100).toStringAsFixed(1)}%, '
      'bones: ${boneScores.length}, '
      'errors: ${boneErrors.length}, '
      'effectiveWeight: ${effectiveWeight.toStringAsFixed(3)}, '
      'reliable: $isReliable)';
}
