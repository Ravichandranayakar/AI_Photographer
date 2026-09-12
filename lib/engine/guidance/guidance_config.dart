// ─────────────────────────────────────────────────────────────────────────────
// EDR DECISION — Research Topic 06: Guidance Engine
// ─────────────────────────────────────────────────────────────────────────────
//
// File: guidance_config.dart
// Layer: Configuration (Engine 6 parameters)
//
// DESIGN PRINCIPLE:
//   New pose categories are added through configuration, not algorithm changes.
//   All Engine 6 thresholds live here. The Decision Engine algorithm itself
//   never contains hardcoded numbers.
//
//   Future: GuidanceConfig will be loaded from a JSON pose category definition,
//   allowing Standing / Yoga / Dance / Martial Arts to each have their own
//   thresholds without touching decision_engine.dart.
// ─────────────────────────────────────────────────────────────────────────────

/// Configuration parameters for the Guidance Engine (Engine 6).
///
/// Instantiate one [GuidanceConfig] per pose category.
/// Pass it into [DecisionEngine] at construction time.
///
/// ─────────────────────────────────────────────────────────────────────────
/// Research references:
///   bandwidthThreshold — Schmidt, 1991. Bandwidth Feedback in motor learning.
///   fsmPromoteThreshold / fsmDemoteThreshold — Standard control-system
///     hysteresis to prevent rapid state oscillation (flickering).
///   utilityConfidenceFloor — Prevents ML Kit's occluded joint guesses
///     from dominating the coaching priority.
/// ─────────────────────────────────────────────────────────────────────────
class GuidanceConfig {
  // ── Layer 1: Bandwidth Feedback ────────────────────────────────────────────

  /// Minimum joint error distance (normalized) to trigger coaching.
  /// Errors smaller than this are silently ignored.
  ///
  /// Calibrated values by pose category:
  ///   Standing portrait: 0.08
  ///   Seated portrait:   0.10
  ///   Yoga / stretch:    0.15
  ///   Dance / dynamic:   0.22
  final double bandwidthThreshold;

  // ── Layer 2: Utility Sorting ───────────────────────────────────────────────

  /// Confidence floor for the Utility Score calculation.
  ///
  /// The full Utility equation is: U = (1 - S) × W × clamp(C, floor, 1.0)
  ///
  /// Without a floor, a joint with confidence=0.20 would have its Utility
  /// almost zeroed out, and the engine would skip coaching it even if the
  /// joint is badly misaligned. The floor ensures low-confidence joints
  /// still receive partial utility weight rather than being completely ignored.
  ///
  /// Default: 0.5 → confidence scales from 0.5 to 1.0 instead of 0 to 1.0.
  final double utilityConfidenceFloor;

  // ── Layer 3: FSM Hysteresis ────────────────────────────────────────────────

  /// A bone's score must fall BELOW this threshold to become the bottleneck.
  /// Prevents the engine from coaching on joints that are almost correct.
  final double fsmPromoteThreshold;

  /// The current bottleneck is RELEASED only when its score rises ABOVE this.
  /// Higher than [fsmPromoteThreshold] to create hysteresis (prevents flickering).
  final double fsmDemoteThreshold;

  // ── Global Score Gate ──────────────────────────────────────────────────────

  /// If the overall pose score is above this, [GuidanceSignal.isPostureAcceptable]
  /// is true and Engine 7 hides all guidance.
  final double acceptableScoreThreshold;

  // ── Priority Classification ────────────────────────────────────────────────

  /// Score thresholds for classifying [CorrectionPriority].
  ///   boneScore < criticalScoreThreshold → CorrectionPriority.critical
  ///   boneScore < majorScoreThreshold    → CorrectionPriority.major
  ///   otherwise                          → CorrectionPriority.minor
  final double criticalScoreThreshold;
  final double majorScoreThreshold;

  const GuidanceConfig({
    this.bandwidthThreshold = 0.12,
    this.utilityConfidenceFloor = 0.5,
    this.fsmPromoteThreshold = 0.60,
    this.fsmDemoteThreshold = 0.82,
    this.acceptableScoreThreshold = 0.85,
    this.criticalScoreThreshold = 0.40,
    this.majorScoreThreshold = 0.60,
  });

  /// Default config for standing portrait photography.
  static const GuidanceConfig portrait = GuidanceConfig(
    bandwidthThreshold: 0.08,
  );

  /// Config for yoga or high-stretch poses requiring finer corrections.
  static const GuidanceConfig yoga = GuidanceConfig(
    bandwidthThreshold: 0.15,
    fsmPromoteThreshold: 0.65,
    fsmDemoteThreshold: 0.85,
  );

  /// Config for dynamic / dance poses with large allowed error bands.
  static const GuidanceConfig dance = GuidanceConfig(
    bandwidthThreshold: 0.22,
    fsmPromoteThreshold: 0.55,
  );

  @override
  String toString() =>
      'GuidanceConfig('
      'bandwidth:$bandwidthThreshold, '
      'promote:$fsmPromoteThreshold, '
      'demote:$fsmDemoteThreshold, '
      'acceptable:$acceptableScoreThreshold)';
}
