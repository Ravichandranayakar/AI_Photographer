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
// ── Phase 3: Guidance Engine ──────────────────────────────────────────
// Engine 5 (boneErrors) is populated inside PoseMatcher.
// Engine 6 (DecisionEngine) decides which joint to coach.
// Engine 7 (SilhouettePainter shift + GuidanceArrowPainter) renders it.
import 'engine/guidance/decision_engine.dart';
import 'engine/guidance/guidance_config.dart';
import 'engine/guidance/guidance_signal.dart';
import 'engine/guidance/guidance_arrow_painter.dart';
import 'engine/models/frozen_landmark.dart';
// ── Step 9: State Machine Integration Layer ────────────────────────────────────
import 'engine/state/session_controller.dart';
import 'engine/state/camera_mirror_mode.dart';


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

class _PoseVisualizerPageState extends State<PoseVisualizerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );
  
  bool _isProcessing = false;
  // _detectedPoses removed: SessionSnapshot.subject replaces this.
  Size? _imageSize;

  // Phase 3: The currently selected target pose from the library
  PoseLibraryItem _currentPose = TargetPoses.allPoses.first;
  bool _showPoses = false;

  // Target Pose Ghost — Engine B result shaped to user's body scale
  SilhouetteResult _targetSilhouetteResult = SilhouetteResult.empty();
  // _anchorPxX/Y and _userTorsoPx are computed locally in _processCameraImage,
  // not stored as fields (SessionSnapshot.targetScaleFactor replaces them).
  bool _userDetected = false;

  // Smoothing & Orchestration
  final FrozenEuroFilter _euroFilter = FrozenEuroFilter();
  final EmaScoreSmoother _scoreSmoother = EmaScoreSmoother();
  int _frameCount = 0;

  // Topic 5: Silhouette Generation Engine (instance kept for future direct calls)
  // ignore: unused_field
  final SilhouetteEngine _silhouetteEngine = const SilhouetteEngine(
    config: SilhouetteConfig(),
  );
  SilhouetteResult _silhouetteResult = SilhouetteResult.empty();

  // ── Phase 3: Guidance Engine (Topic 6) ───────────────────────────────────
  // Architecture (Option 1 — correct):
  //   main.dart runs Engine 5+6, computes GuidanceSignal, passes it to
  //   SessionController.onFrame(activeGuidance: signal).
  //   SessionSnapshot carries it as activeGuidance — painters read from there.
  //   DecisionEngine stays here so it has access to the smoothed landmarks
  //   that only exist in this pipeline. SessionController does NOT run it.
  final DecisionEngine _decisionEngine = DecisionEngine(
    config: const GuidanceConfig(),
  );

  /// Smoothed user landmarks from the last frame.
  /// Used by GuidanceArrowPainter to place the arrow exactly at the joint.
  Map<PoseLandmarkType, PoseLandmark> _smoothedLandmarks = {};

  // ── Step 9: State Machine Integration ─────────────────────────────────────────────
  /// The session controller — owns the state machine, runs global alignment,
  /// returns a SessionSnapshot every frame.
  late SessionController _sessionController;

  /// Latest snapshot from the state machine — used to gate all rendering.
  SessionSnapshot _snapshot = SessionSnapshot.idle;
  // ───────────────────────────────────────────────────────────────────────────

  /// AnimationController that drives the arrow pulse at ~1.5Hz.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  // ───────────────────────────────────────────────────────────────

  // Live debug values for on-screen display
  String _liveRawScore = "Raw: --%";
  String _liveEmaScore = "EMA: --%";
  
  /// Step 12: Developer Overlay Toggle
  bool _developerMode = false;

  // Caching for Engine B Target Ghost (Performance fix)
  String? _cachedTargetPoseId;
  SilhouetteResult? _cachedNormalizedTargetSilhouette;
  double _latestAnchorX = 0;
  double _latestAnchorY = 0;
  double _latestTorsoPx = 100;
  bool _wasUserDetected = false; // Track previous frame state to skip empty-frame setStates

  // Camera Selection
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start with front camera if available
    _cameraIndex = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    if (_cameraIndex == -1) _cameraIndex = 0;
    
    _sessionController = SessionController(
      mirrorMode: CameraMirrorMode.mirrored,
    );
    
    _initializeCamera();

    // ── Phase 3: Start arrow pulse animation ───────────────────────────────
    // ~1.5Hz: 666ms per cycle — slow enough to be readable, fast enough to be noticed.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 666),
    )..repeat(reverse: true);
    _pulseAnimation = _pulseController;
    // ───────────────────────────────────────────────────────────────────
  }

  /// WidgetsBindingObserver: fires when device orientation changes.
  /// Per frozen_ai_state_machine.md: always reset to WAIT_FOR_USER on rotation.
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _sessionController.onDeviceRotation();
    if (kDebugMode) print('[main.dart] didChangeMetrics → onDeviceRotation');
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length <= 1) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;

    // Rebuild SessionController with the new mirror mode
    _sessionController.dispose();
    final isFront = _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;
    _sessionController = SessionController(
      mirrorMode: isFront ? CameraMirrorMode.mirrored : CameraMirrorMode.unmirrored,
    );

    _isProcessing = false;
    if (_cameraController != null) {
      await _cameraController!.stopImageStream();
      await _cameraController!.dispose();
      _cameraController = null;
    }
    if (mounted) {
      setState(() {});
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameras.isEmpty) return;

    final selectedCamera = _cameras[_cameraIndex];

    _cameraController = CameraController(
      selectedCamera,
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

            // Compute torsoPx and anchor from raw pixel coordinates
            double torsoPx = 80.0; // fallback
            double anchorPxX = 0;
            double anchorPxY = 0;
            final leftHip = smoothedLandmarks[PoseLandmarkType.leftHip];
            final rightHip = smoothedLandmarks[PoseLandmarkType.rightHip];
            final leftShoulder = smoothedLandmarks[PoseLandmarkType.leftShoulder];
            final rightShoulder = smoothedLandmarks[PoseLandmarkType.rightShoulder];
            if (leftHip != null && rightHip != null &&
                leftShoulder != null && rightShoulder != null) {
              anchorPxX = (leftHip.x + rightHip.x) / 2;
              anchorPxY = (leftHip.y + rightHip.y) / 2;
              final midShX = (leftShoulder.x + rightShoulder.x) / 2;
              final midShY = (leftShoulder.y + rightShoulder.y) / 2;
              final dx = midShX - anchorPxX;
              final dy = midShY - anchorPxY;
              final computed = math.sqrt(dx * dx + dy * dy);
              torsoPx = computed > 0 ? computed : 80.0;
            }
            
            _latestAnchorX = anchorPxX;
            _latestAnchorY = anchorPxY;
            _latestTorsoPx = torsoPx;

            // Run Engine B on LIVE user body
            final silhouette = EngineBAdapter.process(
              smoothedLandmarks: smoothedLandmarks,
              torsoPx: torsoPx,
            );

            // Run Engine B on TARGET POSE at user's body scale (CACHED for 60fps performance!)
            final isFrontCamera = _cameraController?.description.lensDirection == CameraLensDirection.front;
            
            // 1. Compute normalized CSG path ONLY when pose changes
            if (_cachedTargetPoseId != _currentPose.id || _cachedNormalizedTargetSilhouette == null) {
              _cachedTargetPoseId = _currentPose.id;
              // Generate at torsoPx = 100, anchor = 0,0
              _cachedNormalizedTargetSilhouette = EngineBAdapter.processTargetPose(
                targetPose: _currentPose.pose,
                anchorPxX: 0,
                anchorPxY: 0,
                torsoPx: 100.0,
                imageHeight: 1000.0, // Arbitrary large height so it doesn't clamp at normalized scale
                mirrorX: false, // Don't mirror in cache. We apply mirror transform in paint!
              );
            }

            // 2. We don't build a new CSG. We just pass the cached silhouette, and tell SilhouettePainter
            // where to scale and translate it to match the live user!
            final targetSilhouette = _cachedNormalizedTargetSilhouette!;

            // 3. Normalize Smoothed Skeleton
            final normalizedUser = LandmarkNormalizer.normalize(smoothedLandmarks);
            
            // Step 12: Run Engine 5 (Pose Matcher)
            // If on front camera, we generate a "Mathematical Target Pose" where left/right labels
            // are swapped and X is negated. This allows the user to act as a mirror to match the ghost,
            // while PoseMatcher sees it as a mathematically valid match.
            Map<PoseLandmarkType, FrozenLandmark> matcherTargetPose = _currentPose.pose;
            if (isFrontCamera) {
              matcherTargetPose = <PoseLandmarkType, FrozenLandmark>{};
              for (final entry in _currentPose.pose.entries) {
                final type = entry.key;
                final lm = entry.value;

                PoseLandmarkType swappedType = type;
                switch (type) {
                  case PoseLandmarkType.leftEyeInner: swappedType = PoseLandmarkType.rightEyeInner; break;
                  case PoseLandmarkType.leftEye: swappedType = PoseLandmarkType.rightEye; break;
                  case PoseLandmarkType.leftEyeOuter: swappedType = PoseLandmarkType.rightEyeOuter; break;
                  case PoseLandmarkType.leftEar: swappedType = PoseLandmarkType.rightEar; break;
                  case PoseLandmarkType.leftShoulder: swappedType = PoseLandmarkType.rightShoulder; break;
                  case PoseLandmarkType.leftElbow: swappedType = PoseLandmarkType.rightElbow; break;
                  case PoseLandmarkType.leftWrist: swappedType = PoseLandmarkType.rightWrist; break;
                  case PoseLandmarkType.leftPinky: swappedType = PoseLandmarkType.rightPinky; break;
                  case PoseLandmarkType.leftIndex: swappedType = PoseLandmarkType.rightIndex; break;
                  case PoseLandmarkType.leftThumb: swappedType = PoseLandmarkType.rightThumb; break;
                  case PoseLandmarkType.leftHip: swappedType = PoseLandmarkType.rightHip; break;
                  case PoseLandmarkType.leftKnee: swappedType = PoseLandmarkType.rightKnee; break;
                  case PoseLandmarkType.leftAnkle: swappedType = PoseLandmarkType.rightAnkle; break;
                  case PoseLandmarkType.leftHeel: swappedType = PoseLandmarkType.rightHeel; break;
                  case PoseLandmarkType.leftFootIndex: swappedType = PoseLandmarkType.rightFootIndex; break;

                  case PoseLandmarkType.rightEyeInner: swappedType = PoseLandmarkType.leftEyeInner; break;
                  case PoseLandmarkType.rightEye: swappedType = PoseLandmarkType.leftEye; break;
                  case PoseLandmarkType.rightEyeOuter: swappedType = PoseLandmarkType.leftEyeOuter; break;
                  case PoseLandmarkType.rightEar: swappedType = PoseLandmarkType.leftEar; break;
                  case PoseLandmarkType.rightShoulder: swappedType = PoseLandmarkType.leftShoulder; break;
                  case PoseLandmarkType.rightElbow: swappedType = PoseLandmarkType.leftElbow; break;
                  case PoseLandmarkType.rightWrist: swappedType = PoseLandmarkType.leftWrist; break;
                  case PoseLandmarkType.rightPinky: swappedType = PoseLandmarkType.leftPinky; break;
                  case PoseLandmarkType.rightIndex: swappedType = PoseLandmarkType.leftIndex; break;
                  case PoseLandmarkType.rightThumb: swappedType = PoseLandmarkType.leftThumb; break;
                  case PoseLandmarkType.rightHip: swappedType = PoseLandmarkType.leftHip; break;
                  case PoseLandmarkType.rightKnee: swappedType = PoseLandmarkType.leftKnee; break;
                  case PoseLandmarkType.rightAnkle: swappedType = PoseLandmarkType.leftAnkle; break;
                  case PoseLandmarkType.rightHeel: swappedType = PoseLandmarkType.leftHeel; break;
                  case PoseLandmarkType.rightFootIndex: swappedType = PoseLandmarkType.leftFootIndex; break;
                  default: break;
                }

                matcherTargetPose[swappedType] = FrozenLandmark(
                  x: -lm.x, // Negate X for the mirrored coordinate system
                  y: lm.y,
                  likelihood: lm.likelihood,
                );
              }
            }

            // ── Step 9: State Machine Frame Gate ──────────────────────────────────
            // 1. Compute guidance first (Engine 5 + 6)
            double? hybridScore;
            GuidanceSignal? computedGuidance;
            if (normalizedUser != null) {
              // Engine 5: Pose Matcher (gated by state machine from previous frame)
              if (_snapshot.engine5Active) {
                final matchResult = PoseMatcher.compute(
                  userLandmarks: normalizedUser,
                  targetLandmarks: matcherTargetPose, // Use mathematical target pose!
                );
                hybridScore = matchResult.score;

                // Engine 6: Decision Engine — only when state machine permits
                if (_snapshot.engine6Active) {
                  computedGuidance = _decisionEngine.evaluate(matchResult: matchResult);
                }
              }
            }

            // 2. Feed state machine with computed guidance → get new snapshot
            final snap = _sessionController.onFrame(
              detectedPoses: poses,
              activeGuidance: computedGuidance,
              developerMode: _developerMode,
            );

            if (hybridScore != null) {
              final double uiScore = _scoreSmoother.process(hybridScore);
              if (mounted) {
                setState(() {
                  _liveRawScore = "Raw: ${(hybridScore! * 100).toStringAsFixed(1)}%";
                  _liveEmaScore = "EMA: ${(uiScore * 100).toStringAsFixed(1)}%";
                  _smoothedLandmarks = smoothedLandmarks;
                  _silhouetteResult = silhouette;
                  _targetSilhouetteResult = targetSilhouette;
                  _snapshot = snap; // ─ single source of truth
                });
              }
            } else if (mounted) {
              setState(() {
                _smoothedLandmarks = smoothedLandmarks;
                _silhouetteResult = silhouette;
                _targetSilhouetteResult = targetSilhouette;
                _snapshot = snap;
              });
            }

            // Feed into ResearchLogger
            ResearchLogger.instance.logFrame(
              smoothedLandmarks,
              hybridScore: hybridScore,
              capsuleTelemetry: silhouette.capsuleTelemetry,
            );
            
            stopwatchPipeline.stop();


            if (kDebugMode && _frameCount % 30 == 0) {
              if (silhouette.csgPath != null) {
                debugPrint('Frame: $_frameCount [v2 CSG] '
                  '| Capsules: ${silhouette.inputJoints} '
                  '| SubPaths: ${silhouette.csgSubPaths} '
                  '| Extraction: ${silhouette.extractionUs / 1000.0}ms '
                  '| Pipeline: ${stopwatchPipeline.elapsedMicroseconds / 1000.0}ms');
              } else {
                debugPrint('Frame: $_frameCount [v1 Polar] '
                  '| Filter: ${stopwatchFilter.elapsedMicroseconds / 1000.0}ms '
                  '| Pipeline: ${stopwatchPipeline.elapsedMicroseconds / 1000.0}ms '
                  '| Hull: ${silhouette.hullVertices} → ${silhouette.finalVertices} pts');
              }
            }
          }
        }
        // ─────────────────────────────────────────────────────────────────────

        if (mounted) {
          final imgW = image.width.toDouble();
          final imgH = image.height.toDouble();
          if (poses.isEmpty) {
            // No person in frame — only run setState if we transitioned from
            // "person detected" to "no person". After that, skip setState every
            // frame to prevent expensive repaints when nobody is in view.
            if (_wasUserDetected) {
              _wasUserDetected = false;
              final isRotated = _cameraController?.description.sensorOrientation == 90 ||
                                _cameraController?.description.sensorOrientation == 270;
              final mlKitWidth = isRotated ? imgH : imgW;
              final mlKitHeight = isRotated ? imgW : imgH;

              if (_cachedTargetPoseId != _currentPose.id || _cachedNormalizedTargetSilhouette == null) {
                _cachedTargetPoseId = _currentPose.id;
                _cachedNormalizedTargetSilhouette = EngineBAdapter.processTargetPose(
                  targetPose: _currentPose.pose,
                  anchorPxX: 0,
                  anchorPxY: 0,
                  torsoPx: 100.0,
                  imageHeight: 1000.0,
                  mirrorX: false,
                );
              }
              
              setState(() {
                _imageSize = Size(imgW, imgH);
                _silhouetteResult = SilhouetteResult.empty();
                _userDetected = false;
                _latestAnchorX = mlKitWidth * 0.5;
                _latestAnchorY = mlKitHeight * 0.5;
                _latestTorsoPx = mlKitHeight * 0.15;
                _targetSilhouetteResult = _cachedNormalizedTargetSilhouette!;
                final snap = _sessionController.onFrame(detectedPoses: poses);
                _snapshot = snap;
              });
            } else {
              // Still no person — skip setState to prevent constant repaints
              _sessionController.onFrame(detectedPoses: poses);
            }
          } else {
            _wasUserDetected = true;
            // All the per-frame state (silhouette, snapshot, scores) is already
            // set inside the setState calls above (lines ~388-404).
            // We just need to update imageSize here if it hasn't been set yet.
            if (_imageSize == null) {
              setState(() {
                _imageSize = Size(image.width.toDouble(), image.height.toDouble());
              });
            }
          }
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
    WidgetsBinding.instance.removeObserver(this); // ─ rotation observer
    _sessionController.dispose();
    _pulseController.dispose();
    ResearchLogger.instance.endSession();
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Feed (Long press toggles Developer Mode)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () {
              setState(() {
                _developerMode = !_developerMode;
              });
            },
            child: CameraPreview(_cameraController!),
          ),
          
          // 2. Target Pose Ghost — cyan/green ghost outline of the target pose.
          //    State machine gates visibility via snapshot.showTargetGhost.
          //    COORDINATE CONTRACT:
          //    processTargetPose always outputs coords in raw ML Kit pixel space (mirrorX:false).
          //    The painter applies the SAME screen-space transform as the live body painter.
          //    This means on front camera both outlines are flipped identically, so the ghost
          //    appears in the same screen position as where the user's body will be.
          if (_imageSize != null && _targetSilhouetteResult.isValid && _snapshot.showTargetGhost)
            CustomPaint(
              painter: SilhouettePainter(
                result: _targetSilhouetteResult,
                imageSize: _imageSize!,
                sensorRotation: _cameraController!.description.sensorOrientation,
                mirrorMode: _snapshot.mirrorMode, // Same as live body — painter handles the flip
                appState: _snapshot.appState,
                ghostMode: true,
                ghostAnchorX: _latestAnchorX,
                ghostAnchorY: _latestAnchorY,
                ghostTorsoPx: _latestTorsoPx,
                ghostMirrorX: _cameraController?.description.lensDirection == CameraLensDirection.front,
              ),
            ),

          // 3. Live Body Silhouette — state machine gates via snapshot.showLiveOutline.
          //    Turns green when appState == poseMatched / captureCountdown.
          if (_imageSize != null && _silhouetteResult.isValid && _snapshot.showLiveOutline)
            CustomPaint(
              painter: SilhouettePainter(
                result: _silhouetteResult,
                imageSize: _imageSize!,
                sensorRotation: _cameraController!.description.sensorOrientation,
                mirrorMode: _snapshot.mirrorMode,
                appState: _snapshot.appState,
                guidanceSignal: _snapshot.activeGuidance,
              ),
            ),

          // 4. Arrow Painter — only when state machine allows guidance overlay.
          if (_imageSize != null &&
              _snapshot.guidanceOverlayActive &&
              !(_snapshot.activeGuidance?.isPostureAcceptable ?? true))
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) => CustomPaint(
                painter: GuidanceArrowPainter(
                  signal: _snapshot.activeGuidance ?? GuidanceSignal.ready(),
                  userLandmarks: _smoothedLandmarks,
                  imageSize: _imageSize!,
                  sensorRotation: _cameraController!.description.sensorOrientation,
                  animationValue: _pulseAnimation.value,
                  mirrorMode: _snapshot.mirrorMode,
                ),
              ),
            ),

          // 5. State hint overlay — shown during WAIT_FOR_USER and GLOBAL_ALIGNMENT
          if (_snapshot.uiHint != null && _snapshot.uiHint!.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _snapshot.uiHint!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          // 6. Developer Telemetry Overlay (Step 11 & 12)
          if (_developerMode)
            Positioned(
              bottom: _showPoses ? 260 : 130,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("DEV TELEMETRY", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("State: ${_snapshot.appState.name}", style: const TextStyle(color: Colors.white, fontSize: 11)),
                    Text("Target Score: ${_liveEmaScore.replaceAll('EMA: ', '')}", style: const TextStyle(color: Colors.white, fontSize: 11)),
                    if (_snapshot.activeGuidance != null) ...[
                      const SizedBox(height: 4),
                      Text("Intent: ${_snapshot.activeGuidance!.intent.name}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text("Priority: ${_snapshot.activeGuidance!.priority.name}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text("Bottleneck: ${_snapshot.activeGuidance!.targetJoint.name}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text("Severity: ${_snapshot.activeGuidance!.severity.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ],
                ),
              ),
            ),

          // 4. UI Overlay (Pose Selector & Controls)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // TOP BAR: Scores
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: _ScoreBadge(label: "Raw", value: _liveRawScore)),
                      const SizedBox(width: 8),
                      Flexible(child: _ScoreBadge(label: "EMA", value: _liveEmaScore)),
                    ],
                  ),
                ),

                // Guidance hint — explains what CYAN and WHITE mean
                if (_userDetected)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ColorDot(color: Color(0xFF00FFFF)),
                        SizedBox(width: 4),
                        Text('Target', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        SizedBox(width: 16),
                        _ColorDot(color: Colors.white),
                        SizedBox(width: 4),
                        Text('You', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Step into frame to start',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                
                // BOTTOM BAR: Carousel & Shutter
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pose Carousel
                    if (_showPoses)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: TargetPoses.allPoses.length,
                          itemBuilder: (context, index) {
                            final poseItem = TargetPoses.allPoses[index];
                            final isSelected = poseItem == _currentPose;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentPose = poseItem;
                                  // Immediately show the new ghost at default center.
                                  if (_imageSize != null) {
                                    final imgW = _imageSize!.width;
                                    final imgH = _imageSize!.height;
                                    
                                    final isRotated = _cameraController?.description.sensorOrientation == 90 || 
                                                      _cameraController?.description.sensorOrientation == 270;
                                    final mlKitWidth = isRotated ? imgH : imgW;
                                    final mlKitHeight = isRotated ? imgW : imgH;
                                    
                                    final isFrontCamera = _cameraController?.description.lensDirection == CameraLensDirection.front;

                                    _targetSilhouetteResult = EngineBAdapter.processTargetPose(
                                      targetPose: poseItem.pose,
                                      anchorPxX: mlKitWidth * 0.5,
                                      anchorPxY: mlKitHeight * 0.50,
                                      torsoPx: mlKitHeight * 0.15,
                                      imageHeight: mlKitHeight,
                                      mirrorX: isFrontCamera,
                                    );
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.cyan.withValues(alpha: 0.3) : Colors.black54,
                                  border: Border.all(
                                    color: isSelected ? Colors.cyanAccent : Colors.white24,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: AssetImage(poseItem.imagePath),
                                    fit: BoxFit.cover,
                                    colorFilter: isSelected 
                                      ? null 
                                      : ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Controls Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Left: 9:6 Ratio Gallery/Pose Toggle Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showPoses = !_showPoses;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 90,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: AssetImage(_currentPose.imagePath),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Center: Shutter Button
                          GestureDetector(
                            onTap: () {
                              // TODO: Phase 4 Capture Logic
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Capture not yet implemented.")),
                              );
                            },
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: const Center(
                                child: Icon(Icons.camera_alt, color: Colors.white, size: 32),
                              ),
                            ),
                          ),
                          // Right: Camera Toggle Button
                          if (_cameras.length > 1)
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _toggleCamera,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.flip_camera_ios,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final String value;
  
  const _ScoreBadge({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// Tiny colored circle — used in the guidance legend (CYAN=Target, WHITE=You)
class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)],
      ),
    );
  }
}
