import 'dart:math' as math;

import '../models/bone_registry.dart';
import '../models/pose_match_result.dart';
import 'guidance_config.dart';
import 'guidance_signal.dart';
import 'joint_error.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EDR DECISION — Research Topic 06: Guidance Engine
// ─────────────────────────────────────────────────────────────────────────────
//
// File: decision_engine.dart
// Layer: Engine 6 — The Decision Engine ("The Brain")
//
// DESIGN PRINCIPLE:
//   Engine 6 decides. It never measures. It never renders.
//   It reads the Pose Error Model from Engine 5 and outputs ONE
//   GuidanceSignal per frame.
//
// THREE MATHEMATICAL LAYERS (locked in EDR v3.6):
//
//   Layer 1: Bandwidth Feedback (Schmidt, 1991)
//     Ignore errors smaller than GuidanceConfig.bandwidthThreshold.
//     Do NOT overwhelm the user with micro-corrections.
//
//   Layer 2: Utility Sorting (Proximal-to-Distal motor learning)
//     U = (1.0 - S) × W × clamp(C, floor, 1.0)
//     where S = bone score, W = kinematic weight, C = confidence.
//     Ensures Core bones are coached before Secondary bones, even if
//     Secondary bones have a worse raw score.
//
//   Layer 3: FSM Hysteresis (Control System Design)
//     Once a bone becomes the bottleneck (score < PROMOTE_THRESHOLD),
//     it is HELD until it recovers (score > DEMOTE_THRESHOLD).
//     Prevents the coaching arrow from flickering between joints every frame.
// ─────────────────────────────────────────────────────────────────────────────

/// A single candidate joint that passed the Bandwidth Gate and is eligible
/// to become the coaching bottleneck.
///
/// Built by Engine 6 from the Pose Error Model. Ranked by Utility Score.
/// The highest-Utility candidate becomes the bottleneck for the frame.
class _CorrectionCandidate {
  final String boneName;
  final BoneDefinition bone;
  final JointError error;
  final double boneScore;
  final double utilityScore;

  const _CorrectionCandidate({
    required this.boneName,
    required this.bone,
    required this.error,
    required this.boneScore,
    required this.utilityScore,
  });
}

/// Engine 6: The Decision Engine.
///
/// Stateful — maintains the FSM bottleneck state between frames.
/// Create one instance per active guidance session (i.e., while a pose is loaded).
/// Call [reset] when the user changes pose or steps out of frame.
///
/// Usage:
/// ```dart
/// final engine = DecisionEngine(config: GuidanceConfig.portrait);
///
/// // Every frame:
/// final signal = engine.evaluate(matchResult: result, boneRegistry: BoneRegistry.all);
/// ```
class DecisionEngine {
  final GuidanceConfig config;

  /// Minimum milliseconds a GuidanceSignal stays locked before Engine 6
  /// may switch to a new bottleneck joint.
  ///
  /// Prevents flickering arrows when the user is moving between positions.
  /// Default: 500ms — based on minimum human reaction time.
  final int guidanceLifetimeMs;

  /// The name of the bone currently locked as the bottleneck.
  String? _currentBottleneckBone;

  /// Guidance Lifetime Lock — holds the current signal until expiry.
  DateTime? _guidanceLockUntil;
  GuidanceSignal? _lockedSignal;

  DecisionEngine({
    this.config = const GuidanceConfig(),
    this.guidanceLifetimeMs = 500,
  });

