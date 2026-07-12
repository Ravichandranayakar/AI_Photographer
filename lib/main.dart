import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'engine/research/research_logger.dart';
import 'engine/normalizer/landmark_normalizer.dart';
import 'engine/matcher/pose_matcher.dart';
import 'engine/research/target_poses.dart';
import 'engine/smoothing/frozen_euro_filter.dart';
import 'engine/smoothing/score_smoother.dart';
import 'engine/silhouette/silhouette_engine.dart';
import 'engine/silhouette/silhouette_config.dart';
import 'engine/silhouette/silhouette_painter.dart';
import 'engine/engine_b_adapter.dart'; // Engine B: Capsule + Offset Curves


late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const PoseVisualizerPage(),
    );
  }
}

class PoseVisualizerPage extends StatefulWidget {
  const PoseVisualizerPage({super.key});

  @override
  State<PoseVisualizerPage> createState() => _PoseVisualizerPageState();
}

class _PoseVisualizerPageState extends State<PoseVisualizerPage> {
  CameraController? _cameraController;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );
  
  bool _isProcessing = false;
  List<Pose> _detectedPoses = [];
  Size? _imageSize;
  
  // Smoothing & Orchestration
  final FrozenEuroFilter _euroFilter = FrozenEuroFilter();
  final EmaScoreSmoother _scoreSmoother = EmaScoreSmoother();
  int _frameCount = 0;

  // Topic 5: Silhouette Generation Engine
  final SilhouetteEngine _silhouetteEngine = const SilhouetteEngine(
    config: SilhouetteConfig(),
  );
  SilhouetteResult _silhouetteResult = SilhouetteResult.empty();

  // Live debug values for on-screen display
  String _liveRawScore = "Raw: --%";
  String _liveEmaScore = "EMA: --%";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (_cameras.isEmpty) return;

    // Use front camera for posing / selfie coaching
    final frontCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      _cameraController!.startImageStream(_processCameraImage);
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print("Camera initialization error: $e");
      }
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        final poses = await _poseDetector.processImage(inputImage);

        // ── Research Topic 3 Benchmarking ────────────────────────────────────
        if (poses.isNotEmpty) {
          _frameCount++;
          
          // ── Warm-up Frames (Skip first 15 to allow camera/exposure to settle) ──
          if (_frameCount > 15) {
            final stopwatchPipeline = Stopwatch()..start();
            final pose = poses.first;
            final timestamp = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
            
            // 1. Smooth Raw ML Kit Pixels
            final stopwatchFilter = Stopwatch()..start();
            final smoothedLandmarks = _euroFilter.processPose(pose.landmarks, timestamp);
            stopwatchFilter.stop();

            // ── RESEARCH STATUS: ENGINE B ACTIVE (2026-07-09) ───────────────
            // Engine A (Topology + Chaikin) → FROZEN (self-intersecting polygons)
            // Engine B (Capsule + Offset Curves) → ACTIVE
            //
            // Engine B pipeline:
            //   smoothedLandmarks → 17 capsules → outer surface points
            //   → polar binning (72 bins) → Chaikin ×2 → SilhouetteResult
            //
            // Equations: B1 (capsule distance), B2 (adaptive radius),
            //            B3 (angle-aware thickness), B4 (waist), B5+B6 (surface)
            // ─────────────────────────────────────────────────────────────────

            // Compute torsoPx from raw pixel coordinates (same as before)
            double torsoPx = 80.0; // fallback
            final leftHip = smoothedLandmarks[PoseLandmarkType.leftHip];
            final rightHip = smoothedLandmarks[PoseLandmarkType.rightHip];
            final leftShoulder = smoothedLandmarks[PoseLandmarkType.leftShoulder];
            final rightShoulder = smoothedLandmarks[PoseLandmarkType.rightShoulder];
            if (leftHip != null && rightHip != null &&
                leftShoulder != null && rightShoulder != null) {
              final midHipX = (leftHip.x + rightHip.x) / 2;
              final midHipY = (leftHip.y + rightHip.y) / 2;
              final midShX = (leftShoulder.x + rightShoulder.x) / 2;
              final midShY = (leftShoulder.y + rightShoulder.y) / 2;
              final dx = midShX - midHipX;
              final dy = midShY - midHipY;
              final computed = math.sqrt(dx * dx + dy * dy);
              torsoPx = computed > 0 ? computed : 80.0;
            }

            // Run Engine B
            final silhouette = EngineBAdapter.process(
              smoothedLandmarks: smoothedLandmarks,
              torsoPx: torsoPx,
            );

            // 3. Normalize Smoothed Skeleton
            final normalized = LandmarkNormalizer.normalize(smoothedLandmarks);
            
            double? hybridScore;

            if (normalized != null) {
              // 3. Pose Matcher (Hybrid Cosine)
              hybridScore = PoseMatcher.compute(
                userLandmarks: normalized,
                targetLandmarks: TargetPoses.standingPose,
              ).score;
              
              // 4. Score Smoothing (EMA)
              final double uiScore = _scoreSmoother.process(hybridScore);
              
              if (mounted) {
                _liveRawScore = "Raw Score: ${(hybridScore * 100).toStringAsFixed(1)}%";
                _liveEmaScore = "EMA Smoothed: ${(uiScore * 100).toStringAsFixed(1)}%";
              }
            }

            // Feed into ResearchLogger
            ResearchLogger.instance.logFrame(
              smoothedLandmarks,
              hybridScore: hybridScore,
              capsuleTelemetry: silhouette.capsuleTelemetry,
            );
            
            stopwatchPipeline.stop();
            
            if (mounted) {
              setState(() {
                _silhouetteResult = silhouette;
              });
            }

            if (kDebugMode && _frameCount % 30 == 0) {
              if (silhouette.csgPath != null) {
                // v2 CSG telemetry
                print('Frame: $_frameCount [v2 CSG] '
                  '| Capsules: ${silhouette.inputJoints} '
                  '| SubPaths: ${silhouette.csgSubPaths} '
                  '| Extraction: ${silhouette.extractionUs / 1000.0}ms '
                  '| Pipeline: ${stopwatchPipeline.elapsedMicroseconds / 1000.0}ms');
              } else {
                // v1 Polar telemetry
                print('Frame: $_frameCount [v1 Polar] '
                  '| Filter: ${stopwatchFilter.elapsedMicroseconds / 1000.0}ms '
                  '| Pipeline: ${stopwatchPipeline.elapsedMicroseconds / 1000.0}ms '
                  '| Hull: ${silhouette.hullVertices} → ${silhouette.finalVertices} pts');
              }
            }
          }
        }
        // ─────────────────────────────────────────────────────────────────────

        if (mounted) {
          setState(() {
            _detectedPoses = poses;
            _imageSize = Size(image.width.toDouble(), image.height.toDouble());
            // BUG FIX: Clear silhouette when no person detected.
            // Without this, the outline from the last frame freezes on screen
            // even after the subject walks out of frame (ghost outline bug).
            if (poses.isEmpty) {
              _silhouetteResult = SilhouetteResult.empty();
            }
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing image: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final sensorOrientation = _cameraController!.description.sensorOrientation;
    InputImageRotation? rotation;
    
    // Calculate rotation based on sensor orientation
    if (sensorOrientation == 90) {
      rotation = InputImageRotation.rotation90deg;
    } else if (sensorOrientation == 180) {
      rotation = InputImageRotation.rotation180deg;
    } else if (sensorOrientation == 270) {
      rotation = InputImageRotation.rotation270deg;
    } else if (sensorOrientation == 0) {
      rotation = InputImageRotation.rotation0deg;
    }
    
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    ResearchLogger.instance.endSession();
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Frozen AI — Research Phase 0'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          // Topic 5: Silhouette Painter — smooth glowing body outline
          // Normal direction confirmed OUTWARD from visual testing (2026-07-09).
          // Stick-figure PosePainter removed — no longer needed.
          if (_imageSize != null && _silhouetteResult.isValid)
            CustomPaint(
              painter: SilhouettePainter(
                result: _silhouetteResult,
                imageSize: _imageSize!,
                sensorRotation: _cameraController!.description.sensorOrientation,
              ),
            ),
        ],
      ),
      floatingActionButton: _ResearchRecordButton(),
    );
  }
}

