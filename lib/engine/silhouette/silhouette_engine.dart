import 'dart:ui' show Path;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'chaikin_engine.dart';
import 'kinematic_hull.dart';
import 'silhouette_config.dart';
import 'vec2.dart';

/// The result produced by [SilhouetteEngine] on each frame.
class SilhouetteResult {
  /// The final smooth closed path points ready for Flutter's CustomPainter.
  /// Used by Engine A (kinematic hull) and Engine B v1 (polar binning).
  final List<Vec2> path;

  /// [v2 CSG] Pre-merged Flutter Path from CsgExtractor.
  /// When non-null, the painter draws this directly — bypassing _buildPath().
  /// Already in ML Kit pixel space; painter _tx/_ty still applied.
  final Path? csgPath;

  /// Telemetry for benchmarking. Records vertex counts at each pipeline stage.
  final int inputJoints;
  final int hullVertices;
  final int finalVertices;

  /// Extraction time in microseconds (v2 CSG only — 0 for v1).
  final int extractionUs;

  /// Number of CSG sub-paths in the merged result.
  /// 1 = fully connected body (ideal). >1 = disconnected segments (failure).
  final int csgSubPaths;
  
  /// Telemetry data from Phase 1.5 Observational Validators
  final List<Map<String, dynamic>>? capsuleTelemetry;

  /// True if the engine produced something renderable.
  bool get isValid => path.length >= 3 || csgPath != null;

  const SilhouetteResult({
    required this.path,
    required this.inputJoints,
    required this.hullVertices,
    required this.finalVertices,
    this.csgPath,
    this.extractionUs = 0,
    this.csgSubPaths = 0,
    this.capsuleTelemetry,
  });

  /// Returns an empty result when there are insufficient landmarks.
  factory SilhouetteResult.empty() => const SilhouetteResult(
        path: [],
        inputJoints: 0,
        hullVertices: 0,
        finalVertices: 0,
        csgPath: null,
        extractionUs: 0,
        csgSubPaths: 0,
      );
}

/// Top-level orchestrator for the Silhouette Generation Pipeline.
///
/// Executes the three stages in strict sequence:
///
///   Pre-Stage : Confidence Gate  (inside KinematicHull)
///   Stage 1   : Topology Router  (inside KinematicHull via TopologyRouter)
///   Stage 2   : Kinematic Expansion (KinematicHull.generate)
///   Stage 3   : Chaikin Subdivision (ChaikinEngine.subdivide)
///
/// Usage:
///   final engine = SilhouetteEngine();
///   final result = engine.process(landmarks: smoothedLandmarks, torsoPx: torsoPx);
///   if (result.isValid) { /* render result.path */ }
class SilhouetteEngine {
  final SilhouetteConfig config;

  const SilhouetteEngine({this.config = const SilhouetteConfig()});

  /// Processes one frame of smoothed landmarks and returns the silhouette path.
  ///
  /// [landmarks]  — filtered/smoothed landmark map from the 1 Euro Filter.
  /// [torsoPx]    — live torso pixel length from LandmarkNormalizer.
  ///
  /// Returns [SilhouetteResult.empty] if there are insufficient valid joints
  /// to render a meaningful silhouette (engine never throws).
  SilhouetteResult process({
    required Map<PoseLandmarkType, PoseLandmark> landmarks,
    required double torsoPx,
  }) {
    // ── Stage 2: Kinematic Expansion (includes Pre-Stage + Stage 1) ──────
    final hull = KinematicHull.generate(
      landmarks: landmarks,
      config: config,
      torsoPx: torsoPx,
    );

    if (hull.length < 3) return SilhouetteResult.empty();

    // ── Stage 3: Chaikin Subdivision ─────────────────────────────────────
    final smoothPath = ChaikinEngine.subdivide(
      hull,
      iterations: config.chaikinIterations,
    );

    return SilhouetteResult(
      path: smoothPath,
      inputJoints: landmarks.length,
      hullVertices: hull.length,
      finalVertices: smoothPath.length,
    );
  }
}
