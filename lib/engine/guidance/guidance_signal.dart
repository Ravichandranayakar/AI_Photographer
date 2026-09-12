import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EDR DECISION — Research Topic 06: Guidance Engine
// ─────────────────────────────────────────────────────────────────────────────
//
// File: guidance_signal.dart
// Layer: Engine 6 Output → Engine 7 Input
//
// DESIGN PRINCIPLE:
//   Engine 6 decides WHAT to correct. Engine 7 decides HOW to draw it.
//
//   This class contains ZERO UI concepts (no pixels, no animation names).
//   It contains coaching intent + mathematical correction data.
//   Engine 7 reads this and independently decides whether to draw an arrow,
//   shift the outline, pulse a glow, or any future technique.
//
//   The `priority` field (CorrectionPriority) is the only hint Engine 6
//   gives Engine 7 about urgency. Visual intensity is still Engine 7's job.
// ─────────────────────────────────────────────────────────────────────────────

/// What TYPE of correction the user needs to make.
/// Engine 6 sets this. Engine 7 maps it to a visual technique.
///
/// Example mapping (Engine 7's decision, not locked here):
///   directionalCorrection → arrow + outline shift
///   alignmentCorrection   → glow + outline shift
///   rotationCorrection    → rotating glow indicator (future)
///   success               → green confirmation flash
///   ready                 → hide all guidance
enum CorrectionIntent {
  /// Joint must move in a 2D direction. Dominant use-case in V1.
  directionalCorrection,

  /// Bone axis must align with the target bone axis.
  alignmentCorrection,

  /// Joint must rotate around its parent joint. Future (requires angleError).
  rotationCorrection,

  /// Whole-body reposition needed. User's center-of-mass is too far from target.
  /// Takes priority over ALL joint-level corrections.
  /// Engine 7 shows a full-body instruction: "Step back" / "Move left".
  /// NOT an arrow on a joint — a whole-body instruction text/overlay.
  reposition,

  /// Pose score is high enough to attempt auto-capture.
  ready,

  /// User has matched the pose perfectly. All joints within bandwidth.
  success,
}

/// How urgent the bottleneck correction is.
/// Engine 7 uses this to scale visual intensity WITHOUT changing Engine 6 logic.
///
///   critical → Score < 0.40 on a Core bone. Dominant error.
///   major    → Score < 0.60 on any bone.
///   minor    → Score slightly below threshold. Gentle nudge.
enum CorrectionPriority { critical, major, minor }

/// The single coaching instruction produced by Engine 6 (Decision Engine)
/// for one frame.
///
/// This is the contract between Engine 6 and Engine 7.
/// Engine 7 receives this and executes it — blindly.
///
/// ─────────────────────────────────────────────────────────────────────────
/// What Engine 7 MUST do:
///   1. Read `intent` to choose a rendering strategy.
///   2. Read `priority` to scale visual intensity.
///   3. Draw near `targetJoint` at screen coordinates.
///   4. Apply correction in the direction of `correctionDx`/`correctionDy`.
///   5. Hide all guidance when `isPostureAcceptable == true`.
/// ─────────────────────────────────────────────────────────────────────────
@immutable
class GuidanceSignal {
  // ── Identification ─────────────────────────────────────────────────────────

  /// Name of the bottleneck bone (e.g. 'left_humerus').
  /// Matches a key in [BoneRegistry.all].
  final String targetBone;

  /// The specific joint that needs to move (the distal end of the bottleneck bone).
  /// Used by Engine 7 to determine WHERE on screen to draw the visual cue.
  final PoseLandmarkType targetJoint;

  // ── Mathematical Context ───────────────────────────────────────────────────

  /// How bad the error is. Range [0.0 – 1.0].
  /// Derived from `(1.0 - boneScore)` of the bottleneck bone.
  final double severity;

  /// ML Kit detection confidence of the bottleneck joint [0.0 – 1.0].
  /// Engine 7 may choose to fade the visual cue when this is low.
  final double confidence;

  /// How many frames this signal is expected to remain valid.
  /// Controlled by the FSM DEMOTE_THRESHOLD. Informational for Engine 7.
  final double lifetime;

  // ── Correction Vector ──────────────────────────────────────────────────────

  /// X-axis correction: how far and in which direction the joint must move.
  /// Positive = move RIGHT. Negative = move LEFT. (Normalized coordinates.)
  final double correctionDx;

  /// Y-axis correction: how far and in which direction the joint must move.
  /// Positive = move DOWN. Negative = move UP. (Normalized coordinates.)
  final double correctionDy;

  /// Pre-computed magnitude: √(correctionDx² + correctionDy²).
  /// Stored here to avoid recomputation in the render loop.
  final double magnitude;

  // ── Coaching Intent ────────────────────────────────────────────────────────

  /// What TYPE of correction the user needs. Engine 7 picks the visual style.
  final CorrectionIntent intent;

  /// How URGENT the correction is. Engine 7 picks the visual intensity.
  final CorrectionPriority priority;

  // ── Global Status ──────────────────────────────────────────────────────────

  /// True when the overall pose score >= [GuidanceConfig.acceptableScoreThreshold].
  /// When true, Engine 7 MUST hide all guidance indicators.
  final bool isPostureAcceptable;

  const GuidanceSignal({
    required this.targetBone,
    required this.targetJoint,
    required this.severity,
    required this.confidence,
    required this.lifetime,
    required this.correctionDx,
    required this.correctionDy,
    required this.magnitude,
    required this.intent,
    required this.priority,
    required this.isPostureAcceptable,
  });

  /// Convenience factory for the "success" / "posture acceptable" state.
  /// Engine 7 should hide all guidance when this is returned.
  factory GuidanceSignal.success() {
    return const GuidanceSignal(
      targetBone: '',
      targetJoint: PoseLandmarkType.nose,
      severity: 0.0,
      confidence: 1.0,
      lifetime: 0.0,
      correctionDx: 0.0,
      correctionDy: 0.0,
      magnitude: 0.0,
      intent: CorrectionIntent.success,
      priority: CorrectionPriority.minor,
      isPostureAcceptable: true,
    );
  }

  /// Initial state before the first frame is evaluated.
  /// Engine 7 treats this identically to success (hide all guidance)
  /// but semantically it means "not yet evaluated", not "correct".
  factory GuidanceSignal.ready() {
    return const GuidanceSignal(
      targetBone: '',
      targetJoint: PoseLandmarkType.nose,
      severity: 0.0,
      confidence: 1.0,
      lifetime: 0.0,
      correctionDx: 0.0,
      correctionDy: 0.0,
      magnitude: 0.0,
      intent: CorrectionIntent.ready,
      priority: CorrectionPriority.minor,
      isPostureAcceptable: true,
    );
  }

  @override
  String toString() =>
      'GuidanceSignal('
      'bone:$targetBone, '
      'joint:${targetJoint.name}, '
      'intent:${intent.name}, '
      'priority:${priority.name}, '
      'severity:${severity.toStringAsFixed(2)}, '
      'dx:${correctionDx.toStringAsFixed(3)}, '
      'dy:${correctionDy.toStringAsFixed(3)}, '
      'mag:${magnitude.toStringAsFixed(3)}, '
      'acceptable:$isPostureAcceptable)';
}
