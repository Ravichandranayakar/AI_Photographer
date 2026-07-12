import 'dart:convert';
import 'dart:io';
import 'dart:math' as dart_math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';

import '../models/frozen_landmark.dart';
import '../normalizer/landmark_normalizer.dart';

/// A structured data record for a single frame of normalization evaluation.
///
/// Captures everything needed to evaluate Research Topic 2:
///   - Raw anchor coordinates and torso length (scale denominator S)
///   - All 33 normalized landmark coordinates with confidence values
///   - Guard condition status (did normalization succeed?)
///   - Frame timing for FPS analysis
class NormalizationFrame {
  final int frameIndex;
  final int timestampMs;

  /// Whether [LandmarkNormalizer.normalize] returned a valid result.
  final bool normalizationSucceeded;

  /// Raw mid-hip coordinates BEFORE normalization (pixel space).
  final double? rawMidHipX;
  final double? rawMidHipY;

  /// Torso length S (the scale denominator).
  /// After normalization, this value should be 1.0 (the skeleton is
  /// scaled to 1 torso-unit). Tracking this validates scale invariance.
  final double? torsoLengthPixels;

  /// All 33 normalized landmark values.
  /// Key: PoseLandmarkType name (e.g., 'leftShoulder').
  /// Value: Map with 'x', 'y', 'likelihood' fields.
  final Map<String, Map<String, double>>? normalizedLandmarks;

  /// Research Topic 3 Benchmarking Scores (Optional)
  final double? hybridScore;

  /// Phase 1.5 Observational Telemetry Data
  final List<Map<String, dynamic>>? capsuleTelemetry;

  const NormalizationFrame({
    required this.frameIndex,
    required this.timestampMs,
    required this.normalizationSucceeded,
    this.rawMidHipX,
    this.rawMidHipY,
    this.torsoLengthPixels,
    this.normalizedLandmarks,
    this.hybridScore,
    this.capsuleTelemetry,
  });

  Map<String, dynamic> toJson() => {
        'frame': frameIndex,
        'ts_ms': timestampMs,
        'ok': normalizationSucceeded,
        if (rawMidHipX != null) 'raw_hip_x': _round(rawMidHipX!),
        if (rawMidHipY != null) 'raw_hip_y': _round(rawMidHipY!),
        if (torsoLengthPixels != null) 'torso_px': _round(torsoLengthPixels!),
        if (normalizedLandmarks != null) 'landmarks': normalizedLandmarks,
        if (hybridScore != null) 'hybrid_score': _round(hybridScore!),
        if (capsuleTelemetry != null) 'capsule_telemetry': capsuleTelemetry,
      };

  static double _round(double v) =>
      double.parse(v.toStringAsFixed(4));
}

/// Singleton research data capture service for Phase 0 evaluation.
///
/// Writes structured JSON Lines to a file in the app's documents directory.
/// Each line is one [NormalizationFrame] record.
///
/// File location: <AppDocuments>/research_logs/topic_05_norm_<timestamp>.jsonl
///
/// Usage:
///   ResearchLogger.instance.startSession('test_translation_invariance');
///   ResearchLogger.instance.logFrame(pose, rawMidHipX, rawMidHipY, ...);
///   await ResearchLogger.instance.endSession();
class ResearchLogger {
  ResearchLogger._();
  static final ResearchLogger instance = ResearchLogger._();

  IOSink? _sink;
  int _frameIndex = 0;
  int _loggedFrameCount = 0;
  bool _isRecording = false;
  String? _currentLogPath;
  final Stopwatch _sessionTimer = Stopwatch();

  /// How many camera frames to skip between log writes.
  /// At 30 FPS with skip=10, we write ~3 records/second.
  /// Enough to capture movement without flooding disk I/O.
  static const int _frameSkip = 10;

  bool get isRecording => _isRecording;
  String? get currentLogPath => _currentLogPath;
  int get loggedFrameCount => _loggedFrameCount;

  /// Opens a new log file and starts the session.
  ///
  /// [testName] is embedded in the filename for identification.
  /// Example: 'translation_invariance', 'scale_invariance', 'jitter_baseline'.
  Future<void> startSession(String testName) async {
    if (_isRecording) await endSession();

    final dir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${dir.path}/research_logs');
    if (!logDir.existsSync()) logDir.createSync(recursive: true);

    final ts = DateTime.now().millisecondsSinceEpoch;
    _currentLogPath = '${logDir.path}/topic_05_${testName}_$ts.jsonl';

    final file = File(_currentLogPath!);
    _sink = file.openWrite(mode: FileMode.append);

    // Write a session header as the first line.
    _sink!.writeln(jsonEncode({
      'session_start': true,
      'test': testName,
      'ts': ts,
      'frame_skip': _frameSkip,
    }));

    _frameIndex = 0;
    _loggedFrameCount = 0;
    _isRecording = true;
    _sessionTimer
      ..reset()
      ..start();

    debugPrint('🔬 [ResearchLogger] Session started → $_currentLogPath');
  }

