// ─────────────────────────────────────────────────────────────────────────────
// State Machine — Step 9
// File: session_controller.dart
// Layer: Integration Layer — bridges PoseSessionStateMachine to the UI
//
// DESIGN PRINCIPLE:
//   session_controller.dart is the ONLY class that touches both:
//     - The state machine (pure orchestration logic)
//     - The Flutter widget state (UI + camera)
//
//   main.dart does NOT import PoseSessionStateMachine directly.
//   It only imports SessionController and reads SessionSnapshot.
//
// WHAT THIS DOES:
//   1. Owns the PoseSessionStateMachine instance.
//   2. Called every camera frame with detected poses.
//   3. Returns a SessionSnapshot: what to render, what engines to run.
//   4. Handles device rotation events.
//   5. Gates engine execution: engines only run in their allowed states.
//
// WHAT THIS DOES NOT DO:
//   - It does not run ML Kit pose detection.
//   - It does not control the camera.
//   - It does not build widgets.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'app_state.dart';
import 'camera_mirror_mode.dart';
import 'global_alignment_check.dart';
import 'guidance_profile.dart';
import 'pose_session_state_machine.dart';
import 'tracking_profile.dart';
import '../guidance/guidance_signal.dart';

/// A snapshot of the current session state — produced every camera frame.
///
/// The UI reads this struct to decide:
///   - Which painters to show (overlay gating)
///   - What color to use (poseMatched → green)
///   - What hint text to show
///   - Whether the capture countdown ring should fill
///
/// All fields have safe defaults — the UI never crashes on a null snapshot.
class SessionSnapshot {
  /// The current state of the session.
  final AppState appState;

  /// True when the state machine transitioned in this frame.
  final bool didTransition;

  /// True when Engine 5 (PoseMatcher) is allowed to run this frame.
  final bool engine5Active;

  /// True when Engine 6 (DecisionEngine) is allowed to run this frame.
  final bool engine6Active;

  /// True when Engine 7 (renderers with guidance overlays) should show arrows.
  final bool guidanceOverlayActive;

  /// True when the target ghost outline should be shown on screen.
  final bool showTargetGhost;

  /// True when the live body outline should be shown on screen.
  /// In production mode (Step 10), this will be false.
  final bool showLiveOutline;

  /// True when the capture countdown ring should be visible and filling.
  final bool showCountdownRing;

  /// Scale factor for the target ghost — from GlobalAlignmentCheck.
  /// Passed to TargetPoseGhostPainter so the ghost matches the user's body.
  final double targetScaleFactor;

  /// Progress [0.0–1.0] of the pose-hold timer.
  final double holdProgress;

  /// Mirror mode for Engine 7 renderers (front vs rear camera).
  final CameraMirrorMode mirrorMode;

  /// Optional hint for UI display (e.g. "Turn to face camera").
  final String? uiHint;

  /// The selected subject pose from ML Kit (null when not detected).
  final Pose? subject;

  /// The active guidance signal from Engine 6 (DecisionEngine).
  ///
  /// This is the single source of truth for all Engine 7 renderers.
  /// Painters MUST read guidance from here — not from a separate field.
  ///
  /// Null when Engine 6 is not permitted to run (e.g. WAIT_FOR_USER state).
  /// Use [GuidanceSignal.ready()] as the fallback in painters.
  final GuidanceSignal? activeGuidance;

  const SessionSnapshot({
    this.appState = AppState.idle,
    this.didTransition = false,
    this.engine5Active = false,
    this.engine6Active = false,
    this.guidanceOverlayActive = false,
    this.showTargetGhost = false,
    this.showLiveOutline = false,
    this.showCountdownRing = false,
    this.targetScaleFactor = 1.0,
    this.holdProgress = 0.0,
    this.mirrorMode = CameraMirrorMode.mirrored,
    this.uiHint,
    this.subject,
    this.activeGuidance,
  });

  /// Snapshot for the initial idle state — safe defaults, nothing rendered.
  static const SessionSnapshot idle = SessionSnapshot();
}

