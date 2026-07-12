import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/bone_registry.dart';
import '../models/frozen_landmark.dart';
import '../models/pose_match_result.dart';

/// Computes the similarity score between a normalized user pose and a
/// normalized target pose using Kinematic Hierarchical Weighting and
/// Confidence Gating.
///
/// ─────────────────────────────────────────────────────────────────────────────
/// EDR DECISION — Research Topic 03: Pose Similarity
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Decision: Hybrid Cosine Similarity with Kinematic Hierarchical Weights
///           and Confidence Gating.
///
/// Why NOT pure Euclidean Distance:
///   Euclidean distance compares joint positions in space. After normalization,
///   small residual differences in body proportions between people still produce
///   large Euclidean penalties at distal joints (wrists, ankles), even when the
///   pose direction is correct. This creates false negatives.
///
/// Why NOT pure Cosine Similarity alone:
///   Cosine similarity on bone vectors is immune to scale. It only measures
///   whether a bone is pointing in the same direction as the target. However,
///   without weighting, a correct wrist position compensates for a broken spine.
///
/// Why THIS hybrid approach wins:
///   1. Confidence Gating: ML Kit will guess occluded joint positions at low
///      confidence. Including these corrupts the score. By setting a threshold
///      τ = 0.5 and excising low-confidence bones from the denominator, we
///      only score what the camera can actually see.
///
///   2. Kinematic Hierarchical Weights: The core is assigned 2.5x the weight
///      of secondary joints. A user cannot reach 90% similarity with a broken
///      spine and perfect wrist positions. Structural integrity is enforced.
///
/// Locked Math:
///
///   For each bone i (defined as a vector from start to end landmark):
///     u_i = (user_end - user_start) in normalized space
///     t_i = (target_end - target_start) in normalized space
///
///   Cosine Similarity:
///     S_i = (u_i · t_i) / (‖u_i‖ * ‖t_i‖)         ∈ [-1, 1]
///
///   Mapped to [0, 1]:
///     S'_i = (S_i + 1) / 2
///
///   Bone confidence (mean of its two joints):
///     c_i = (likelihood(start) + likelihood(end)) / 2
///
///   Gate: If c_i < τ (0.5), this bone is excised (weight set to 0).
///
///   Final weighted score:
///     TotalScore = Σ(w_i * c_i * S'_i) / Σ(w_i * c_i)
///
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class PoseMatcher {
  /// Confidence gate threshold (τ).
  /// Bones where mean joint confidence falls below this value are excluded
  /// from both the numerator and denominator of the score equation.
  static const double _confidenceThreshold = 0.5;

  /// Minimum vector magnitude to consider a bone geometrically valid.
  /// Prevents division by zero for degenerate zero-length bone vectors.
  static const double _minVectorMagnitude = 1e-9;

  /// Computes the [PoseMatchResult] for a single frame.
  ///
  /// Both [userLandmarks] and [targetLandmarks] MUST be the output of
  /// [LandmarkNormalizer.normalize] before being passed here. Passing raw
  /// ML Kit pixel coordinates will produce incorrect results.
  ///
  /// Returns a [PoseMatchResult] with the total score and per-bone data.
  static PoseMatchResult compute({
    required Map<PoseLandmarkType, FrozenLandmark> userLandmarks,
    required Map<PoseLandmarkType, FrozenLandmark> targetLandmarks,
  }) {
    double weightedScoreNumerator = 0.0;
    double weightedScoreDenominator = 0.0;
    final Map<String, double> boneScores = {};

    for (final BoneDefinition bone in BoneRegistry.all) {
      // ── Fetch normalized landmarks for this bone ────────────────────────────
      final FrozenLandmark? userStart = userLandmarks[bone.startLandmark];
      final FrozenLandmark? userEnd = userLandmarks[bone.endLandmark];
      final FrozenLandmark? targetStart = targetLandmarks[bone.startLandmark];
      final FrozenLandmark? targetEnd = targetLandmarks[bone.endLandmark];

      // Skip entirely if any landmark is absent (should not occur post-validation).
      if (userStart == null ||
          userEnd == null ||
          targetStart == null ||
          targetEnd == null) {
        boneScores[bone.name] = 0.0;
        continue;
      }

      // ── Confidence Gating ───────────────────────────────────────────────────
      // c_i = (likelihood(start) + likelihood(end)) / 2
      final double boneConfidence =
          (userStart.likelihood + userEnd.likelihood) / 2.0;

      // Excise bone from scoring if confidence is below threshold τ.
      if (boneConfidence < _confidenceThreshold) {
        boneScores[bone.name] = 0.0;
        continue;
      }

      // ── Compute Bone Vectors ────────────────────────────────────────────────
      // u_i = (user_end - user_start)
      // t_i = (target_end - target_start)
      final double ux = userEnd.x - userStart.x;
      final double uy = userEnd.y - userStart.y;
      final double tx = targetEnd.x - targetStart.x;
      final double ty = targetEnd.y - targetStart.y;

      // ── Cosine Similarity ───────────────────────────────────────────────────
      // S_i = (u · t) / (‖u‖ * ‖t‖)
      final double rawCosine = _cosineSimilarity(ux, uy, tx, ty);

      // Degenerate case: one of the vectors is zero-length. Skip this bone.
      if (rawCosine.isNaN) {
        boneScores[bone.name] = 0.0;
        continue;
      }

      // Map [-1, 1] → [0, 1]:   S'_i = (S_i + 1) / 2
      final double normalizedSimilarity = (rawCosine + 1.0) / 2.0;

      // ── Apply Kinematic Weight + Confidence ────────────────────────────────
      // Effective bone contribution weight: w_i * c_i
      final double effectiveBoneWeight = bone.weight * boneConfidence;

      weightedScoreNumerator += effectiveBoneWeight * normalizedSimilarity;
      weightedScoreDenominator += effectiveBoneWeight;
      boneScores[bone.name] = normalizedSimilarity;
    }

    // ── Guard: Division by zero (user completely off-screen) ─────────────────
    double totalScore = weightedScoreDenominator > 0
        ? weightedScoreNumerator / weightedScoreDenominator
        : 0.0;

    totalScore = totalScore.clamp(0.0, 1.0);

    // ── Refinement 1: Dynamic Scaling of Score Space ─────────────────────────
    // Expand raw mathematical band into user-facing percentage
    // Lowered floor from 0.85 to 0.50 so we can see actual score variations in logs
    // without it instantly snapping to 0.00.
    const double scoreFloor = 0.50;
    final double userFacingScore = math.max(0.0, (totalScore - scoreFloor) / (1.0 - scoreFloor));

    return PoseMatchResult(
      score: userFacingScore,
      boneScores: Map.unmodifiable(boneScores),
      effectiveWeight: weightedScoreDenominator,
    );
  }

  /// Computes cosine similarity between two 2D bone vectors.
  ///
  /// Returns a value in [-1.0, 1.0].
  ///   1.0  = vectors point in the exact same direction (perfect bone alignment).
  ///   0.0  = vectors are perpendicular (90° misalignment).
  ///  -1.0  = vectors point in opposite directions (180° misalignment).
  ///
  /// Returns [double.nan] for zero-magnitude vectors (degenerate bone).
  static double _cosineSimilarity(
    double ux,
    double uy,
    double tx,
    double ty,
  ) {
    final double dotProduct = (ux * tx) + (uy * ty);
    final double magnitudeU = math.sqrt((ux * ux) + (uy * uy));
    final double magnitudeT = math.sqrt((tx * tx) + (ty * ty));

    if (magnitudeU < _minVectorMagnitude || magnitudeT < _minVectorMagnitude) {
      return double.nan; // Signal degenerate bone to the caller.
    }

    // Clamp to [-1, 1] to guard against floating-point drift beyond valid range.
    return (dotProduct / (magnitudeU * magnitudeT)).clamp(-1.0, 1.0);
  }
}