/// FAB that controls the ResearchLogger session.
/// START → prompts for test name → begins logging.
/// STOP  → ends session and shows the log file path.
class _ResearchRecordButton extends StatefulWidget {
  @override
  State<_ResearchRecordButton> createState() => _ResearchRecordButtonState();
}

class _ResearchRecordButtonState extends State<_ResearchRecordButton> {
  bool _recording = false;

  Future<void> _toggle() async {
    if (_recording) {
      final path = await ResearchLogger.instance.endSession();
      if (mounted) {
        setState(() => _recording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Log saved:\n$path'),
            duration: const Duration(seconds: 6),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } else {
      await _showTestNameDialog();
    }
  }

  Future<void> _showTestNameDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Start Research Session',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. translation_test',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('START',
                style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      await ResearchLogger.instance.startSession(controller.text.trim());
      if (mounted) setState(() => _recording = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _toggle,
      backgroundColor: _recording ? Colors.red.shade700 : Colors.cyan.shade800,
      icon: Icon(_recording ? Icons.stop : Icons.fiber_manual_record),
      label: Text(
        _recording
            ? 'STOP (${ResearchLogger.instance.loggedFrameCount} frames)'
            : 'RECORD',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class PosePainter extends CustomPainter {

  final List<Pose> poses;
  final Size imageSize;
  final int rotation;

  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill
      ..strokeWidth = 4.0;

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (final pose in poses) {
      // Draw landmarks
      pose.landmarks.forEach((type, landmark) {
        // Translate landmarks from image space to canvas space
        final x = _translateX(landmark.x, size, imageSize, rotation);
        final y = _translateY(landmark.y, size, imageSize, rotation);
        
        canvas.drawCircle(Offset(x, y), 5.0, paint);
      });

      // Draw helper connections between points (e.g. shoulders, arms)
      void drawLine(PoseLandmarkType type1, PoseLandmarkType type2) {
        final lm1 = pose.landmarks[type1];
        final lm2 = pose.landmarks[type2];
        if (lm1 != null && lm2 != null) {
          final x1 = _translateX(lm1.x, size, imageSize, rotation);
          final y1 = _translateY(lm1.y, size, imageSize, rotation);
          final x2 = _translateX(lm2.x, size, imageSize, rotation);
          final y2 = _translateY(lm2.y, size, imageSize, rotation);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
        }
      }

      // Torso
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

      // Arms
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

      // Legs
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    }
  }

  double _translateX(double x, Size canvasSize, Size imageSize, int rotation) {
    if (rotation == 90 || rotation == 270) {
      return canvasSize.width - (x * canvasSize.width / imageSize.height);
    }
    return x * canvasSize.width / imageSize.width;
  }

  double _translateY(double y, Size canvasSize, Size imageSize, int rotation) {
    if (rotation == 90 || rotation == 270) {
      return y * canvasSize.height / imageSize.width;
    }
    return y * canvasSize.height / imageSize.height;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
