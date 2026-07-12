/// Topic 5 — Silhouette Geometry Evaluator
///
/// Standalone evaluation script for the Body Silhouette Generation engine.
/// Runs the full geometric pipeline (Confidence Gate → Topology → Kinematic
/// Expansion → Chaikin Subdivision) on REAL landmark data from existing
/// Topic 4 JSONL logs — without any Flutter dependency.
///
/// What this file does:
///   1. Loads real normalized landmark coordinates from Topic 4 benchmark logs.
///   2. Runs the complete Phase A + Phase B silhouette math on each frame.
///   3. Reports vertex counts at every pipeline stage (input → hull → final).
///   4. Validates that no NaN or Infinity values appear in the output (ε-guard check).
///   5. Measures average execution time per frame over 10,000 iterations.
///
/// Run from project root:
///   dart run research/05_body_silhouette/geometry_evaluator.dart
///
/// Pass Criteria:
///   ✅ Full pipeline runs without crash
///   ✅ No NaN or Infinity in output coordinates (validates ε-guard)
///   ✅ Vertex count scales correctly (22 joints → ~44 hull → ~352 final)
///   ✅ Execution time < 1.0 ms per frame

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// Minimal Vec2 (identical math to lib/engine/silhouette/vec2.dart)
// Duplicated here so this script runs standalone without Flutter dependencies.
// ─────────────────────────────────────────────────────────────────────────────
class Vec2 {
  final double x, y;
  const Vec2(this.x, this.y);

  Vec2 operator +(Vec2 o) => Vec2(x + o.x, y + o.y);
  Vec2 operator -(Vec2 o) => Vec2(x - o.x, y - o.y);
  Vec2 operator *(double s) => Vec2(x * s, y * s);

  double get length => math.sqrt(x * x + y * y);
  bool get isDegenerate => length < 1e-6;

  Vec2 get normalized {
    final l = length;
    return Vec2(x / l, y / l);
  }

  // CCW perpendicular normal
  Vec2 get normalCCW {
    final u = normalized;
    return Vec2(-u.y, u.x);
  }

  bool get hasNaN => x.isNaN || y.isNaN || x.isInfinite || y.isInfinite;

