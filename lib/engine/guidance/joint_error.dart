import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EDR DECISION — Research Topic 06: Guidance Engine
// ─────────────────────────────────────────────────────────────────────────────
//
// File: joint_error.dart
// Layer: Pose Error Model (Output of Engine 5, Input to Engine 6)
//
// DESIGN PRINCIPLE: Engine 5 measures. Engine 6 decides. Engine 7 renders.
// This class belongs strictly to Engine 5's output layer. It contains only
// mathematical measurements — never coaching decisions or UI concepts.
//
// The `frameIndex` field uses a monotonic frame counter, NOT wall-clock epoch
// time. Camera pipelines do not guarantee stable epoch timing. Future temporal
// reasoning (velocity, EMA prediction) must be based on frame index.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Change 3 (frozen_ai_state_machine.md): TrackingState in JointError
//
// Tells Engine 6 whether ML Kit physically observed the joint or was guessing.
// CorrectionCandidateBuilder uses this in Pass 1 (confidence gate):
//   lost     → always drop (no data)
//   inferred → apply confidence penalty (weight × 0.67)
//   tracked  → full weight, normal scoring
// ─────────────────────────────────────────────────────────────────────────────

/// Whether ML Kit directly observed this landmark or was mathematically estimating it.
enum TrackingState {
  /// ML Kit directly detected the joint in this frame with high confidence.
  tracked,

  /// ML Kit estimated the position based on surrounding joints.
  /// The joint may be partially occluded. Apply a confidence penalty.
  inferred,

  /// ML Kit has no usable data for this joint.
  /// CorrectionCandidateBuilder MUST drop joints with this state.
  lost,
}

/// Classifies the TYPE of physical error a joint has relative to the target.
///
/// Engine 5 sets this based on the dominant signal in the error vector.
/// Engine 6 uses it to choose the appropriate [CorrectionIntent].
///
/// Locked in EDR v3.6 — Topic 06.
enum ErrorType {
  /// Joint is in the wrong 2D position. Primary signal is (dx, dy).
  translation,

  /// Joint is rotated incorrectly. Future: uses `angleError`.
  rotation,

  /// Limb length or bone-to-bone scale is mismatched.
  scale,

  /// ML Kit confidence is too low to reliably score this joint.
  visibility,

  /// Left/right body asymmetry relative to the target pose.
  symmetry,
}

/// The mathematical error for a single joint, as measured by
/// Engine 5 (Pose Comparison Engine).
///
/// This is one entry in the [Pose Error Model] — a map of these objects
/// keyed by [PoseLandmarkType].
///
/// ─────────────────────────────────────────────────────────────────────────
/// Math (all values in normalized coordinate space):
///
///   dx       = target.x - user.x
///   dy       = target.y - user.y
///   distance = √(dx² + dy²)
/// ─────────────────────────────────────────────────────────────────────────
@immutable
class JointError {
  /// The joint this error belongs to.
  final PoseLandmarkType joint;

  /// X-axis component of the correction vector.
  /// Positive = user must move RIGHT. Negative = user must move LEFT.
  final double dx;

  /// Y-axis component of the correction vector.
  /// Positive = user must move DOWN. Negative = user must move UP.
  final double dy;

  /// Euclidean distance: √(dx² + dy²). Pre-computed so no downstream engine
  /// needs to recompute it.
  final double distance;

  /// ML Kit landmark visibility confidence [0.0 – 1.0].
  /// Used by Engine 6's Utility Score to down-weight poorly visible joints.
  final double confidence;

  /// Whether ML Kit physically observed this landmark or was estimating it.
  ///
  /// Derived from [confidence]:
  ///   confidence > 0.75  → [TrackingState.tracked]
  ///   confidence 0.50–0.75 → [TrackingState.inferred]
  ///   confidence < 0.50  → [TrackingState.lost]
  ///
  /// [CorrectionCandidateBuilder] uses this in Pass 1 to gate and weight candidates.
  final TrackingState trackingState;

  /// Monotonic frame counter from the camera pipeline.
  ///
  /// Do NOT use `DateTime.now().millisecondsSinceEpoch` here.
  /// Camera frames don't guarantee stable wall-clock timing. Use the frame
  /// index counter incremented by the camera pipeline on every processed frame.
  ///
  /// Future use: velocity = (distance_t - distance_{t-1}) / (frameIndex_t - frameIndex_{t-1})
  final int frameIndex;

  /// The dominant type of error for this joint. Set by Engine 5.
  final ErrorType errorType;

  // ── Future-proofing fields ─────────────────────────────────────────────────
  // Engine 5 will populate these in future versions without requiring
  // Engine 6 or Engine 7 to change.

  /// Angle difference between user bone direction and target bone direction.
  /// Future: populated when Engine 5 adds trigonometric analysis.
  final double? angleError;

  /// Rotation difference (signed, in degrees). Future use.
  final double? rotationError;

  /// Raw ML Kit visibility value (distinct from confidence in some models).
  final double? visibility;

  /// Override kinematic weight for this specific joint error (optional).
  final double? weight;

  const JointError({
    required this.joint,
    required this.dx,
    required this.dy,
    required this.distance,
    required this.confidence,
    required this.trackingState,
    required this.frameIndex,
    required this.errorType,
    this.angleError,
    this.rotationError,
    this.visibility,
    this.weight,
  });

  /// Factory constructor: computes [distance] and classifies [errorType]
  /// automatically from the raw dx/dy values.
  factory JointError.fromVector({
    required PoseLandmarkType joint,
    required double dx,
    required double dy,
    required double confidence,
    required int frameIndex,
    double? angleError,
    double? rotationError,
    double? visibility,
    double? weight,
  }) {
    final double distance = math.sqrt(dx * dx + dy * dy);

    // Derive TrackingState from ML Kit inFrameLikelihood (confidence)
    final TrackingState trackingState;
    if (confidence > 0.75) {
      trackingState = TrackingState.tracked;
    } else if (confidence >= 0.50) {
      trackingState = TrackingState.inferred;
    } else {
      trackingState = TrackingState.lost;
    }

    // V1: Classify everything as translation by default.
    // Future: Engine 5 will set rotation/scale/symmetry when those detectors exist.
    final ErrorType errorType =
        confidence < 0.30 ? ErrorType.visibility : ErrorType.translation;

    return JointError(
      joint: joint,
      dx: dx,
      dy: dy,
      distance: distance,
      confidence: confidence,
      trackingState: trackingState,
      frameIndex: frameIndex,
      errorType: errorType,
      angleError: angleError,
      rotationError: rotationError,
      visibility: visibility,
      weight: weight,
    );
  }

  @override
  String toString() =>
      'JointError(${joint.name}, '
      'dx:${dx.toStringAsFixed(3)}, '
      'dy:${dy.toStringAsFixed(3)}, '
      'dist:${distance.toStringAsFixed(3)}, '
      'conf:${confidence.toStringAsFixed(2)}, '
      'tracking:${trackingState.name}, '
      'type:${errorType.name}, '
      'frame:$frameIndex)';
}