/// Integration layer between the state machine and the Flutter UI.
///
/// Create one instance when the camera session starts.
/// Call [onFrame] every camera frame. Call [onDeviceRotation] on orientation change.
/// Read the returned [SessionSnapshot] to decide what to render.
///
/// Usage in main.dart:
/// ```dart
/// // In initState:
/// _sessionController = SessionController(
///   mirrorMode: isFrontCamera
///       ? CameraMirrorMode.mirrored
///       : CameraMirrorMode.unmirrored,
/// );
///
/// // Every camera frame (after ML Kit):
/// final snap = _sessionController.onFrame(detectedPoses: poses);
/// if (snap.engine5Active) {
///   final matchResult = PoseMatcher.compute(...);
///   if (snap.engine6Active) {
///     _guidanceSignal = _decisionEngine.evaluate(matchResult: matchResult);
///   }
/// }
///
/// // Apply snap to UI:
/// setState(() {
///   _snapshot = snap;
/// });
/// ```
class SessionController {
  final CameraMirrorMode mirrorMode;
  final TrackingProfile trackingProfile;
  final GuidanceProfile guidanceProfile;

  late final PoseSessionStateMachine _machine;
  final GlobalAlignmentCheck _alignmentCheck = const GlobalAlignmentCheck();

  /// Last alignment result — updated in GLOBAL_ALIGNMENT state.
  AlignmentResult _lastAlignment = const AlignmentResult.pass(scaleFactor: 1.0);

  SessionController({
    this.mirrorMode = CameraMirrorMode.mirrored,
    this.trackingProfile = const TrackingProfile(),
    this.guidanceProfile = const GuidanceProfile(),
  }) {
    _machine = PoseSessionStateMachine(
      trackingProfile: trackingProfile,
      guidanceProfile: guidanceProfile,
    );
    // For V1 compatibility: auto-start the session so the camera is active immediately.
    _machine.onEvent(StateMachineEvent.poseSelected);
    _machine.onEvent(StateMachineEvent.sessionStarted);
    if (kDebugMode) debugPrint('[SessionController] Auto-started → WAIT_FOR_USER');
  }

  /// Process one camera frame. Call every frame from the camera pipeline.
  ///
  /// [detectedPoses] — ML Kit detected poses for this frame.
  /// [activeGuidance] — GuidanceSignal from Engine 6, computed in main.dart.
  ///   Pass null when Engine 6 did not run (e.g. no body detected, wrong state).
  SessionSnapshot onFrame({
    required List<Pose> detectedPoses,
    GuidanceSignal? activeGuidance,
    bool developerMode = false,
  }) {
    final frame = _machine.onFrame(detectedPoses: detectedPoses);

    // ── Global Alignment Check (runs in GLOBAL_ALIGNMENT state only) ──────────
    if (frame.state == AppState.globalAlignment && frame.subject != null) {
      final alignResult = _alignmentCheck.evaluate(
        detectedPose: frame.subject!,
        guidanceProfile: guidanceProfile,
      );
      _lastAlignment = alignResult;
      _machine.onGlobalAlignmentResult(passed: alignResult.passed);
    }

    // ── Pose Match Evaluation (runs in JOINT_GUIDANCE or later) ───────────────
    if (activeGuidance != null) {
      _machine.onPoseMatchEvaluation(
        allJointsMatched: activeGuidance.isPostureAcceptable,
      );
    }

    return _buildSnapshot(
      frame,
      activeGuidance: activeGuidance,
      developerMode: developerMode,
    );
  }

  /// Call when device orientation changes.
  void onDeviceRotation() => _machine.onDeviceRotation();

  /// Fire a state machine event (pose selected, session started, etc.)
  void onEvent(StateMachineEvent event) => _machine.onEvent(event);

  /// Release resources.
  void dispose() => _machine.dispose();

  // ── Private ─────────────────────────────────────────────────────────────────

  SessionSnapshot _buildSnapshot(
    StateMachineFrame frame, {
    GuidanceSignal? activeGuidance,
    bool developerMode = false,
  }) {
    final state = frame.state;

    return SessionSnapshot(
      appState: state,
      didTransition: frame.didTransition,
      engine5Active: state.engine5Active,
      engine6Active: state.engine6Active,
      guidanceOverlayActive: state.guidanceOverlayActive,

      // Show target ghost in all active camera states
      showTargetGhost: state.cameraActive || state == AppState.poseSelected,

      // Show live outline when body is detected in any active state
      // Step 10: Disabled for production mode.
      // Step 12: Re-enabled when developerMode is true.
      showLiveOutline: developerMode && state.cameraActive && frame.subject != null,

      // Countdown ring only during the final capture phase
      showCountdownRing: state == AppState.captureCountdown,

      targetScaleFactor: _lastAlignment.scaleFactor,
      holdProgress: frame.holdProgress,
      mirrorMode: mirrorMode,
      uiHint: frame.uiHint ??
          (state == AppState.globalAlignment ? _lastAlignment.hint : null),
      subject: frame.subject,

      // Engine 6 output — the single source of truth for all renderers
      activeGuidance: activeGuidance,
    );
  }
}
