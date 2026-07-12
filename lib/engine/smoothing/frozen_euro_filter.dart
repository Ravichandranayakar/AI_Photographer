import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'filter_config.dart';

/// Tracks the mathematical history for a single physical joint.
class JointFilterState {
  double prevX = 0.0;
  double prevY = 0.0;
  double prevDx = 0.0;
  double prevDy = 0.0;
  Duration prevTimestamp = Duration.zero;
  bool isInitialized = false;
}

/// The core 1 Euro Filter Orchestrator.
/// Maintains independent state matrices for every tracked joint and applies
/// joint-specific configurations (Core vs. Extremity) dynamically.
class FrozenEuroFilter {
  // Hold mathematical history for every joint independently
  final Map<PoseLandmarkType, JointFilterState> _states = {};

  double _alpha(double cutoff, double dt) {
    final double tau = 1.0 / (2.0 * math.pi * cutoff);
    return 1.0 / (1.0 + tau / dt);
  }

  /// Processes a raw pose from ML Kit, applying the 1 Euro filter to all landmarks,
  /// and returns a new Map of smoothed landmarks.
  Map<PoseLandmarkType, PoseLandmark> processPose(
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    Duration timestamp,
  ) {
    final Map<PoseLandmarkType, PoseLandmark> smoothedLandmarks = {};

    for (final entry in landmarks.entries) {
      final PoseLandmarkType type = entry.key;
      final PoseLandmark raw = entry.value;

      _states.putIfAbsent(type, () => JointFilterState());
      final JointFilterState state = _states[type]!;

      if (!state.isInitialized) {
        state.prevX = raw.x;
        state.prevY = raw.y;
        state.prevTimestamp = timestamp;
        state.isInitialized = true;
        smoothedLandmarks[type] = raw;
        continue;
      }

      final double dt = (timestamp - state.prevTimestamp).inMicroseconds / 1000000.0;
      
      // Prevent divide by zero or negative delta time
      if (dt <= 0.0) {
        smoothedLandmarks[type] = PoseLandmark(
          type: type,
          x: state.prevX,
          y: state.prevY,
          z: raw.z,
          likelihood: raw.likelihood,
        );
        continue;
      }

      final FilterConfig config = JointProfileRegistry.getConfigForJoint(type);

      // ── X-Axis Math ──
      final double dx = (raw.x - state.prevX) / dt;
      final double alphaDx = _alpha(config.derivativeCutoff, dt);
      final double filteredDx = alphaDx * dx + (1.0 - alphaDx) * state.prevDx;
      final double cutoffX = config.minCutoff + config.beta * filteredDx.abs();
      final double alphaX = _alpha(cutoffX, dt);
      final double filteredX = alphaX * raw.x + (1.0 - alphaX) * state.prevX;

      // ── Y-Axis Math ──
      final double dy = (raw.y - state.prevY) / dt;
      final double alphaDy = _alpha(config.derivativeCutoff, dt);
      final double filteredDy = alphaDy * dy + (1.0 - alphaDy) * state.prevDy;
      final double cutoffY = config.minCutoff + config.beta * filteredDy.abs();
      final double alphaY = _alpha(cutoffY, dt);
      final double filteredY = alphaY * raw.y + (1.0 - alphaY) * state.prevY;

      // Update State
      state.prevX = filteredX;
      state.prevY = filteredY;
      state.prevDx = filteredDx;
      state.prevDy = filteredDy;
      state.prevTimestamp = timestamp;

      smoothedLandmarks[type] = PoseLandmark(
        type: type,
        x: filteredX,
        y: filteredY,
        z: raw.z, // Z is currently untouched in 2D pipeline
        likelihood: raw.likelihood, // Confidence passes through unchanged
      );
    }

    return smoothedLandmarks;
  }
}
