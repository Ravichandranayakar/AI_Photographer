import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';

import 'engine/authoring/authored_pose.dart';
import 'engine/authoring/pose_geometry_validator.dart';
import 'engine/authoring/pose_leveler.dart';
import 'engine/authoring/pose_metadata_generator.dart';
import 'engine/authoring/pose_quality_gate.dart';
import 'engine/authoring/pose_serializer.dart';
import 'engine/normalizer/landmark_normalizer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pose Authoring Studio — Developer Entry Point
// ─────────────────────────────────────────────────────────────────────────────
//
// Run with: flutter run -t lib/main_authoring.dart
//
// This tool is NEVER shipped to users. Developer-only utility.
//
// Workflow:
//   1. Enter a Pose ID (e.g. weddingPose01).
//   2. Pick a pose image from your phone gallery.
//   3. All 7 pipeline stages run automatically.
//   4. Generated Dart code appears on screen.
//   5. Tap [Copy] → paste into lib/engine/research/target_poses.dart.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AuthoringStudioApp());
}

class AuthoringStudioApp extends StatelessWidget {
  const AuthoringStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pose Authoring Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF58A6FF),
          surface: Color(0xFF161B22),
        ),
        cardColor: const Color(0xFF161B22),
      ),
      home: const AuthoringStudioPage(),
    );
  }
}

// ── Pipeline stage status ────────────────────────────────────────────────────
enum _StageStatus { waiting, running, passed, warning, failed }

class _StageState {
  final String label;
  _StageStatus status;
  String detail;

  _StageState(this.label)
      : status = _StageStatus.waiting,
        detail = '';
}

class AuthoringStudioPage extends StatefulWidget {
  const AuthoringStudioPage({super.key});

  @override
  State<AuthoringStudioPage> createState() => _AuthoringStudioPageState();
}

