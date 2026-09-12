// ─────────────────────────────────────────────────────────────────────────────
// State Machine — Step 1
// File: pose_session_state_machine.dart
// Layer: Orchestrator — The Master Controller
//
// DESIGN PRINCIPLE (from frozen_ai_state_machine.md):
//   The state machine is the orchestrator. It does not run any math itself.
//   Its only job is: "Which engines are running now, and what does the UI show?"
//
//   Every engine checks the state machine before doing work.
//   No engine runs outside its allowed states.
//
// SEPARATION OF CONCERNS:
//   - PoseSessionStateMachine: owns ALL state transitions
//   - Engine 5 (PoseMatcher): math only — called only when state.engine5Active
//   - Engine 6 (DecisionEngine): ranking only — called only when state.engine6Active
//   - Engine 7 (Renderers): drawing only — called only when state.guidanceOverlayActive
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'app_state.dart';
import 'guidance_profile.dart';
import 'subject_tracker.dart';
import 'tracking_profile.dart';

/// The result of a single state machine evaluation frame.
///
/// Returned by [PoseSessionStateMachine.onFrame] every camera frame.
/// The UI reads this to decide what to render.
class StateMachineFrame {
  final AppState state;

  /// The selected subject pose (null when no body detected).
  final Pose? subject;

  /// Number of visible joints in the subject pose (0 when no body).
  final int visibleJoints;

  /// True when the state machine just transitioned in this frame.
  final bool didTransition;

  /// The previous state (useful for fade-out animations on transition).
  final AppState? previousState;

  /// Human-readable hint for the UI (e.g. "Turn to face camera").
  /// Null when no hint is needed.
  final String? uiHint;

  /// Progress of the pose-matched hold timer [0.0–1.0].
  /// Only meaningful in [AppState.poseMatched] and [AppState.captureCountdown].
  final double holdProgress;

  const StateMachineFrame({
    required this.state,
    this.subject,
    this.visibleJoints = 0,
    this.didTransition = false,
    this.previousState,
    this.uiHint,
    this.holdProgress = 0.0,
  });
}

/// Event types the state machine can receive externally.
enum StateMachineEvent {
  /// User selected a pose from the gallery.
  poseSelected,

  /// User tapped the "Start" button on the pose preview screen.
  sessionStarted,

  /// User tapped "Back" to cancel the current session.
  userCancelled,

  /// User tapped "Retake" on the capture preview screen.
  retakeRequested,

  /// User tapped "Save" after capture.
  saveCompleted,

  /// Camera or ML Kit error occurred.
  cameraError,

  /// Error was dismissed/recovered.
  errorRecovered,

  /// Error dismissed, go back to home.
  errorGoHome,
}

/// The master orchestrator for a pose photography session.
///
/// Create ONE instance and keep it alive for the session lifecycle.
/// Call [onFrame] every camera frame with the latest ML Kit pose detections.
/// Call [onEvent] for user-initiated events (button taps, etc.).
/// Call [onPoseMatchEvaluation] from Engine 5/6 when a match result is available.
///
/// Usage:
/// ```dart
/// final stateMachine = PoseSessionStateMachine(
///   trackingProfile: TrackingProfile.portrait,
///   guidanceProfile: GuidanceProfile.portrait,
/// );
///
/// // Every camera frame:
/// final frame = stateMachine.onFrame(detectedPoses: poses);
/// if (frame.state.engine6Active) {
///   final signal = decisionEngine.evaluate(matchResult: result);
/// }
/// ```
class PoseSessionStateMachine {
  final TrackingProfile trackingProfile;
  final GuidanceProfile guidanceProfile;

  PoseSessionStateMachine({
    this.trackingProfile = const TrackingProfile(),
    this.guidanceProfile = const GuidanceProfile(),
  }) : _subjectTracker = SubjectTracker();

  // ── Internal State ─────────────────────────────────────────────────────────

  final SubjectTracker _subjectTracker;

  AppState _state = AppState.idle;
  AppState? _previousState;
  bool _didTransition = false;

  /// Skeleton loss buffer — consecutive frames without a skeleton.
  int _lostFrameCount = 0;

  /// Hold timer for POSE_MATCHED → CAPTURE_COUNTDOWN transition.
  /// Null = timer not started. Reset to null on any pose break.
  DateTime? _matchStartTime;

  /// Timeout timers — both are wired and functional (Step 8 complete).
  Timer? _waitForUserTimer;
  Timer? _globalAlignTimer;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Current state (read-only).
  AppState get state => _state;

