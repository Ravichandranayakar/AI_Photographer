import 'dart:math' as math;
import 'capsule_body.dart' show RawLandmark;

class _TemporalState {
  double x;
  double y;
  double confidence;
  DateTime lastUpdate;

  _TemporalState(this.x, this.y, this.confidence, this.lastUpdate);
}

/// Validates landmarks and capsules using fuzzy logic (Validity Score).
/// Penalizes ML Kit garbage before constructing the regularized union.
class CapsuleValidator {
  static final Map<int, _TemporalState> _temporalState = {};

  // Tuning constants for EMA (Exponential Moving Average)
  // alpha = 0.40 means 40% new frame, 60% previous history.
  // Prioritizing maximum smoothness and stability over responsiveness.
  static const double emaAlphaPosition = 0.40;
  static const double emaAlphaConfidence = 0.20;
  static const int maxStateAgeMs = 500; // Reset if tracking lost for 500ms

  /// 1A. Temporal Smoothing (EMA Filter)
  /// Glides raw ML Kit coordinates and confidences to prevent jumping.
  static Map<int, RawLandmark> smoothLandmarks(
    Map<int, RawLandmark> currentFrame,
  ) {
    final smoothedFrame = <int, RawLandmark>{};
    final now = DateTime.now();

    for (final entry in currentFrame.entries) {
      final idx = entry.key;
      final lm = entry.value;

      var state = _temporalState[idx];

      // Initialize or reset if tracking was lost for too long
      if (state == null ||
          now.difference(state.lastUpdate).inMilliseconds > maxStateAgeMs) {
        state = _TemporalState(lm.x, lm.y, lm.confidence, now);
        _temporalState[idx] = state;
      } else {
        // Apply EMA
        state.x =
            (lm.x * emaAlphaPosition) + (state.x * (1.0 - emaAlphaPosition));
        state.y =
            (lm.y * emaAlphaPosition) + (state.y * (1.0 - emaAlphaPosition));
        state.confidence =
            (lm.confidence * emaAlphaConfidence) +
            (state.confidence * (1.0 - emaAlphaConfidence));
        state.lastUpdate = now;
      }

      smoothedFrame[idx] = RawLandmark(state.x, state.y, state.confidence);
    }
    return smoothedFrame;
  }

  /// 1B. Visibility Graph
  /// Evaluates base confidence and applies structural penalties.
  /// Returns a Map of Joint Index -> Validity Score [0.0, 1.0].
  static Map<int, double> evaluateJointScores(
    Map<int, RawLandmark> currentFrame,
  ) {
    final scores = <int, double>{};

    for (final entry in currentFrame.entries) {
      final idx = entry.key;
      final lm = entry.value;
      scores[idx] = lm.confidence.clamp(0.0, 1.0);
    }

    // ── 1B. Visibility Graph (Dependency Tree) ─────────────────────────────
    // If a parent joint's score is bad, cascade a penalty to its children.
    void applyParentPenalty(int parent, int child) {
      final pScore = scores[parent] ?? 0.0;
      final cScore = scores[child] ?? 0.0;
      // If parent is practically missing, heavily penalize the child
      if (pScore < 0.4) {
        scores[child] = cScore - 0.5;
      } else if (pScore < 0.6) {
        scores[child] = cScore - 0.2;
      }
    }

    // Left Arm: Shoulder (11) -> Elbow (13) -> Wrist (15)
    applyParentPenalty(11, 13);
    applyParentPenalty(13, 15);

    // Right Arm: Shoulder (12) -> Elbow (14) -> Wrist (16)
    applyParentPenalty(12, 14);
    applyParentPenalty(14, 16);

    // Left Leg: Hip (23) -> Knee (25) -> Ankle (27)
    applyParentPenalty(23, 25);
    applyParentPenalty(25, 27);

    // Right Leg: Hip (24) -> Knee (26) -> Ankle (28)
    applyParentPenalty(24, 26);
    applyParentPenalty(26, 28);

    return scores;
  }

  /// Telemetry data collected during the current frame (Phase 1.5 Observational Mode)
  static final List<Map<String, dynamic>> currentFrameTelemetry = [];

  static void resetTelemetry() {
    currentFrameTelemetry.clear();
  }

  /// 2. Bone Length Validator (Observational Mode)
  static double getBoneLengthPenalty(
    String boneName,
    double L,
    double torsoPx,
    double confidence,
  ) {
    if (torsoPx <= 0) return 0.0;
    final ratio = L / torsoPx;

    currentFrameTelemetry.add({
      'type': 'length',
      'joint': boneName,
      'ratio': double.parse(ratio.toStringAsFixed(3)),
      'lengthPx': double.parse(L.toStringAsFixed(1)),
      'torsoPx': double.parse(torsoPx.toStringAsFixed(1)),
      'confidence': double.parse(confidence.toStringAsFixed(2)),
      'accepted': true, // Observational mode: never rejects
    });

    return 0.0; // Return 0 penalty
  }

  /// 3. Joint Angle Validator (Observational Mode)
  static double getJointAnglePenalty(
    String jointType,
    double theta,
    double confidence,
  ) {
    final deg = theta * (180.0 / math.pi);

    currentFrameTelemetry.add({
      'type': 'angle',
      'joint': jointType,
      'angle': double.parse(deg.toStringAsFixed(1)),
      'confidence': double.parse(confidence.toStringAsFixed(2)),
      'accepted': true, // Observational mode: never rejects
    });

    return 0.0; // Return 0 penalty
  }

  static void resetTemporalState() {
    _temporalState.clear();
  }
}
