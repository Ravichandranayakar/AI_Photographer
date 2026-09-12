// ─────────────────────────────────────────────────────────────────────────────
// State Machine — Step 1
// File: app_state.dart
// Layer: Orchestrator — App State Enum
// ─────────────────────────────────────────────────────────────────────────────

/// All 9 states of a pose photography session.
/// Transitions are managed exclusively by [PoseSessionStateMachine].
enum AppState {
  /// Home / pose selection screen. No camera active.
  idle,

  /// A pose has been chosen. Preview shown with "Start" button.
  poseSelected,

  /// Camera live. Cyan ghost shown. No body detected yet.
  waitForUser,

  /// Skeleton detected. Checking global orientation (shoulder/hip/torso).
  /// CandidateBuilder and Engine 6 are OFF until this passes.
  globalAlignment,

  /// Global alignment passed. Engine 6 active, coaching one joint at a time.
  jointGuidance,

  /// All joints within tolerance. Outline turns green. Hold timer running.
  poseMatched,

  /// Ring countdown fills over GuidanceProfile.holdTime. Capture fires on complete.
  captureCountdown,

  /// Photo captured. Preview screen with Save/Retake/Share.
  captured,

  /// Unrecoverable error. Shows soft error message.
  error,
}

extension AppStateLabel on AppState {
  String get label {
    switch (this) {
      case AppState.idle:             return 'IDLE';
      case AppState.poseSelected:     return 'POSE_SELECTED';
      case AppState.waitForUser:      return 'WAIT_FOR_USER';
      case AppState.globalAlignment:  return 'GLOBAL_ALIGNMENT';
      case AppState.jointGuidance:    return 'JOINT_GUIDANCE';
      case AppState.poseMatched:      return 'POSE_MATCHED';
      case AppState.captureCountdown: return 'CAPTURE_COUNTDOWN';
      case AppState.captured:         return 'CAPTURED';
      case AppState.error:            return 'ERROR';
    }
  }

  /// True when camera should actively stream frames.
  bool get cameraActive => const {
    AppState.waitForUser,
    AppState.globalAlignment,
    AppState.jointGuidance,
    AppState.poseMatched,
    AppState.captureCountdown,
  }.contains(this);

  /// True when Engine 5 (PoseMatcher) is allowed to run.
  bool get engine5Active => const {
    AppState.globalAlignment,
    AppState.jointGuidance,
    AppState.poseMatched,
    AppState.captureCountdown,
  }.contains(this);

  /// True when CorrectionCandidateBuilder + Engine 6 are allowed.
  /// OFF during globalAlignment — orientation check must pass first.
  bool get engine6Active => const {
    AppState.jointGuidance,
    AppState.poseMatched,
    AppState.captureCountdown,
  }.contains(this);

  /// True when guidance overlays may be drawn.
  bool get guidanceOverlayActive => const {
    AppState.waitForUser,
    AppState.globalAlignment,
    AppState.jointGuidance,
    AppState.poseMatched,
    AppState.captureCountdown,
  }.contains(this);
}