  /// Call this when the device orientation changes.
  ///
  /// RULE (frozen_ai_state_machine.md): Always reset to [AppState.waitForUser]
  /// on device rotation. The user's body position on screen changes completely
  /// when the screen rotates — continuing guidance would produce wrong arrows.
  ///
  /// Wired to Flutter's [OrientationBuilder] / [didChangeMetrics] in main.dart.
  void onDeviceRotation() {
    _cancelAllTimers();
    _subjectTracker.clearLock();
    _matchStartTime = null;
    _lostFrameCount = 0;

    if (_state != AppState.idle &&
        _state != AppState.poseSelected &&
        _state != AppState.error) {
      if (kDebugMode) {
        print('[StateMachine] Device rotated → WAIT_FOR_USER');
      }
      _transitionTo(AppState.waitForUser);
      _startWaitForUserTimer();
    }
  }

  /// Process one camera frame of detected poses.
  ///
  /// Call this every frame from the camera pipeline, BEFORE running any engine.
  /// Returns a [StateMachineFrame] describing what engines are allowed to run
  /// and what the UI should display.
  StateMachineFrame onFrame({required List<Pose> detectedPoses}) {
    _didTransition = false;

    final subject = _subjectTracker.selectSubject(detectedPoses);
    final visibleJoints = subject != null
        ? _subjectTracker.countVisibleJoints(
            subject,
            minConfidence: trackingProfile.minConfidence,
          )
        : 0;

    // ── Skeleton Loss Buffer ───────────────────────────────────────────────
    if (subject == null && _state.cameraActive) {
      _lostFrameCount++;
      if (_lostFrameCount >= trackingProfile.bodyLostFrames) {
        _handleSkeletonLost();
      }
    } else if (subject != null) {
      _lostFrameCount = 0;
    }

    // ── State-Specific Logic ───────────────────────────────────────────────
    String? uiHint;
    switch (_state) {
      case AppState.waitForUser:
        uiHint = 'Step into frame to start';
        if (subject != null &&
            visibleJoints >= trackingProfile.minVisibleJoints) {
          _waitForUserTimer?.cancel();
          _transitionTo(AppState.globalAlignment);
          _startGlobalAlignTimer();
          uiHint = null; // SessionController provides the dynamic hint
        }
        break;

      case AppState.globalAlignment:
        // Engine 5 runs here to compute the raw pose match.
        // GlobalAlignmentCheck (Step 4) evaluates shoulder/hip/torso angles
        // and calls [onGlobalAlignmentResult] when they pass/fail.
        uiHint = null; // SessionController provides the dynamic hint
        break;

      case AppState.jointGuidance:
        // Engine 5 + 6 running. No hint needed — arrows handle guidance.
        break;

      case AppState.poseMatched:
        uiHint = 'Hold steady...';
        break;

      case AppState.captureCountdown:
        // Ring animation handles the feedback.
        break;

      default:
        break;
    }

    return StateMachineFrame(
      state: _state,
      subject: subject,
      visibleJoints: visibleJoints,
      didTransition: _didTransition,
      previousState: _previousState,
      uiHint: uiHint,
      holdProgress: _computeHoldProgress(),
    );
  }

  /// Called by Engine 5/6 with the result of global alignment checking.
  ///
  /// [passed] = true when shoulder/hip/torso orientation is acceptable.
  /// [hint] = optional string for UI display when alignment fails (e.g. "Turn to face camera").
  void onGlobalAlignmentResult({required bool passed, String? hint}) {
    if (_state != AppState.globalAlignment) return;
    if (passed) {
      _globalAlignTimer?.cancel();
      _transitionTo(AppState.jointGuidance);
    }
    // If failed, state stays in globalAlignment. Hint is shown by caller.
  }

  /// Called by Engine 5/6 every frame when in JOINT_GUIDANCE or later states.
  ///
  /// [allJointsMatched] = true when all joints are within tolerance (score >= successThreshold).
  /// [globalAlignmentBroken] = true if orientation check fails mid-session.
  void onPoseMatchEvaluation({
    required bool allJointsMatched,
    bool globalAlignmentBroken = false,
  }) {
    if (globalAlignmentBroken &&
        (_state == AppState.jointGuidance ||
            _state == AppState.poseMatched ||
            _state == AppState.captureCountdown)) {
      _matchStartTime = null;
      _transitionTo(AppState.globalAlignment);
      return;
    }

    switch (_state) {
      case AppState.jointGuidance:
        if (allJointsMatched) {
          _transitionTo(AppState.poseMatched);
          _matchStartTime = DateTime.now();
        }
        break;

      case AppState.poseMatched:
        if (!allJointsMatched) {
          _matchStartTime = null;
          _transitionTo(AppState.jointGuidance);
        } else {
          // Check hold timer
          final elapsed =
              DateTime.now().difference(_matchStartTime ?? DateTime.now());
          if (elapsed >= guidanceProfile.holdTime) {
            _transitionTo(AppState.captureCountdown);
          }
        }
        break;

      case AppState.captureCountdown:
        if (!allJointsMatched) {
          _matchStartTime = null;
          _transitionTo(AppState.jointGuidance);
        }
        break;

      default:
        break;
    }
  }

