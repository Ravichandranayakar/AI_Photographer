// ignore_for_file: avoid_print

import 'package:frozen_ai/engine/guidance/decision_engine.dart';
import 'package:frozen_ai/engine/guidance/guidance_config.dart';
import 'package:frozen_ai/engine/guidance/guidance_signal.dart';
import 'package:frozen_ai/engine/guidance/joint_error.dart';
import 'package:frozen_ai/engine/models/pose_match_result.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Research Topic 06 — Offline Validation Tests
// ─────────────────────────────────────────────────────────────────────────────
//
// Run with:
//   flutter test test/guidance/topic_6_offline_test.dart -v
//
// No camera. No UI. No device needed.
// These tests validate the math inside Engine 6 (Decision Engine).
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Engine 6 — Decision Engine (Topic 6 Offline Validation)', () {
    // ────────────────────────────────────────────────────────────────────────
    // TEST 1: Utility Sort beats raw score
    // U(left_forearm) = (1-0.20) × 0.2 × 1.0 = 0.160
    // U(pelvis)       = (1-0.50) × 0.5 × 1.0 = 0.250  ← WINNER (Core > Secondary)
    // ────────────────────────────────────────────────────────────────────────
    test('Utility Sort: Core bone beats Secondary bone despite worse raw score', () {
      final engine = DecisionEngine(config: const GuidanceConfig());

      final result = _buildMockResult(
        overallScore: 0.40,
        bones: {
          'pelvis':       (score: 0.50, dist: 0.30, conf: 1.0, joint: PoseLandmarkType.rightHip),
          'left_forearm': (score: 0.20, dist: 0.50, conf: 1.0, joint: PoseLandmarkType.leftWrist),
        },
      );

      final signal = engine.evaluate(matchResult: result);

      print('\n[Test 1] Expected: pelvis | Actual: ${signal.targetBone}');
      expect(signal.targetBone, equals('pelvis'),
          reason: 'Pelvis (Core, weight 0.5) must win over left_forearm (Secondary, weight 0.2) '
                  'even though left_forearm has a worse raw score (0.20 vs 0.50). '
                  'Utility = (1-S) × W × C: pelvis=0.250, left_forearm=0.160');
      expect(signal.isPostureAcceptable, isFalse);
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 2: Bandwidth Gate filters small errors
    // pelvis distance (0.05) < bandwidthThreshold (0.12) → must be ignored
    // left_humerus distance (0.20) > threshold → must win
    // ────────────────────────────────────────────────────────────────────────
    test('Bandwidth Gate: joints with distance below threshold are ignored', () {
      final engine = DecisionEngine(config: const GuidanceConfig());

      final result = _buildMockResult(
        overallScore: 0.50,
        bones: {
          'pelvis':       (score: 0.45, dist: 0.05, conf: 1.0, joint: PoseLandmarkType.rightHip),
          'left_humerus': (score: 0.55, dist: 0.20, conf: 1.0, joint: PoseLandmarkType.leftElbow),
        },
      );

      final signal = engine.evaluate(matchResult: result);

      print('\n[Test 2] Expected: left_humerus | Actual: ${signal.targetBone}');
      expect(signal.targetBone, equals('left_humerus'),
          reason: 'pelvis error distance (0.05) is below bandwidthThreshold (0.12). '
                  'It must be silently filtered. left_humerus (0.20) passes the gate.');
      expect(signal.isPostureAcceptable, isFalse);
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 3: FSM Hysteresis — bottleneck is HELD between frames
    // Frame A: pelvis is clear bottleneck (score 0.40)
    // Frame B: left_humerus gets worse (0.30) but pelvis still below DEMOTE (0.82)
    // Engine MUST keep coaching pelvis (FSM lock)
    // ────────────────────────────────────────────────────────────────────────
    test('FSM Hysteresis: bottleneck is held across frames until demote threshold', () {
      final engine = DecisionEngine(config: const GuidanceConfig());

      final frameA = _buildMockResult(
        overallScore: 0.40,
        bones: {
          'pelvis':       (score: 0.40, dist: 0.30, conf: 1.0, joint: PoseLandmarkType.rightHip),
          'left_humerus': (score: 0.80, dist: 0.20, conf: 1.0, joint: PoseLandmarkType.leftElbow),
        },
      );
      final signalA = engine.evaluate(matchResult: frameA);

      // Frame B: left_humerus worsens but pelvis (current bottleneck) is still below 0.82
      final frameB = _buildMockResult(
        overallScore: 0.45,
        bones: {
          'pelvis':       (score: 0.50, dist: 0.25, conf: 1.0, joint: PoseLandmarkType.rightHip),
          'left_humerus': (score: 0.30, dist: 0.35, conf: 1.0, joint: PoseLandmarkType.leftElbow),
        },
      );
      final signalB = engine.evaluate(matchResult: frameB);

      print('\n[Test 3] Frame A: ${signalA.targetBone} | Frame B: ${signalB.targetBone}');
      expect(signalA.targetBone, equals('pelvis'));
      expect(signalB.targetBone, equals('pelvis'),
          reason: 'Even though left_humerus got worse in Frame B, pelvis must remain '
                  'the bottleneck because its score (0.50) is still below DEMOTE_THRESHOLD (0.82). '
                  'FSM hysteresis prevents coaching flicker.');
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 4: Success signal when all errors are within bandwidth
    // All bones distance < 0.12 → GuidanceSignal.success()
    // ────────────────────────────────────────────────────────────────────────
    test('Success Signal: all errors within bandwidth returns success', () {
      final engine = DecisionEngine(config: const GuidanceConfig());

      final result = _buildMockResult(
        overallScore: 0.70,
        bones: {
          'pelvis':       (score: 0.55, dist: 0.05, conf: 1.0, joint: PoseLandmarkType.rightHip),
          'left_humerus': (score: 0.60, dist: 0.08, conf: 1.0, joint: PoseLandmarkType.leftElbow),
        },
      );

      final signal = engine.evaluate(matchResult: result);

      print('\n[Test 4] intent: ${signal.intent.name} | acceptable: ${signal.isPostureAcceptable}');
      expect(signal.isPostureAcceptable, isTrue,
          reason: 'Both bones have error distance below bandwidthThreshold (0.12). '
                  'The engine must go silent and return a success signal.');
      expect(signal.intent, equals(CorrectionIntent.success));
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 5: Confidence floor keeps low-visibility joints coachable
    // pelvis confidence=0.25, floor=0.50
    // With floor: U = (1-0.45) × 0.5 × 0.50 = 0.1375  (still useful)
    // Without floor: U = (1-0.45) × 0.5 × 0.25 = 0.069 (nearly suppressed)
    // ────────────────────────────────────────────────────────────────────────
    test('Confidence Floor: low-visibility joint retains partial utility', () {
      const config = GuidanceConfig(utilityConfidenceFloor: 0.5);
      final engine = DecisionEngine(config: config);

      final result = _buildMockResult(
        overallScore: 0.40,
        bones: {
          'pelvis': (score: 0.45, dist: 0.30, conf: 0.25, joint: PoseLandmarkType.rightHip),
        },
      );

      final signal = engine.evaluate(matchResult: result);

      print('\n[Test 5] targetBone: ${signal.targetBone} | acceptable: ${signal.isPostureAcceptable}');
      expect(signal.targetBone, equals('pelvis'),
          reason: 'Even with ML Kit confidence=0.25 (below floor=0.50), the confidence floor '
                  'clamps it to 0.50. The joint remains coachable and becomes the bottleneck.');
      expect(signal.isPostureAcceptable, isFalse);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock Builder
// ─────────────────────────────────────────────────────────────────────────────

typedef _BoneData = ({
  double score,
  double dist,
  double conf,
  PoseLandmarkType joint,
});

PoseMatchResult _buildMockResult({
  required double overallScore,
  required Map<String, _BoneData> bones,
}) {
  final boneScores = <String, double>{};
  final boneErrors = <String, JointError>{};

  for (final entry in bones.entries) {
    final name = entry.key;
    final data = entry.value;
    boneScores[name] = data.score;
    // Use a 45° vector (dx=dy=dist×0.707) to produce the given distance.
    boneErrors[name] = JointError.fromVector(
      joint: data.joint,
      dx: data.dist * 0.707,
      dy: data.dist * 0.707,
      confidence: data.conf,
      frameIndex: 1,
    );
  }

  return PoseMatchResult(
    score: overallScore,
    boneScores: Map.unmodifiable(boneScores),
    boneErrors: Map.unmodifiable(boneErrors),
    effectiveWeight: 1.0,
  );
}
