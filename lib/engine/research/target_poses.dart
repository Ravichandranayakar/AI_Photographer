import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/frozen_landmark.dart';

abstract final class TargetPoses {
  /// Extracted from test_3_utf8.jsonl (Frame 10) - Face/Head Landmarks Excised
  /// MATHEMATICALLY INVERTED: Flipped X and Y axes to fix the upside-down camera recording!
  /// Now the shoulders are at Y = -1.0 (above hips) and ankles are at Y = +1.6 (below hips).
  static final Map<PoseLandmarkType, FrozenLandmark> standingPose = {
    PoseLandmarkType.leftShoulder: FrozenLandmark(x: 0.0947, y: -1.0588, likelihood: 0.98),
    PoseLandmarkType.rightShoulder: FrozenLandmark(x: -0.5524, y: -0.8881, likelihood: 0.96),
    PoseLandmarkType.leftElbow: FrozenLandmark(x: 0.4612, y: -0.5972, likelihood: 0.82),
    PoseLandmarkType.rightElbow: FrozenLandmark(x: -0.3365, y: -0.5137, likelihood: 0.87),
    PoseLandmarkType.leftWrist: FrozenLandmark(x: 0.7383, y: -0.4940, likelihood: 0.80),
    PoseLandmarkType.rightWrist: FrozenLandmark(x: -0.2841, y: -0.1522, likelihood: 0.85),
    PoseLandmarkType.leftHip: FrozenLandmark(x: 0.1120, y: 0.0120, likelihood: 0.99),
    PoseLandmarkType.rightHip: FrozenLandmark(x: -0.2950, y: 0.0340, likelihood: 0.99),
    PoseLandmarkType.leftKnee: FrozenLandmark(x: 0.1850, y: 0.8420, likelihood: 0.95),
    PoseLandmarkType.rightKnee: FrozenLandmark(x: -0.3120, y: 0.8650, likelihood: 0.96),
    PoseLandmarkType.leftAnkle: FrozenLandmark(x: 0.2100, y: 1.6500, likelihood: 0.90),
    PoseLandmarkType.rightAnkle: FrozenLandmark(x: -0.3300, y: 1.6800, likelihood: 0.88),
    PoseLandmarkType.leftHeel: FrozenLandmark(x: 0.2200, y: 1.7000, likelihood: 0.85),
    PoseLandmarkType.rightHeel: FrozenLandmark(x: -0.3200, y: 1.7200, likelihood: 0.82),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(x: 0.2500, y: 1.7500, likelihood: 0.80),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(x: -0.3500, y: 1.7800, likelihood: 0.78),
  };
}