  /// Called when the camera successfully captures a photo.
  void onCaptureFired() {
    if (_state == AppState.captureCountdown) {
      _transitionTo(AppState.captured);
    }
  }

  /// Handle UI events (button taps, back navigation, errors).
  void onEvent(StateMachineEvent event) {
    switch (event) {
      case StateMachineEvent.poseSelected:
        if (_state == AppState.idle) {
          _transitionTo(AppState.poseSelected);
        }
        break;

      case StateMachineEvent.sessionStarted:
        if (_state == AppState.poseSelected) {
          _transitionTo(AppState.waitForUser);
          _startWaitForUserTimer();
        }
        break;

      case StateMachineEvent.userCancelled:
        if (_state.cameraActive ||
            _state == AppState.poseMatched ||
            _state == AppState.captureCountdown) {
          _cancelAllTimers();
          _subjectTracker.clearLock();
          _matchStartTime = null;
          _transitionTo(AppState.waitForUser);
        } else if (_state == AppState.poseSelected) {
          _transitionTo(AppState.idle);
        }
        break;

      case StateMachineEvent.retakeRequested:
        if (_state == AppState.captured) {
          _subjectTracker.clearLock();
          _matchStartTime = null;
          _transitionTo(AppState.waitForUser);
          _startWaitForUserTimer();
        }
        break;

      case StateMachineEvent.saveCompleted:
        if (_state == AppState.captured) {
          _cancelAllTimers();
          _subjectTracker.clearLock();
          _matchStartTime = null;
          _transitionTo(AppState.idle);
        }
        break;

      case StateMachineEvent.cameraError:
        _cancelAllTimers();
        _transitionTo(AppState.error);
        break;

      case StateMachineEvent.errorRecovered:
        if (_state == AppState.error) {
          _subjectTracker.clearLock();
          _transitionTo(AppState.waitForUser);
          _startWaitForUserTimer();
        }
        break;

      case StateMachineEvent.errorGoHome:
        if (_state == AppState.error) {
          _cancelAllTimers();
          _transitionTo(AppState.idle);
        }
        break;
    }
  }

  /// Release all resources. Call on widget dispose.
  void dispose() {
    _cancelAllTimers();
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  void _transitionTo(AppState next) {
    if (_state == next) return;
    if (kDebugMode) {
      print('[StateMachine] ${_state.label} → ${next.label}');
    }
    _previousState = _state;
    _state = next;
    _didTransition = true;
  }

  void _handleSkeletonLost() {
    _lostFrameCount = 0;
    _subjectTracker.clearLock();
    _matchStartTime = null;

    if (_state == AppState.globalAlignment ||
        _state == AppState.jointGuidance ||
        _state == AppState.poseMatched ||
        _state == AppState.captureCountdown) {
      _transitionTo(AppState.waitForUser);
      _startWaitForUserTimer();
    }
  }

  double _computeHoldProgress() {
    if (_matchStartTime == null) return 0.0;
    if (_state != AppState.poseMatched &&
        _state != AppState.captureCountdown) {
      return 0.0;
    }
    final elapsed = DateTime.now().difference(_matchStartTime!);
    return (elapsed.inMilliseconds / guidanceProfile.holdTime.inMilliseconds)
        .clamp(0.0, 1.0);
  }


  // ── Timeout Timers (Step 8 — wired here, logic below) ─────────────────────

  void _startWaitForUserTimer() {
    _waitForUserTimer?.cancel();
    _waitForUserTimer = Timer(trackingProfile.waitForUserTimeout, () {
      if (_state == AppState.waitForUser) {
        if (kDebugMode) {
          print('[StateMachine] WAIT_FOR_USER timeout → IDLE');
        }
        _cancelAllTimers();
        _transitionTo(AppState.idle);
      }
    });
  }

  void _startGlobalAlignTimer() {
    _globalAlignTimer?.cancel();
    _globalAlignTimer = Timer(trackingProfile.globalAlignTimeout, () {
      if (_state == AppState.globalAlignment) {
        if (kDebugMode) {
          print('[StateMachine] GLOBAL_ALIGNMENT timeout → WAIT_FOR_USER');
        }
        _transitionTo(AppState.waitForUser);
        _startWaitForUserTimer();
      }
    });
  }

  void _cancelAllTimers() {
    _waitForUserTimer?.cancel();
    _globalAlignTimer?.cancel();
    _waitForUserTimer = null;
    _globalAlignTimer = null;
  }
}
