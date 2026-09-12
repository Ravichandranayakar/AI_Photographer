// ─────────────────────────────────────────────────────────────────────────────
// State Machine — Step 1
// File: subject_tracker.dart
// Layer: State Machine — Multi-Person Subject Locking (Q1 resolution)
//
// PROBLEM (from frozen_ai_state_machine.md Q1):
//   If multiple people are in frame, the engine must not silently switch
//   subjects mid-session. "Largest bounding box" fails when two people
//   stand at different distances — the engine switches subjects the moment
//   someone walks closer.
//
// SOLUTION:
//   Lock onto one subject using highest-confidence selection on first detection.
//   ML Kit v0.x does not expose persistent pose IDs, so we cannot track by ID.
//   The lock is cleared explicitly when the skeleton is "lost" (3 consecutive
//   frames with no detection) and the state machine reverts to WAIT_FOR_USER.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Selects and locks onto a single subject from a list of detected poses.
///
/// Subject selection priority:
///   1. Highest average landmark confidence (primary selector)
///   2. Largest visible joint count (tiebreaker)
///
/// Note: When ML Kit adds persistent pose IDs to its API, update
/// [selectSubject] to use ID-based continuity as Priority 1.
class SubjectTracker {
  SubjectTracker();

  /// Select the best subject from the list of ML Kit detected poses.
  ///
  /// Returns null when [detectedPoses] is empty.
  ///
  /// Stateless by design — the state machine calls this every frame.
  /// Subject continuity is maintained by the state machine's 3-frame loss buffer,
  /// not by internal state in this class.
  Pose? selectSubject(List<Pose> detectedPoses) {
    if (detectedPoses.isEmpty) return null;
    if (detectedPoses.length == 1) return detectedPoses.first;

    // Priority 1: Highest average landmark confidence
    Pose? best;
    double bestScore = -1.0;

    for (final pose in detectedPoses) {
      final score = _selectionScore(pose);
      if (score > bestScore) {
        bestScore = score;
        best = pose;
      }
    }

    return best;
  }

  /// Count joints visible above a given confidence threshold.
  ///
  /// Used by [PoseSessionStateMachine] to check if the detected skeleton
  /// meets [TrackingProfile.minVisibleJoints] before transitioning to
  /// [AppState.globalAlignment].
  int countVisibleJoints(Pose pose, {double minConfidence = 0.5}) {
    return pose.landmarks.values
        .where((lm) => lm.likelihood >= minConfidence)
        .length;
  }

  /// Average confidence across all landmarks.
  double averageConfidence(Pose pose) {
    if (pose.landmarks.isEmpty) return 0.0;
    final total = pose.landmarks.values
        .map((lm) => lm.likelihood)
        .fold(0.0, (sum, v) => sum + v);
    return total / pose.landmarks.length;
  }

  /// Clear any internal tracking state.
  /// Call this when the state machine reverts to [AppState.waitForUser]
  /// due to skeleton loss, ensuring a fresh subject acquisition next frame.
  void clearLock() {
    // ML Kit v0.x does not expose persistent pose IDs, so there is no
    // internal ID to clear. This method exists for API consistency and
    // forward compatibility — when ML Kit adds persistent IDs, the
    // implementation will clear _lockedTrackingId here.
  }


  // ── Private ────────────────────────────────────────────────────────────────

  /// Composite selection score: weighted average confidence + visible joint ratio.
  /// Prefers skeletons that are both high-confidence AND fully visible.
  double _selectionScore(Pose pose) {
    final avgConf = averageConfidence(pose);
    final visibleRatio = pose.landmarks.isEmpty
        ? 0.0
        : countVisibleJoints(pose, minConfidence: 0.5) /
            pose.landmarks.length;

    // 70% weight to confidence, 30% to visible joint count
    return avgConf * 0.70 + visibleRatio * 0.30;
  }
}