class _AuthoringStudioPageState extends State<AuthoringStudioPage> {
  final _picker = ImagePicker();
  final _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.single),
  );

  bool _isProcessing = false;
  AuthoredPose? _result;
  String _generatedCode = '';
  String _poseId = 'myPose01';

  late final List<_StageState> _stages = [
    _StageState('Stage 1: ML Kit Extraction'),
    _StageState('Stage 2: Quality Gate'),
    _StageState('Stage 3: Auto-Leveling'),
    _StageState('Stage 4: Normalization'),
    _StageState('Stage 5: Geometry Validation'),
    _StageState('Stage 6: Metadata Generation'),
    _StageState('Stage 7: Serialization'),
  ];

  void _resetStages() {
    for (final s in _stages) {
      s.status = _StageStatus.waiting;
      s.detail = '';
    }
    _result = null;
    _generatedCode = '';
  }

  void _setStage(int index, _StageStatus status, String detail) {
    setState(() {
      _stages[index].status = status;
      _stages[index].detail = detail;
    });
  }

  Future<void> _pickAndProcess() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _isProcessing = true;
      _resetStages();
    });

    try {
      final inputImage = InputImage.fromFilePath(picked.path);

      // ── Stage 1: ML Kit Extraction ───────────────────────────────────────
      _setStage(0, _StageStatus.running, '');
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        _setStage(0, _StageStatus.failed, 'No pose detected in image.');
        setState(() => _isProcessing = false);
        return;
      }

      final rawLandmarks = poses.first.landmarks;
      _setStage(0, _StageStatus.passed,
          '${rawLandmarks.length} landmarks detected.');

      // ── Stage 2: Quality Gate ────────────────────────────────────────────
      _setStage(1, _StageStatus.running, '');
      final (:report, :coverage) = PoseQualityGate.run(rawLandmarks);

      if (report.rejected) {
        _setStage(1, _StageStatus.failed,
            report.rejectionReason ?? 'Unknown rejection reason.');
        setState(() => _isProcessing = false);
        return;
      }

      _setStage(
        1,
        report.warnings.isNotEmpty ? _StageStatus.warning : _StageStatus.passed,
        report.warnings.isEmpty
            ? 'All checks passed. Coverage: ${coverage.name}.'
            : '${report.warnings.length} warning(s). Coverage: ${coverage.name}.',
      );

      // ── Stage 3: Auto-Leveling ───────────────────────────────────────────
      _setStage(2, _StageStatus.running, '');
      final leveled = PoseLeveler.level(rawLandmarks);
      _setStage(
        2,
        _StageStatus.passed,
        'Corrected tilt: ${leveled.tiltDegrees.toStringAsFixed(1)}°',
      );

      // ── Stage 4: Normalization ───────────────────────────────────────────
      _setStage(3, _StageStatus.running, '');
      final normalized = LandmarkNormalizer.normalize(leveled.landmarks);

      if (normalized == null) {
        _setStage(3, _StageStatus.failed,
            'Normalization failed — torso too short. Is full body in frame?');
        setState(() => _isProcessing = false);
        return;
      }
      _setStage(3, _StageStatus.passed,
          '${normalized.length} landmarks normalized. Mid-hip = (0,0).');

      // ── Stage 5: Geometry Validation ─────────────────────────────────────
      _setStage(4, _StageStatus.running, '');
      final geoReport = PoseGeometryValidator.validate(normalized);

      if (!geoReport.passed) {
        _setStage(4, _StageStatus.failed,
            geoReport.warnings.firstOrNull ?? 'Geometry validation failed.');
        setState(() => _isProcessing = false);
        return;
      }

      _setStage(
        4,
        geoReport.warnings.isNotEmpty ? _StageStatus.warning : _StageStatus.passed,
        geoReport.warnings.isEmpty
            ? 'Anatomy checks passed.'
            : '${geoReport.warnings.length} warning(s).',
      );

      // ── Stage 6: Metadata Generation ─────────────────────────────────────
      _setStage(5, _StageStatus.running, '');

      // Compute raw torso pixel length for camera distance estimation.
      final ls = rawLandmarks[PoseLandmarkType.leftShoulder]!;
      final rs = rawLandmarks[PoseLandmarkType.rightShoulder]!;
      final lh = rawLandmarks[PoseLandmarkType.leftHip]!;
      final rh = rawLandmarks[PoseLandmarkType.rightHip]!;
      final midShX = (ls.x + rs.x) / 2;
      final midShY = (ls.y + rs.y) / 2;
      final midHpX = (lh.x + rh.x) / 2;
      final midHpY = (lh.y + rh.y) / 2;
      final dx = midShX - midHpX;
      final dy = midShY - midHpY;
      final rawTorsoLength = math.sqrt(dx * dx + dy * dy);

      // Infer image height from torso/ratio. At medium distance (~2m),
      // typical ratio is 0.18. This gives a reasonable camera distance estimate.
      final inferredImageHeight = rawTorsoLength / 0.18;

      final meta = PoseMetadataGenerator.generate(
        normalizedLandmarks: normalized,
        rawTorsoPixelLength: rawTorsoLength,
        imageHeight: inferredImageHeight,
      );

      _setStage(
        5,
        _StageStatus.passed,
        'Orientation: ${meta.orientation.name} | '
        'Camera: ${meta.recommendedCameraDistance.name} | '
        'Balanced: ${meta.balance.isBalanced}',
      );

      // ── Stage 7: Serialization ───────────────────────────────────────────
      _setStage(6, _StageStatus.running, '');

      final authored = AuthoredPose(
        id: _poseId,
        sourceImageName: picked.name,
        normalizedLandmarks: normalized,
        qualityReport: report,
        geometryReport: geoReport,
        correctedTiltDegrees: leveled.tiltDegrees,
        bodyCoverage: coverage,
        orientation: meta.orientation,
        recommendedCameraDistance: meta.recommendedCameraDistance,
        jointAngles: meta.jointAngles,
        balance: meta.balance,
        isSymmetric: meta.isSymmetric,
        isMirrored: meta.isMirrored,
        jointImportanceWeights: meta.jointImportanceWeights,
      );

      final code = PoseSerializer.serialize(authored);
      _setStage(6, _StageStatus.passed, 'Dart code generated. Ready to copy.');

      // Print to VS Code terminal so the developer can copy it directly from their PC screen
      debugPrint('\n\n================ GENERATED POSE CODE ================');
      debugPrint(code);
      debugPrint('=====================================================\n\n');

      setState(() {
        _result = authored;
        _generatedCode = code;
        _isProcessing = false;
      });
    } catch (e, stack) {
      debugPrint('Authoring error: $e\n$stack');
      setState(() {
        _isProcessing = false;
        _stages[0].detail = 'Unexpected error: $e';
        _stages[0].status = _StageStatus.failed;
      });
    }
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _generatedCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dart code copied! Paste into target_poses.dart'),
          backgroundColor: Color(0xFF238636),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pose Authoring Studio',
              style: TextStyle(
                color: Color(0xFF58A6FF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Developer Tool — Not for Production',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Pose ID Input ─────────────────────────────────────────────
            _SectionHeader('Pose ID'),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g. weddingPose01',
                hintStyle: TextStyle(color: Color(0xFF8B949E)),
                filled: true,
                fillColor: Color(0xFF161B22),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF30363D))),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF30363D))),
              ),
              onChanged: (v) => _poseId = v.isEmpty ? 'myPose01' : v,
            ),
            const SizedBox(height: 16),

            // ── Pick Image Button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238636),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isProcessing ? null : _pickAndProcess,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ))
                    : const Icon(Icons.photo_library),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Select Pose Image',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Pipeline Progress ─────────────────────────────────────────
            _SectionHeader('Pipeline Status'),
            ..._stages.map((s) => _StageRow(stage: s)),
            const SizedBox(height: 24),

            // ── Metadata + Generated Code ─────────────────────────────────
            if (_result != null) ...[
              _SectionHeader('Metadata Summary'),
              _MetadataCard(pose: _result!),
              const SizedBox(height: 24),
              _SectionHeader('Generated Dart Code'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  border: Border.all(color: const Color(0xFF30363D)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _generatedCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFFE6EDF3),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58A6FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy to Clipboard',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}

// ── UI Components ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );
}

class _StageRow extends StatelessWidget {
  final _StageState stage;
  const _StageRow({required this.stage});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (stage.status) {
      _StageStatus.waiting => (Icons.radio_button_unchecked, const Color(0xFF8B949E)),
      _StageStatus.running => (Icons.hourglass_top, const Color(0xFFD29922)),
      _StageStatus.passed  => (Icons.check_circle, const Color(0xFF3FB950)),
      _StageStatus.warning => (Icons.warning_amber, const Color(0xFFD29922)),
      _StageStatus.failed  => (Icons.cancel, const Color(0xFFF85149)),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stage.label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                if (stage.detail.isNotEmpty)
                  Text(stage.detail,
                      style: const TextStyle(
                          color: Color(0xFF8B949E), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  final AuthoredPose pose;
  const _MetadataCard({required this.pose});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          border: Border.all(color: const Color(0xFF30363D)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _Row('Orientation', pose.orientation.name),
            _Row('Coverage', pose.bodyCoverage.name),
            _Row('Camera Distance', pose.recommendedCameraDistance.name),
            _Row('Balanced', pose.balance.isBalanced.toString()),
            _Row('Symmetric', pose.isSymmetric.toString()),
            _Row('Mirrored', pose.isMirrored.toString()),
            _Row('Tilt Corrected',
                '${pose.correctedTiltDegrees.toStringAsFixed(1)}°'),
            _Row('L Elbow Angle',
                '${pose.jointAngles.leftElbow.toStringAsFixed(0)}°'),
            _Row('R Elbow Angle',
                '${pose.jointAngles.rightElbow.toStringAsFixed(0)}°'),
            _Row('L Knee Angle',
                '${pose.jointAngles.leftKnee.toStringAsFixed(0)}°'),
            _Row('R Knee Angle',
                '${pose.jointAngles.rightKnee.toStringAsFixed(0)}°'),
          ],
        ),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF8B949E), fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
