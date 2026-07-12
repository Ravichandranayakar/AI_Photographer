import 'package:flutter/foundation.dart';

/// The output of a single pose match computation from [PoseMatcher].
///
/// Contains the aggregated total score and granular per-bone data,
/// enabling both the Pose Score Engine (overall feedback) and the
/// Guidance Engine (per-joint coaching indicators) to operate independently.
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

  /// The sum of (weight * confidence) for all bones that passed the
  /// confidence gate in this frame.
  ///
  /// A value significantly below the theoretical maximum indicates heavy
  /// occlusion — used to de-prioritize the score display during poor visibility.
  final double effectiveWeight;

  const PoseMatchResult({
    required this.score,
    required this.boneScores,
    required this.effectiveWeight,
  });

  /// Returns true if the user's body is sufficiently visible to produce a
  /// reliable match score. Uses a threshold of 30% of the maximum possible weight.
  bool get isReliable => effectiveWeight > 0.3;

  @override
  String toString() =>
      'PoseMatchResult(score: ${(score * 100).toStringAsFixed(1)}%, '
      'effectiveWeight: ${effectiveWeight.toStringAsFixed(3)}, '
      'reliable: $isReliable)';
}
