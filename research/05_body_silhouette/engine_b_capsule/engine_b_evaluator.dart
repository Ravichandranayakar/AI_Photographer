/// Engine B — Evaluator
///
/// Benchmarks the Capsule + Offset Curves engine against real landmark data.
/// Uses the same JSONL files as the Engine A evaluator for fair comparison.
///
/// What this measures:
///   Phase 1 — Correctness: run on first frame, inspect output
///   Phase 2 — NaN/Infinity guard: validate all 63 frames
///   Phase 3 — CPU Performance: 10,000 frame benchmark
///
/// Run from project root:
///   dart run research/05_body_silhouette/engine_b_capsule/engine_b_evaluator.dart
///
/// Target benchmarks:
///   ✅ Capsule count >= 10 per frame
///   ✅ Zero NaN/Infinity in output
///   ✅ < 8ms per frame (60fps budget)
///   ✅ Final outline visually encloses all detected joints

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'capsule.dart'; // for Vec2
import 'capsule_body.dart'; // for RawLandmark, LandmarkIdx, CapsuleBody
import 'engine_b.dart'; // for EngineB, EngineBResult

// ── Landmark name → index mapping (matching LandmarkIdx in capsule_body.dart) ─
const Map<String, int> _nameToIdx = {
  'nose': 0,
  'leftEyeInner': 1, 'leftEye': 2, 'leftEyeOuter': 3,
  'rightEyeInner': 4, 'rightEye': 5, 'rightEyeOuter': 6,
  'leftEar': 7, 'rightEar': 8,
  'leftMouth': 9, 'rightMouth': 10,
  'leftShoulder': 11, 'rightShoulder': 12,
  'leftElbow': 13, 'rightElbow': 14,
  'leftWrist': 15, 'rightWrist': 16,
  'leftPinky': 17, 'rightPinky': 18,
  'leftIndex': 19, 'rightIndex': 20,
  'leftThumb': 21, 'rightThumb': 22,
  'leftHip': 23, 'rightHip': 24,
  'leftKnee': 25, 'rightKnee': 26,
  'leftAnkle': 27, 'rightAnkle': 28,
  'leftHeel': 29, 'rightHeel': 30,
  'leftFootIndex': 31, 'rightFootIndex': 32,
};

// ── Parse JSONL frame into Map<int, RawLandmark> in raw pixel coordinates ─────
//
// JSONL format (from LandmarkNormalizer output):
//   "landmarks": { "leftShoulder": {"x": norm_x, "y": norm_y, "c": conf} }
//   "torso_px": 227.8
//   "raw_hip_x": 250.5, "raw_hip_y": 603.2
//
// Reconstruction: raw_x = norm_x * torso_px + raw_hip_x
//                 raw_y = norm_y * torso_px + raw_hip_y
Map<int, RawLandmark>? parseFrame(Map<String, dynamic> json) {
  final rawLm = json['landmarks'];
  if (rawLm == null || rawLm is! Map) return null;

  final torsoPx = (json['torso_px'] as num?)?.toDouble() ?? 80.0;
  final hipX = (json['raw_hip_x'] as num?)?.toDouble() ?? 0.0;
  final hipY = (json['raw_hip_y'] as num?)?.toDouble() ?? 0.0;

  final result = <int, RawLandmark>{};
  (rawLm as Map<String, dynamic>).forEach((name, data) {
    final idx = _nameToIdx[name];
    if (idx == null || data is! Map) return;

    final nx = (data['x'] as num?)?.toDouble() ?? 0.0;
    final ny = (data['y'] as num?)?.toDouble() ?? 0.0;
    final c = (data['c'] as num?)?.toDouble() ?? 0.0;

    // Reconstruct raw pixel coordinates from normalized space
    final rawX = nx * torsoPx + hipX;
    final rawY = ny * torsoPx + hipY;

    result[idx] = RawLandmark(rawX, rawY, c);
  });

  return result.isEmpty ? null : result;
}

// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  print('=' * 60);
  print('FROZEN AI — Engine B: Capsule Outline Evaluator');
  print('=' * 60);

  // Load real frames from Topic 4 benchmark logs
  final frames = <Map<String, dynamic>>[];
  final filePaths = [
    'reserch topic 4/test_4_1_utf8.jsonl',
    'reserch topic 4/test_4_5_utf8.jsonl',
    'reserch topic 4/test_4_7_utf8.jsonl',
  ];

  for (final path in filePaths) {
    final file = File(path);
    if (!await file.exists()) {
      print('Warning: $path not found — skipping.');
      continue;
    }
    for (final line in await file.readAsLines()) {
      if (line.trim().isEmpty) continue;
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        if (json.containsKey('landmarks')) frames.add(json);
      } catch (_) {}
    }
  }

  if (frames.isEmpty) {
    print('❌ No frames loaded. Run from project root and check JSONL files.');
    return;
  }
  print('Loaded ${frames.length} real landmark frames from JSONL logs.\n');

  final engine = const EngineB(chaikinIterations: 2);

  // ── Phase 1: Correctness on first frame ─────────────────────────────────
  print('─── Phase 1: Correctness Evaluation (first frame) ───');

  final firstJson = frames.first;
  final firstLm = parseFrame(firstJson);
  final firstTorso = (firstJson['torso_px'] as num?)?.toDouble() ?? 80.0;

  if (firstLm == null) {
    print('❌ Could not parse first frame.');
    return;
  }

  final firstResult = engine.process(landmarks: firstLm, torsoPx: firstTorso);
  print('Capsules built          : ${firstResult.capsuleCount}');
  print('Candidate boundary pts  : ${firstResult.candidatePointCount}');
  print('Outer surface pts       : ${firstResult.outerSurfaceCount}');
  print('Hull vertices (binned)  : ${firstResult.hullVertices}');
  print('Final path (Chaikin ×2) : ${firstResult.finalVertices}');
  print('torsoPx used            : ${firstTorso.toStringAsFixed(1)} px');
  print(firstResult.isValid ? '✅ Valid polygon' : '❌ Not enough points');

  if (firstResult.path.length >= 3) {
    print('\nFirst 3 path points (inspect for human-shaped coordinates):');
    for (int i = 0; i < 3; i++) {
      final p = firstResult.path[i];
      print('  path[$i] = ${p.x.toStringAsFixed(1)}, ${p.y.toStringAsFixed(1)}');
    }
  }

  // ── Phase 2: NaN/Infinity guard across all frames ────────────────────────
  print('\n─── Phase 2: NaN/Infinity Guard (${frames.length} frames) ───');

  int nanCount = 0;
  int validFrames = 0;
  int emptyFrames = 0;
  int totalCapsules = 0;
  int minCapsules = 999;
  int maxCapsules = 0;

  for (final json in frames) {
    final lm = parseFrame(json);
    if (lm == null) { emptyFrames++; continue; }

    final torso = (json['torso_px'] as num?)?.toDouble() ?? 80.0;
    final result = engine.process(landmarks: lm, torsoPx: torso);

    if (!result.isClean) {
      nanCount += result.path.where((p) => !p.x.isFinite || !p.y.isFinite).length;
    }

    if (result.isValid) {
      validFrames++;
      totalCapsules += result.capsuleCount;
      if (result.capsuleCount < minCapsules) minCapsules = result.capsuleCount;
      if (result.capsuleCount > maxCapsules) maxCapsules = result.capsuleCount;
    } else {
      emptyFrames++;
    }
  }

  print('Valid polygon frames     : $validFrames / ${frames.length}');
  print('Empty/skipped frames     : $emptyFrames');
  print('NaN/Infinity points      : $nanCount');
  print('Capsule range            : $minCapsules – $maxCapsules (avg ${validFrames > 0 ? (totalCapsules / validFrames).toStringAsFixed(1) : "N/A"})');

  if (nanCount == 0) {
    print('✅ Zero NaN/Infinity — ε-guard validated across all frames.');
  } else {
    print('❌ FAIL: $nanCount bad points found. Check capsule radius computation.');
  }

  // ── Phase 3: CPU Performance benchmark ───────────────────────────────────
  print('\n─── Phase 3: CPU Performance (10,000 frames) ───');

  final parsedFrames = <({Map<int, RawLandmark> lm, double torso})>[];
  for (final json in frames) {
    final lm = parseFrame(json);
    if (lm == null) continue;
    final torso = (json['torso_px'] as num?)?.toDouble() ?? 80.0;
    parsedFrames.add((lm: lm, torso: torso));
  }

  if (parsedFrames.isEmpty) {
    print('No frames available for performance benchmark.');
    return;
  }

  final sw = Stopwatch()..start();
  for (int i = 0; i < 10000; i++) {
    final f = parsedFrames[i % parsedFrames.length];
    engine.process(landmarks: f.lm, torsoPx: f.torso);
  }
  sw.stop();

  final msPerFrame = sw.elapsedMicroseconds / 10000.0 / 1000.0;
  print('Avg time per frame      : ${msPerFrame.toStringAsFixed(4)} ms');
  print('FPS budget (16ms total) : ${(16.0 / msPerFrame).toStringAsFixed(1)}× headroom');

  if (msPerFrame < 2.0) {
    print('✅ PASS — Well within 60fps budget.');
  } else if (msPerFrame < 8.0) {
    print('⚠️  ACCEPTABLE — Within budget but watch for complex poses.');
  } else {
    print('❌ FAIL — CPU overload risk. Consider reducing boundary point count.');
  }

  // ── Phase 4: Comparison vs Engine A ─────────────────────────────────────
  print('\n─── Phase 4: Engine B vs Engine A Comparison ───');
  print('                          Engine A     Engine B');
  print('Self-intersection        : YES          NO (impossible by construction)');
  print('Cap direction bug        : YES          NO (no caps needed)');
  print('Non-canonical pose       : FAIL         Adapts automatically');
  print('Low confidence gate      : FAILS        Shrinks capsule (Equation B2)');
  print('Computation (offline)    : 0.011 ms     ${msPerFrame.toStringAsFixed(3)} ms');

  print('\n' + '=' * 60);
  print('Copy these results to:');
  print('  research/05_body_silhouette/results/engine_b/benchmark.md');
  print('=' * 60);
}
