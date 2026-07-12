import 'package:flutter/foundation.dart';

/// An immutable, normalized pose landmark produced by the [LandmarkNormalizer].
///
/// All coordinates exist in a common geometric space:
///   - Centered at the subject's mid-hip point (origin = 0, 0).
///   - Scaled by torso length (mid-hip to mid-shoulder distance).
///
/// This is the fundamental data unit passed between all modules in the
/// Frozen Intelligence Engine. Raw screen-pixel coordinates are never used
/// after this normalization step.
///
/// EDR Reference: Research Decision 02_normalization
@immutable
class FrozenLandmark {
  /// Normalized X coordinate. 0.0 = mid-hip X origin.
  final double x;

  /// Normalized Y coordinate. 0.0 = mid-hip Y origin.
  final double y;

  /// Original confidence (likelihood) score from the Vision Engine [0.0 – 1.0].
  /// Preserved for Confidence Gating in the [PoseConfidenceEngine].
  final double likelihood;

  const FrozenLandmark({
    required this.x,
    required this.y,
    required this.likelihood,
  });

  @override
  String toString() =>
      'FrozenLandmark('
      'x: ${x.toStringAsFixed(4)}, '
      'y: ${y.toStringAsFixed(4)}, '
      'likelihood: ${likelihood.toStringAsFixed(2)})';
}
