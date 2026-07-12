/// A lightweight Exponential Moving Average (EMA) filter specifically designed
/// to act as a "shock absorber" for the final 1D scalar Pose Match score.
/// 
/// We do not use the heavy 1 Euro Filter here because the UI score does not 
/// suffer from spatial trailing (lag). It only needs to prevent erratic flickering
/// when confidence gates flip or micro-occlusions occur.
class EmaScoreSmoother {
  /// The smoothing factor (0.0 to 1.0).
  /// A lower value = heavier smoothing (more sluggish, but stable).
  /// A higher value = less smoothing (more responsive, but jumpy).
  /// 
  /// The user requested benchmarking values between 0.15 and 0.3.
  /// We default to 0.2 as the initial hypothesis.
  final double gamma;

  double? _prevScore;

  EmaScoreSmoother({this.gamma = 0.2});

  /// Processes the raw mathematical score and returns the UI-safe stabilized score.
  double process(double rawScore) {
    if (_prevScore == null) {
      _prevScore = rawScore;
      return rawScore;
    }

    // EMA Equation: Ŝ_t = γ * S_raw + (1 - γ) * Ŝ_{t-1}
    final double smoothedScore = (gamma * rawScore) + ((1.0 - gamma) * _prevScore!);
    
    _prevScore = smoothedScore;
    
    return smoothedScore;
  }

  /// Resets the smoother history (e.g., when the user steps out of frame).
  void reset() {
    _prevScore = null;
  }
}
