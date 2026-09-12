// ─────────────────────────────────────────────────────────────────────────────
// State Machine — Step 1
// File: guidance_profile.dart
// Layer: Configuration — session guidance thresholds
//
// DESIGN PRINCIPLE:
//   New pose categories are supported through configuration, not algorithm changes.
//   All session timing and threshold values live here — never hardcoded in the
//   state machine or engine logic.
// ─────────────────────────────────────────────────────────────────────────────

/// Configuration for the guidance session behavior (timing, thresholds, limits).
///
/// Works alongside [GuidanceConfig] (Engine 6 math parameters).
/// [GuidanceProfile] owns the session orchestration parameters.
/// [GuidanceConfig] owns the per-joint scoring parameters.
class GuidanceProfile {
  /// Overall EMA score threshold below which guidance arrows are shown.
  final double arrowThreshold;

  /// Score threshold for switching from directional arrows to gentle pulse indicator.
  final double pulseThreshold;

  /// Score threshold for declaring POSE_MATCHED (all joints within tolerance).
  /// When all joints pass this, the outline turns green.
  final double successThreshold;

  /// How long the user must continuously hold a matched pose before
  /// [AppState.captureCountdown] begins.
  ///
  /// MUST be unbroken — any deviation resets the timer to zero.
  /// Do not accumulate partial holds. (Spec §Hold Timer)
  final Duration holdTime;

  /// Minimum time a GuidanceSignal stays locked before Engine 6 may switch
  /// to a new bottleneck joint. Prevents flickering arrows between frames.
  ///
  /// 500ms minimum lock — based on motor learning research (reaction time floor).
  /// Source of truth for [DecisionEngine.guidanceLifetimeMs] — do not
  /// hardcode this value anywhere else.
  final Duration guidanceLifetime;

  /// Maximum number of CorrectionCandidates passed to Engine 6 per frame.
  /// Bandwidth cap — prevents the engine from trying to correct too many joints.
  final int maxCandidates;

  /// Convenience accessor: [guidanceLifetime] in milliseconds.
  /// Use this when passing to [DecisionEngine] constructor.
  int get guidanceLifetimeMs => guidanceLifetime.inMilliseconds;

  /// Center-of-mass distance threshold to trigger a whole-body reposition instruction.
  /// Measured in normalized coordinate space [0.0–1.0].
  ///
  /// When exceeded, [CorrectionIntent.reposition] fires BEFORE any joint corrections.
  /// This prevents the engine from guiding individual joints when the whole body
  /// is in the wrong screen position.
  final double repositionThreshold;

  const GuidanceProfile({
    this.arrowThreshold = 0.60,
    this.pulseThreshold = 0.80,
    this.successThreshold = 0.85,
    this.holdTime = const Duration(milliseconds: 800),
    this.guidanceLifetime = const Duration(milliseconds: 500),
    this.maxCandidates = 3,
    this.repositionThreshold = 0.15,
  });

  /// Default profile for standing portrait photography.
  static const GuidanceProfile portrait = GuidanceProfile();

  /// Wider reposition tolerance for landscape orientation (wider frame).
  static const GuidanceProfile landscape = GuidanceProfile(
    repositionThreshold: 0.18,
  );

  /// Tighter centering tolerance for tablet screens (larger frame).
  static const GuidanceProfile tablet = GuidanceProfile(
    repositionThreshold: 0.10,
  );
}
