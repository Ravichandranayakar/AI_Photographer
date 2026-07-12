/// Configuration for the Silhouette Generation Engine.
///
/// All tuning values are centralised here. Do NOT scatter magic numbers
/// across the engine files. Any change must be benchmarked and logged in
/// research/05_body_silhouette/benchmark.md before merging.
///
/// Production Config v1.0 — Hypothesis values, to be tuned by Benchmark Suite 1.
class SilhouetteConfig {
  /// Reference torso length in pixels at ~1 m camera distance on the test device.
  ///
  /// Used to compute the per-frame scale factor:
  ///   scaleFactor = torso_px / referenceTorsoLength
  ///
  /// This is CONFIGURABLE — different phones with different camera FOV or
  /// resolution require adjustment. Default: 200.0 px.
  final double referenceTorsoLength;

  /// Number of Chaikin subdivision iterations.
  ///
  /// 3 iterations: N → 8N points. 4 iterations: N → 16N points.
  /// Target: visual quality indistinguishable from limit curve (quadratic B-Spline).
  final int chaikinIterations;

  /// Minimum confidence threshold. Joints below this are excluded before
  /// any geometry is generated.
  final double minConfidence;

  /// Biological radii per body region (in pixels at referenceTorsoLength scale).
  /// These are initial hypotheses — tuned by Benchmark Suite 1.
  final double rHead;
  final double rShoulder;
  final double rTorso;
  final double rUpperArm;
  final double rForearm;
  final double rWrist;
  final double rHip;
  final double rThigh;
  final double rCalf;
  final double rAnkle;
  final double rFoot;
  final double rCrotch;

  const SilhouetteConfig({
    this.referenceTorsoLength = 200.0,
    this.chaikinIterations = 3,
    this.minConfidence = 0.5,
    // Biological radii — tuned v1.1
    // Increased ~1.8x from v1.0 hypothesis values.
    // Reason: Chaikin subdivision shrinks the hull ~25% inward.
    // The hull radii must oversize the body to compensate, so the
    // final smoothed curve sits at the correct body boundary.
    this.rHead = 32.0,
    this.rShoulder = 36.0,
    this.rTorso = 44.0,
    this.rUpperArm = 26.0,
    this.rForearm = 20.0,
    this.rWrist = 14.0,
    this.rHip = 40.0,
    this.rThigh = 30.0,
    this.rCalf = 22.0,
    this.rAnkle = 16.0,
    this.rFoot = 18.0,
    this.rCrotch = 24.0,
  });

  /// Compute the per-frame scale factor from the Normalizer's torso_px output.
  double scaleFactorFor(double torsoPx) => torsoPx / referenceTorsoLength;
}
