// ─────────────────────────────────────────────────────────────────────────────
// State Machine — Step 1
// File: tracking_profile.dart
// Layer: Configuration — skeleton detection thresholds
// ─────────────────────────────────────────────────────────────────────────────

/// All numeric thresholds that affect skeleton detection and state transitions.
///
/// No constants live in [PoseSessionStateMachine] directly — they all come
/// from this config. This lets different pose categories (standing, yoga, etc.)
/// use different tracking sensitivity without touching the state machine logic.
class TrackingProfile {
  /// Minimum number of joints that must be detected before transitioning
  /// from [AppState.waitForUser] to [AppState.globalAlignment].
  final int minVisibleJoints;

  /// Per-joint confidence floor [0.0–1.0].
  /// Joints below this threshold are treated as unreliable by
  /// [CorrectionCandidateBuilder].
  final double minConfidence;

  /// Number of consecutive frames without a skeleton before the state machine
  /// treats the user as truly "lost" and reverts to [AppState.waitForUser].
  ///
  /// 3 frames ≈ 100ms at 30fps — enough to absorb natural occlusion jitter
  /// without reacting to the user momentarily obscuring a limb.
  final int bodyLostFrames;

  /// How long to wait in [AppState.waitForUser] before giving up and going to [AppState.idle].
  final Duration waitForUserTimeout;

  /// How long to wait in [AppState.globalAlignment] before reverting to [AppState.waitForUser]
  /// with a "Try stepping back" hint.
  final Duration globalAlignTimeout;

  const TrackingProfile({
    this.minVisibleJoints = 10,
    this.minConfidence = 0.75,
    this.bodyLostFrames = 3,
    this.waitForUserTimeout = const Duration(seconds: 60),
    this.globalAlignTimeout = const Duration(seconds: 30),
  });

  /// Default profile for standing portrait photography.
  static const TrackingProfile portrait = TrackingProfile();

  /// More lenient profile for seated or partially occluded scenarios.
  static const TrackingProfile seated = TrackingProfile(
    minVisibleJoints: 7,
    minConfidence: 0.65,
  );
}