  /// Logs one camera frame.
  ///
  /// Internally throttled by [_frameSkip]. Not every frame is written.
  /// Accepts the raw [Pose] from ML Kit; runs [LandmarkNormalizer] internally
  /// so all data captured in the log reflects exactly what the engine sees.
  void logFrame(Map<PoseLandmarkType, PoseLandmark> rawLandmarks, {double? hybridScore, List<Map<String, dynamic>>? capsuleTelemetry}) {
    if (!_isRecording || _sink == null) return;

    _frameIndex++;

    // Throttle: only log every N frames to avoid overwhelming disk I/O.
    if (_frameIndex % _frameSkip != 0) return;

    // ── Run the normalizer — this is the module under test ───────────────────

    // Extract raw anchor coordinates for logging BEFORE normalization.
    final leftHip = rawLandmarks[PoseLandmarkType.leftHip];
    final rightHip = rawLandmarks[PoseLandmarkType.rightHip];
    final leftShoulder = rawLandmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = rawLandmarks[PoseLandmarkType.rightShoulder];

    double? rawMidHipX, rawMidHipY, torsoLengthPixels;

    if (leftHip != null && rightHip != null &&
        leftShoulder != null && rightShoulder != null) {
      rawMidHipX = (leftHip.x + rightHip.x) / 2.0;
      rawMidHipY = (leftHip.y + rightHip.y) / 2.0;
      final midShoulderX = (leftShoulder.x + rightShoulder.x) / 2.0;
      final midShoulderY = (leftShoulder.y + rightShoulder.y) / 2.0;
      // Torso length S (in raw pixel units of the image frame).
      torsoLengthPixels =
          _distance(midShoulderX, midShoulderY, rawMidHipX, rawMidHipY);

    }

    final Map<PoseLandmarkType, FrozenLandmark>? normalized =
        LandmarkNormalizer.normalize(rawLandmarks);

    Map<String, Map<String, double>>? landmarkLog;
    if (normalized != null) {
      landmarkLog = {};
      for (final entry in normalized.entries) {
        landmarkLog[entry.key.name] = {
          'x': double.parse(entry.value.x.toStringAsFixed(4)),
          'y': double.parse(entry.value.y.toStringAsFixed(4)),
          'c': double.parse(entry.value.likelihood.toStringAsFixed(2)),
        };
      }
    }

    final record = NormalizationFrame(
      frameIndex: _frameIndex,
      timestampMs: _sessionTimer.elapsedMilliseconds,
      normalizationSucceeded: normalized != null,
      rawMidHipX: rawMidHipX,
      rawMidHipY: rawMidHipY,
      torsoLengthPixels: torsoLengthPixels,
      normalizedLandmarks: landmarkLog,
      hybridScore: hybridScore,
      capsuleTelemetry: capsuleTelemetry,
    );

    _sink!.writeln(jsonEncode(record.toJson()));
    _loggedFrameCount++;

    // Also emit to Flutter debug console so it appears in `flutter run` terminal.
    if (kDebugMode && _loggedFrameCount % 3 == 0) {
      debugPrint(
        '🔬 [T05] frame=${record.frameIndex} '
        'ok=${record.normalizationSucceeded} '
        'hip=(${rawMidHipX?.toStringAsFixed(1)}, '
        '${rawMidHipY?.toStringAsFixed(1)}) '
        'torso=${torsoLengthPixels?.toStringAsFixed(1)}px '
        'norm_hip_y=${normalized?[PoseLandmarkType.leftHip]?.y.toStringAsFixed(3)}'
        ' [logged: $_loggedFrameCount frames]',
      );
    }
  }

  /// Flushes and closes the log file.
  Future<String?> endSession() async {
    if (!_isRecording || _sink == null) return null;

    _sessionTimer.stop();
    _sink!.writeln(jsonEncode({
      'session_end': true,
      'duration_ms': _sessionTimer.elapsedMilliseconds,
      'total_frames_seen': _frameIndex,
      'logged_frames': _loggedFrameCount,
    }));

    await _sink!.flush();
    await _sink!.close();
    _sink = null;
    _isRecording = false;

    debugPrint(
      '🔬 [ResearchLogger] Session ended. '
      'Logged $_loggedFrameCount frames → $_currentLogPath',
    );

    return _currentLogPath;
  }

  double _distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return dart_math.sqrt(dx * dx + dy * dy);
  }
}