  /// Evaluates one [PoseMatchResult] frame and returns the single [GuidanceSignal]
  /// that Engine 7 should render.
  ///
  /// This is the main entry point. Call once per camera frame.
  GuidanceSignal evaluate({required PoseMatchResult matchResult}) {
    // ── Global Acceptable Check ───────────────────────────────────────────────
    if (matchResult.score >= config.acceptableScoreThreshold) {
      _currentBottleneckBone = null;
      _clearLock();
      return GuidanceSignal.success();
    }

    // ── Guidance Lifetime Lock ────────────────────────────────────────────────
    // If the lock is still active, return the cached signal without re-evaluating.
    // This prevents arrow flickering between joints every frame.
    final now = DateTime.now();
    if (_guidanceLockUntil != null &&
        now.isBefore(_guidanceLockUntil!) &&
        _lockedSignal != null) {
      return _lockedSignal!;
    }

    // ── Layer 1: Bandwidth Gate ────────────────────────────────────────────────
    // Build CorrectionCandidates from bones that:
    //   a) Have a JointError in the Pose Error Model (passed Engine 5 confidence gate)
    //   b) Have an error distance >= bandwidthThreshold
    final List<_CorrectionCandidate> candidates = [];

    for (final BoneDefinition bone in BoneRegistry.all) {
      final double? boneScore = matchResult.boneScores[bone.name];
      final JointError? error = matchResult.boneErrors[bone.name];

      // Skip bones that were confidence-gated or degenerate in Engine 5.
      if (boneScore == null || error == null) continue;

      // Layer 1: Bandwidth Gate
      // Ignore corrections that are too small to notice.
      if (error.distance < config.bandwidthThreshold) continue;

      // ── Layer 2: Utility Score ───────────────────────────────────────────────
      // U = (1.0 - S) × W × clamp(C, floor, 1.0)
      //
      // The confidence clamp (floor → 1.0) ensures that a partially-visible
      // joint still receives a meaningful Utility score rather than being
      // suppressed entirely. This implements the GPT-recommended formula
      // U = (1-S) × W × (0.5 + 0.5C) which is equivalent when floor=0.5.
      final double effectiveConfidence =
          error.confidence.clamp(config.utilityConfidenceFloor, 1.0);

      final double utilityScore =
          (1.0 - boneScore) * bone.weight * effectiveConfidence;

      candidates.add(_CorrectionCandidate(
        boneName: bone.name,
        bone: bone,
        error: error,
        boneScore: boneScore,
        utilityScore: utilityScore,
      ));
    }

    // No candidates: all errors are within bandwidth. Pose is almost correct.
    if (candidates.isEmpty) {
      _currentBottleneckBone = null;
      return GuidanceSignal.success();
    }

    // Sort candidates by Utility Score (highest = worst bottleneck first).
    candidates.sort((a, b) => b.utilityScore.compareTo(a.utilityScore));

    // ── Layer 3: FSM Hysteresis ────────────────────────────────────────────────
    // Check if the current bottleneck bone should be released.
    if (_currentBottleneckBone != null) {
      final double? currentScore =
          matchResult.boneScores[_currentBottleneckBone];

      if (currentScore == null || currentScore > config.fsmDemoteThreshold) {
        // Current bottleneck is fixed. Release it.
        _currentBottleneckBone = null;
      }
    }

    // If no bottleneck is active, promote the highest-utility candidate.
    if (_currentBottleneckBone == null) {
      final topCandidate = candidates.first;

      // Only promote if it is below the promote threshold.
      if (topCandidate.boneScore < config.fsmPromoteThreshold) {
        _currentBottleneckBone = topCandidate.boneName;
      } else {
        // All remaining errors are minor (between bandwidth and promote threshold).
        return GuidanceSignal.success();
      }
    }

    // Resolve the active bottleneck candidate.
    final _CorrectionCandidate bottleneck = candidates.firstWhere(
      (c) => c.boneName == _currentBottleneckBone,
      orElse: () => candidates.first,
    );

    // ── Build GuidanceSignal ───────────────────────────────────────────────────
    return _lockAndReturn(_buildSignal(bottleneck, matchResult.score));
  }

  /// Resets the FSM state.
  /// Call when the user changes pose, steps out of frame, or session ends.
  void reset() {
    _currentBottleneckBone = null;
    _clearLock();
  }

  void _clearLock() {
    _guidanceLockUntil = null;
    _lockedSignal = null;
  }

  /// Lock a new signal for [guidanceLifetimeMs] milliseconds.
  GuidanceSignal _lockAndReturn(GuidanceSignal signal) {
    _lockedSignal = signal;
    _guidanceLockUntil = DateTime.now().add(
      Duration(milliseconds: guidanceLifetimeMs),
    );
    return signal;
  }

  // ── Private Helpers ──────────────────────────────────────────────────────────

  GuidanceSignal _buildSignal(
    _CorrectionCandidate candidate,
    double overallScore,
  ) {
    final JointError error = candidate.error;
    final double dx = error.dx;
    final double dy = error.dy;
    final double magnitude = math.sqrt(dx * dx + dy * dy);

    // Classify priority from bone score.
    final CorrectionPriority priority = _classifyPriority(candidate.boneScore);

    // V1: All directional corrections use CorrectionIntent.directionalCorrection.
    // Future: Detect rotation errors via angleError field and emit rotationCorrection.
    const CorrectionIntent intent = CorrectionIntent.directionalCorrection;

    return GuidanceSignal(
      targetBone: candidate.boneName,
      targetJoint: candidate.bone.endLandmark,
      severity: (1.0 - candidate.boneScore).clamp(0.0, 1.0),
      confidence: error.confidence,
      lifetime: config.fsmDemoteThreshold - candidate.boneScore,
      correctionDx: dx,
      correctionDy: dy,
      magnitude: magnitude,
      intent: intent,
      priority: priority,
      isPostureAcceptable: false,
    );
  }

  CorrectionPriority _classifyPriority(double boneScore) {
    if (boneScore < config.criticalScoreThreshold) {
      return CorrectionPriority.critical;
    } else if (boneScore < config.majorScoreThreshold) {
      return CorrectionPriority.major;
    } else {
      return CorrectionPriority.minor;
    }
  }
}