  @override
  String toString() => '(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase A: Kinematic Expansion (simplified topology for evaluation)
// ─────────────────────────────────────────────────────────────────────────────
class KinematicHullEvaluator {
  static List<Vec2> generate(
    Map<String, Vec2> joints,
    List<String> topology,
    Map<String, double> radii,
    double scaleFactor,
  ) {
    final List<Vec2> hull = [];
    Vec2? prevNormal;

    for (int i = 0; i < topology.length; i++) {
      final name = topology[i];
      final current = joints[name];
      if (current == null) continue;

      final nextName = topology[(i + 1) % topology.length];
      final next = joints[nextName];
      if (next == null) continue;

      final bone = next - current;
      if (bone.isDegenerate) {
        // ε-guard: reuse previous valid normal on degenerate edge
        if (prevNormal != null) {
          final r = (radii[name] ?? 12.0) * scaleFactor;
          hull.add(current + prevNormal! * r);
        }
        continue;
      }

      final normal = bone.normalCCW;
      prevNormal = normal;
      final r = (radii[name] ?? 12.0) * scaleFactor;
      hull.add(current + normal * r);
    }

    // Synthetic crotch anchor
    final lh = joints['leftHip'];
    final rh = joints['rightHip'];
    if (lh != null && rh != null) {
      final mx = (lh.x + rh.x) / 2.0;
      final my = (lh.y + rh.y) / 2.0;
      hull.add(Vec2(mx, my + 14.0 * scaleFactor));
    }

    return hull;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase B: Chaikin Subdivision (identical math to lib/engine/silhouette/chaikin_engine.dart)
// ─────────────────────────────────────────────────────────────────────────────
class ChaikinSubdivision {
  static List<Vec2> subdivide(List<Vec2> hull, {int iterations = 3}) {
    if (hull.length < 3) return hull;
    List<Vec2> current = List<Vec2>.from(hull);

    for (int iter = 0; iter < iterations; iter++) {
      final n = current.length;
      final next = List<Vec2>.filled(n * 2, const Vec2(0, 0));
      for (int k = 0; k < n; k++) {
        final vA = current[k];
        final vB = current[(k + 1) % n];
        next[k * 2] = Vec2(
          0.75 * vA.x + 0.25 * vB.x,
          0.75 * vA.y + 0.25 * vB.y,
        );
        next[k * 2 + 1] = Vec2(
          0.25 * vA.x + 0.75 * vB.x,
          0.25 * vA.y + 0.75 * vB.y,
        );
      }
      current = next;
    }
    return current;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  print('=' * 60);
  print('FROZEN AI — Topic 5 Silhouette Geometry Evaluator');
  print('=' * 60);

  // Load real landmark data from Topic 4 test logs
  final List<Map<String, dynamic>> frames = [];
  for (final filename in [
    'reserch topic 4/test_4_1_utf8.jsonl',
    'reserch topic 4/test_4_5_utf8.jsonl',
    'reserch topic 4/test_4_7_utf8.jsonl',
  ]) {
    final file = File(filename);
    if (!await file.exists()) {
      print('Warning: $filename not found, skipping.');
      continue;
    }
    final lines = await file.readAsLines();
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        if (json.containsKey('landmarks')) frames.add(json);
      } catch (_) {}
    }
  }

  if (frames.isEmpty) {
    print('ERROR: No valid landmark frames found. Run from project root.');
    return;
  }

  print('Loaded ${frames.length} real landmark frames from JSONL logs.\n');

  // Topology: 13-joint outer perimeter for this evaluation run
  final topology = [
    'leftShoulder',
    'leftElbow',
    'leftWrist',
    'leftHip',
    'leftKnee',
    'leftAnkle',
    'rightAnkle',
    'rightKnee',
    'rightHip',
    'rightWrist',
    'rightElbow',
    'rightShoulder',
    'nose',
  ];

  // Biological radii (initial hypotheses from SilhouetteConfig)
  final radii = <String, double>{
    'nose': 18.0,
    'leftShoulder': 20.0,
    'rightShoulder': 20.0,
    'leftElbow': 14.0,
    'rightElbow': 14.0,
    'leftWrist': 7.0,
    'rightWrist': 7.0,
    'leftHip': 22.0,
    'rightHip': 22.0,
    'leftKnee': 16.0,
    'rightKnee': 16.0,
    'leftAnkle': 8.0,
    'rightAnkle': 8.0,
  };

  const referenceTorsoLength = 200.0;

  // ── Phase 1: Correctness Evaluation (first real frame) ───────────────────
  print('─── Phase 1: Correctness Evaluation ───');
  final firstFrame = frames.first;
  final rawLandmarks = firstFrame['landmarks'] as Map<String, dynamic>;
  final torsoPx = (firstFrame['torso_px'] as num?)?.toDouble() ?? 80.0;
  final scaleFactor = torsoPx / referenceTorsoLength;

  final joints = <String, Vec2>{};
  rawLandmarks.forEach((name, data) {
    if (data is Map) {
      final x = (data['x'] as num).toDouble();
      final y = (data['y'] as num).toDouble();
      final c = (data['c'] as num).toDouble();
      if (c >= 0.5) joints[name] = Vec2(x, y); // Confidence Gate
    }
  });

  print('Valid joints (confidence ≥ 0.5) : ${joints.length}');

  final hull = KinematicHullEvaluator.generate(
    joints,
    topology,
    radii,
    scaleFactor,
  );
  final smoothed = ChaikinSubdivision.subdivide(hull, iterations: 3);

  print('Hull vertices (Phase A output)  : ${hull.length}');
  print('Final path points (3 iterations): ${smoothed.length}');

  // Validate: no NaN or Infinity (ε-guard check)
  final badPoints = smoothed.where((v) => v.hasNaN).length;
  if (badPoints > 0) {
    print(
      '⚠️  FAIL: $badPoints points contain NaN or Infinity — ε-guard broken.',
    );
  } else {
    print('✅ No NaN/Infinity in output — ε-guard validated.');
  }

  // Validate: normal orientation check (first hull point should be outside body center)
  if (hull.isNotEmpty) {
    print('\nFirst 3 hull points (inspect for outward direction):');
    for (int i = 0; i < math.min(3, hull.length); i++) {
      print('  hull[$i] = ${hull[i]}');
    }
    print(
      '→ If these look inward, flip normalCCW → normalCW in kinematic_hull.dart',
    );
  }

  // ── Phase 2: CPU Performance Evaluation ─────────────────────────────────
  print('\n─── Phase 2: CPU Performance Evaluation (10,000 frames) ───');
  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < 10000; i++) {
    final frame = frames[i % frames.length];
    final lm = frame['landmarks'] as Map<String, dynamic>;
    final tp = (frame['torso_px'] as num?)?.toDouble() ?? 80.0;
    final sf = tp / referenceTorsoLength;

    final j = <String, Vec2>{};
    lm.forEach((name, data) {
      if (data is Map) {
        final x = (data['x'] as num).toDouble();
        final y = (data['y'] as num).toDouble();
        final c = (data['c'] as num).toDouble();
        if (c >= 0.5) j[name] = Vec2(x, y);
      }
    });

    final h = KinematicHullEvaluator.generate(j, topology, radii, sf);
    ChaikinSubdivision.subdivide(
      h,
      iterations: 4,
    ); // 4 iterations for max stress
  }

  stopwatch.stop();
  final msPerFrame = stopwatch.elapsedMicroseconds / 10000.0 / 1000.0;

  print(
    'Execution time per frame: ${msPerFrame.toStringAsFixed(4)} ms (avg over 10,000 frames, 4 Chaikin iterations)',
  );

  if (msPerFrame < 1.0) {
    print('✅ PASS — Ultra-fast O(N) execution. FPS budget safe.');
  } else if (msPerFrame < 5.0) {
    print(
      '⚠️  WARNING — Acceptable but borderline. Consider reducing Chaikin iterations.',
    );
  } else {
    print('❌ FAIL — CPU overload risk. Optimize before Flutter integration.');
  }

  print('\n' + '=' * 60);
  print('Copy results into research/05_body_silhouette/benchmark.md');
  print('=' * 60);
}
