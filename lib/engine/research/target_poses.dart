import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/frozen_landmark.dart';

class PoseLibraryItem {
  final String id;
  final Map<PoseLandmarkType, FrozenLandmark> pose;
  final String
  imagePath; // Path to the asset image (you will provide these later)

  const PoseLibraryItem({
    required this.id,
    required this.pose,
    required this.imagePath,
  });
}

abstract final class TargetPoses {
  /// The master library of all authored target poses for Phase 3 testing.
  static final List<PoseLibraryItem> allPoses = [
    PoseLibraryItem(
      id: 'Side View',
      pose: sideView,
      imagePath: 'lib/engine/assets/image 1.jpeg',
    ),
    PoseLibraryItem(
      id: 'Front With Chair',
      pose: frontViewWithChair,
      imagePath: 'lib/engine/assets/image 2.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing Side Face',
      pose: frontStandingSideFace,
      imagePath: 'lib/engine/assets/image 3.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing Bending',
      pose: frontStandingBending,
      imagePath: 'lib/engine/assets/image 4.jpeg',
    ),
    PoseLibraryItem(
      id: 'Hand Behind Head',
      pose: frontStandingHandBehindHead,
      imagePath: 'lib/engine/assets/image 5.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing Bend Body',
      pose: standingBendBody,
      imagePath: 'lib/engine/assets/image 6.jpeg',
    ),
    PoseLibraryItem(
      id: 'Sitting',
      pose: sitting,
      imagePath: 'lib/engine/assets/image 7.jpeg',
    ),
    PoseLibraryItem(
      id: 'Hand In Mouth',
      pose: standingWithHandInMouth,
      imagePath: 'lib/engine/assets/image 8.jpeg',
    ),
    PoseLibraryItem(
      id: 'Half Frame',
      pose: frontPoseHalfFrame,
      imagePath: 'lib/engine/assets/image 9.jpeg',
    ),
    PoseLibraryItem(
      id: 'Sitting Side Face View',
      pose: sittingSideFaceView,
      imagePath: 'lib/engine/assets/image 10.jpeg',
    ),
    PoseLibraryItem(
      id: 'Straight Standing',
      pose: straightStanding,
      imagePath: 'lib/engine/assets/image 11.jpeg',
    ),
    PoseLibraryItem(
      id: 'Sitting On Chair',
      pose: sittingOnChair,
      imagePath: 'lib/engine/assets/image 12.jpeg',
    ),
    PoseLibraryItem(
      id: 'Sitting Hand On Head',
      pose: sittingHandOnHead,
      imagePath: 'lib/engine/assets/image 13.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing Right Hand On Color',
      pose: standingRightHandOnColor,
      imagePath: 'lib/engine/assets/image 14.jpeg',
    ),
    PoseLibraryItem(
      id: 'Sityung With Hand On Chik',
      pose: sityungWithHandOnChik,
      imagePath: 'lib/engine/assets/image 15.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing Hand On Poket',
      pose: standingHandOnPoket,
      imagePath: 'lib/engine/assets/image 16.jpeg',
    ),
    PoseLibraryItem(
      id: 'Fully Sitting',
      pose: fullySitting,
      imagePath: 'lib/engine/assets/image 17.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing Face Cross',
      pose: standingFaceCross,
      imagePath: 'lib/engine/assets/image 18.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing With Finger Zooming',
      pose: standingWithFingerZooming,
      imagePath: 'lib/engine/assets/image 19.jpeg',
    ),
    PoseLibraryItem(
      id: 'Sitting In Stair',
      pose: sittingInStair,
      imagePath: 'lib/engine/assets/image 20.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing With Wired Pose',
      pose: standingWithWiredPose,
      imagePath: 'lib/engine/assets/image 21.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing With Legs And Hand Up',
      pose: standingWithLegsAndHandUp,
      imagePath: 'lib/engine/assets/image 22.jpeg',
    ),
    PoseLibraryItem(
      id: 'Walking Freely Hand',
      pose: walkingFreelyHand,
      imagePath: 'lib/engine/assets/image 23.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing Silghtly Bend',
      pose: standingSilghtlyBend,
      imagePath: 'lib/engine/assets/image 24.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing Curve Body Bend',
      pose: standingCurveBodyBend,
      imagePath: 'lib/engine/assets/image 25.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing With Hands Back',
      pose: standingWithHandsBack,
      imagePath: 'lib/engine/assets/image 26.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing With Hand On Head With Shirt',
      pose: standingWithHandOnHeadWithShirt,
      imagePath: 'lib/engine/assets/image 27.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing Wit Hands Fall',
      pose: standingWitHandsFall,
      imagePath: 'lib/engine/assets/image 28.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing With One Hand Back And Another Hand Forword',
      pose: standingWithOneHandBackAndAnotherHandForword,
      imagePath: 'lib/engine/assets/image 29.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing With One Leg Cross And One Hand On Face',
      pose: standingWithOneLegCrossAndOneHandOnFace,
      imagePath: 'lib/engine/assets/image 30.jpeg',
    ),
    PoseLibraryItem(
      id: 'Walking With Hand Fallen',
      pose: walkingWithHandFallen,
      imagePath: 'lib/engine/assets/image 31.jpeg',
    ),
    PoseLibraryItem(
      id: 'Sitting With One Leg Up And On That Hand',
      pose: sittingWithOneLegUpAndOnThatHand,
      imagePath: 'lib/engine/assets/image 32.jpeg',
    ),
    PoseLibraryItem(
      id: 'Standing With One Hand On Four Head',
      pose: standingWithOneHandOnFourHead,
      imagePath: 'lib/engine/assets/image 33.jpeg',
    ),
  ];

  // Generated by Pose Authoring Pipeline — 2026-07-25
  // Source: 30869.jpg -1
  static final Map<PoseLandmarkType, FrozenLandmark> sideView = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.0128,
      y: -1.1910,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.0294,
      y: -1.2629,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: -0.0352,
      y: -1.2648,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: -0.0426,
      y: -1.2677,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.0415,
      y: -1.2646,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.0641,
      y: -1.2665,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.0798,
      y: -1.2714,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: -0.1393,
      y: -1.2700,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.2201,
      y: -1.2717,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: -0.0472,
      y: -1.1160,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.0702,
      y: -1.1193,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: -0.0976,
      y: -0.9566,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.4849,
      y: -0.9566,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.0703,
      y: -0.5066,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.4804,
      y: -0.5069,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.2985,
      y: -0.2068,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.0019,
      y: -0.3510,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.3689,
      y: -0.1354,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: 0.0555,
      y: -0.2912,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.3683,
      y: -0.1390,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: 0.0886,
      y: -0.3420,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.3249,
      y: -0.1516,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: 0.0914,
      y: -0.3512,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1035,
      y: -0.0507,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1035,
      y: 0.0507,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.7087,
      y: 0.2637,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: 0.3630,
      y: 0.5898,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.1627,
      y: 0.8504,
      likelihood: 0.98,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: 0.3733,
      y: 1.1552,
      likelihood: 0.98,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.0019,
      y: 0.9223,
      likelihood: 0.98,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: 0.2828,
      y: 1.2018,
      likelihood: 0.97,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.3494,
      y: 1.0915,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: 0.5875,
      y: 1.4378,
      likelihood: 0.94,
    ),
  };

  // Generated by Pose Authoring Pipeline — 2026-07-25
  // Source: 30867.jpg -2
  static final Map<PoseLandmarkType, FrozenLandmark> frontViewWithChair = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.0063,
      y: -1.4251,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.0419,
      y: -1.4679,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.0644,
      y: -1.4558,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.0847,
      y: -1.4438,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.0299,
      y: -1.5008,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.0550,
      y: -1.5094,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.0795,
      y: -1.5164,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.0733,
      y: -1.4037,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.1482,
      y: -1.4822,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.0027,
      y: -1.3329,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.0963,
      y: -1.3668,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.1781,
      y: -0.9886,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.4788,
      y: -0.9886,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.2580,
      y: -0.5140,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.6971,
      y: -0.4745,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.3177,
      y: -0.1988,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.9080,
      y: 0.0038,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.3559,
      y: -0.1091,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -1.0257,
      y: 0.1146,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.3230,
      y: -0.1203,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -1.0074,
      y: 0.1266,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.3111,
      y: -0.1423,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.9627,
      y: 0.0924,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1688,
      y: -0.0263,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1688,
      y: 0.0263,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: -0.0511,
      y: 0.7772,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.0579,
      y: 0.8145,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: -0.3701,
      y: 1.4882,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: 0.0499,
      y: 1.6519,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: -0.4691,
      y: 1.5980,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: 0.0636,
      y: 1.7834,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.2719,
      y: 1.7242,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: 0.1811,
      y: 1.9289,
      likelihood: 0.99,
    ),
  };

  // Generated by Pose Authoring Pipeline — 2026-07-25
  // Source: 30863.jpg -3
  static final Map<PoseLandmarkType, FrozenLandmark> frontStandingSideFace = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.3667,
      y: -1.4831,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.3401,
      y: -1.5426,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.3386,
      y: -1.5428,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.3319,
      y: -1.5435,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: 0.3128,
      y: -1.5444,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: 0.2981,
      y: -1.5436,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: 0.2585,
      y: -1.5446,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.2394,
      y: -1.5049,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: 0.1275,
      y: -1.5032,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.3424,
      y: -1.4008,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: 0.2676,
      y: -1.3983,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.3516,
      y: -0.9995,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.2884,
      y: -0.9995,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.5102,
      y: -0.3275,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.2812,
      y: -0.3513,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.1061,
      y: -0.3391,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: 0.3147,
      y: -0.3285,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: -0.0703,
      y: -0.3133,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: 0.4333,
      y: -0.2948,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: -0.1069,
      y: -0.3826,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: 0.4732,
      y: -0.3489,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: -0.0399,
      y: -0.3777,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: 0.4321,
      y: -0.3677,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1867,
      y: 0.0007,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1867,
      y: -0.0007,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.3337,
      y: 0.7741,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: 0.0999,
      y: 0.6435,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.3250,
      y: 1.4773,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: 0.1777,
      y: 1.4650,
      likelihood: 0.97,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.2701,
      y: 1.5821,
      likelihood: 0.96,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: 0.1199,
      y: 1.5403,
      likelihood: 0.96,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.4573,
      y: 1.6802,
      likelihood: 0.94,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: 0.3967,
      y: 1.7038,
      likelihood: 0.94,
    ),
  };

  // Generated by Pose Authoring Pipeline — 2026-07-25
  // Source: 30861.jpg -4
  static final Map<PoseLandmarkType, FrozenLandmark> frontStandingBending = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.1424,
      y: -1.2198,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.1295,
      y: -1.2861,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: -0.1188,
      y: -1.2832,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: -0.1088,
      y: -1.2810,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.1843,
      y: -1.3000,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.2102,
      y: -1.3066,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.2397,
      y: -1.3123,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: -0.1648,
      y: -1.2554,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.3366,
      y: -1.2844,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: -0.1544,
      y: -1.1382,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.2072,
      y: -1.1541,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: -0.2273,
      y: -0.9370,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.4711,
      y: -0.9370,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: -0.0552,
      y: -0.5226,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.4782,
      y: -0.4244,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.1646,
      y: -0.3963,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.0806,
      y: -0.1102,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.2352,
      y: -0.3426,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.0303,
      y: 0.0131,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.2235,
      y: -0.3989,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: 0.0375,
      y: -0.0458,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.2071,
      y: -0.4023,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: 0.0388,
      y: -0.0581,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.0748,
      y: -0.0156,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.0748,
      y: 0.0156,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.3080,
      y: 0.6120,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: 0.1390,
      y: 0.6981,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.2899,
      y: 1.3899,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.0063,
      y: 1.4865,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.2190,
      y: 1.5413,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.1106,
      y: 1.6344,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.5952,
      y: 1.5442,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: 0.2662,
      y: 1.7011,
      likelihood: 0.99,
    ),
  };

  // Generated by Pose Authoring Pipeline — 2026-07-25
  // Source: 30859.jpg -5
  static final Map<PoseLandmarkType, FrozenLandmark>
  frontStandingHandBehindHead = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.1958,
      y: -1.2901,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.1834,
      y: -1.3659,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: -0.1591,
      y: -1.3737,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: -0.1354,
      y: -1.3800,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.2459,
      y: -1.3367,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.2665,
      y: -1.3274,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.2854,
      y: -1.3189,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: -0.0873,
      y: -1.3554,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.2929,
      y: -1.2931,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: -0.1267,
      y: -1.2484,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.2082,
      y: -1.2226,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.2355,
      y: -0.9970,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.3893,
      y: -0.9970,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.4171,
      y: -0.5900,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.7958,
      y: -1.2105,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.3624,
      y: -0.2771,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.4936,
      y: -1.3491,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.3290,
      y: -0.1789,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.4061,
      y: -1.3702,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.2985,
      y: -0.2001,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.3585,
      y: -1.3617,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.2990,
      y: -0.2237,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.3988,
      y: -1.3183,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1771,
      y: -0.0202,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1771,
      y: 0.0202,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.2517,
      y: 0.6678,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.1558,
      y: 0.6876,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.2628,
      y: 1.1709,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.0602,
      y: 1.1507,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.2257,
      y: 1.2021,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.0079,
      y: 1.2047,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.2948,
      y: 1.4117,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.1541,
      y: 1.4360,
      likelihood: 0.99,
    ),
  };

  // Generated by Pose Authoring Pipeline — 2026-07-25
  // Source: 30848.jpg -6
  static final Map<PoseLandmarkType, FrozenLandmark> standingBendBody = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.0178,
      y: -1.3809,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.0151,
      y: -1.4473,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.0362,
      y: -1.4408,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.0545,
      y: -1.4349,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.0657,
      y: -1.4660,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.1040,
      y: -1.4710,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.1411,
      y: -1.4737,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.0421,
      y: -1.3950,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.2146,
      y: -1.4271,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.0032,
      y: -1.2957,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.1020,
      y: -1.3037,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.0925,
      y: -0.9829,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.4608,
      y: -0.9829,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.1014,
      y: -0.4765,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.5425,
      y: -0.4010,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.2070,
      y: -0.1818,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.2411,
      y: -0.0648,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.2409,
      y: -0.0577,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.1680,
      y: 0.0587,
      likelihood: 0.97,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.2370,
      y: -0.0819,
      likelihood: 0.98,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.0901,
      y: 0.0076,
      likelihood: 0.98,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.1938,
      y: -0.1392,
      likelihood: 0.98,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.1046,
      y: -0.0415,
      likelihood: 0.98,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1620,
      y: -0.0189,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1620,
      y: 0.0189,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.5031,
      y: 0.6274,
      likelihood: 0.89,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: 0.1274,
      y: 0.7144,
      likelihood: 0.92,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.3210,
      y: 1.1900,
      likelihood: 0.44,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: 0.0904,
      y: 1.2990,
      likelihood: 0.31,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.2328,
      y: 1.2291,
      likelihood: 0.37,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: 0.0066,
      y: 1.3400,
      likelihood: 0.23,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.5030,
      y: 1.5005,
      likelihood: 0.18,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: 0.2838,
      y: 1.6218,
      likelihood: 0.11,
    ),
  };

  // Generated by Pose Authoring Pipeline — 2026-07-25
  // Source: 30846.jpg -7
  static final Map<PoseLandmarkType, FrozenLandmark> sitting = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.1792,
      y: -1.3166,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.1429,
      y: -1.4069,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: -0.1102,
      y: -1.4144,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: -0.0800,
      y: -1.4209,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.2400,
      y: -1.3843,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.2700,
      y: -1.3780,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.2982,
      y: -1.3729,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: -0.0345,
      y: -1.4056,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.3212,
      y: -1.3502,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: -0.1003,
      y: -1.2554,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.2253,
      y: -1.2333,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.2918,
      y: -0.9951,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.4898,
      y: -0.9951,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.4341,
      y: -0.4826,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.7483,
      y: -0.6171,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.3170,
      y: -0.1850,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -1.2295,
      y: -0.6535,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.3087,
      y: -0.0544,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -1.3633,
      y: -0.5822,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.2196,
      y: -0.0928,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -1.3349,
      y: -0.5782,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.2170,
      y: -0.1256,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -1.2841,
      y: -0.5979,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.2372,
      y: -0.0439,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.2372,
      y: 0.0439,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.7995,
      y: 0.0491,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.2432,
      y: 0.2023,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.4526,
      y: 0.9895,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: 0.1166,
      y: 1.2104,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.3419,
      y: 1.0721,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: 0.1836,
      y: 1.2791,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.5337,
      y: 1.4214,
      likelihood: 0.98,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: 0.2681,
      y: 1.6252,
      likelihood: 0.97,
    ),
  };

  // Generated by Pose Authoring Pipeline — 2026-07-25
  // Source: 30844.jpg -8
  static final Map<PoseLandmarkType, FrozenLandmark> standingWithHandInMouth = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.0943,
      y: -1.3765,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.0501,
      y: -1.4567,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: -0.0162,
      y: -1.4620,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.0147,
      y: -1.4654,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.1283,
      y: -1.4428,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.1512,
      y: -1.4390,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.1720,
      y: -1.4348,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.0716,
      y: -1.4424,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.1788,
      y: -1.4117,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: -0.0240,
      y: -1.3074,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.1255,
      y: -1.2938,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.3421,
      y: -1.0000,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.3278,
      y: -1.0000,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.4787,
      y: -0.5124,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.7965,
      y: -0.9766,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.3655,
      y: -0.1554,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.4308,
      y: -1.2311,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.3454,
      y: -0.0141,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.3495,
      y: -1.2877,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.2835,
      y: -0.0405,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.3004,
      y: -1.2991,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.2759,
      y: -0.0934,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.3350,
      y: -1.2534,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1804,
      y: 0.0120,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1804,
      y: -0.0120,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.2133,
      y: 0.7550,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.3677,
      y: 0.7260,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.2452,
      y: 1.4580,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.5371,
      y: 1.4836,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.2087,
      y: 1.5527,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.5186,
      y: 1.6300,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.2292,
      y: 1.6909,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.8498,
      y: 1.5526,
      likelihood: 1.00,
    ),
  };

  // Generated by Pose Authoring Pipeline — 2026-07-25
  // Source: 30865.jpg -9
  static final Map<PoseLandmarkType, FrozenLandmark> frontPoseHalfFrame = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.0781,
      y: -1.4216,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.0790,
      y: -1.4764,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.0932,
      y: -1.4753,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.1057,
      y: -1.4738,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: 0.0169,
      y: -1.4748,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.0138,
      y: -1.4709,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.0460,
      y: -1.4646,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.0841,
      y: -1.4367,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.1104,
      y: -1.4218,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.0991,
      y: -1.3512,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: 0.0171,
      y: -1.3453,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.3248,
      y: -0.9999,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.3516,
      y: -0.9999,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.5648,
      y: -0.5185,
      likelihood: 0.92,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.4930,
      y: -0.5351,
      likelihood: 0.83,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.4768,
      y: -0.2814,
      likelihood: 0.71,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.3511,
      y: -0.5518,
      likelihood: 0.83,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.4839,
      y: -0.1257,
      likelihood: 0.61,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.3389,
      y: -0.5174,
      likelihood: 0.81,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.3659,
      y: -0.2122,
      likelihood: 0.68,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.2966,
      y: -0.5728,
      likelihood: 0.85,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.3770,
      y: -0.2923,
      likelihood: 0.69,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.2885,
      y: -0.5750,
      likelihood: 0.86,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.2095,
      y: -0.0039,
      likelihood: 0.39,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.2095,
      y: 0.0039,
      likelihood: 0.35,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.2645,
      y: 0.7976,
      likelihood: 0.01,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.1550,
      y: 0.7705,
      likelihood: 0.01,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.2611,
      y: 1.4106,
      likelihood: 0.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.1145,
      y: 1.4210,
      likelihood: 0.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.2553,
      y: 1.4965,
      likelihood: 0.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.1222,
      y: 1.5111,
      likelihood: 0.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.2511,
      y: 1.6376,
      likelihood: 0.00,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.0416,
      y: 1.6519,
      likelihood: 0.00,
    ),
  };

  // Generated by Pose Authoring Pipeline — 2026-07-26
  // Source: 31053.jpg
  // Quality: PASSED | Coverage: full | Orientation: unknown
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: -167.1° corrected
  // Joint Angles — LElbow:147° RElbow:11° LKnee:60° RKnee:104°
  // Balance: CoM=(0.17, -0.24) isBalanced=false
  // Warnings:
  //   ⚠ Left thigh / torso ratio () is outside expected human bounds [ – ]. May be a sitting pose or foreshortening from camera angle.

  static final Map<PoseLandmarkType, FrozenLandmark> sittingSideFaceView = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.4494,
      y: -1.3582,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.4715,
      y: -1.4413,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.4813,
      y: -1.4422,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.4925,
      y: -1.4437,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: 0.4134,
      y: -1.4482,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: 0.3671,
      y: -1.4550,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: 0.3389,
      y: -1.4589,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.4453,
      y: -1.4263,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: 0.2307,
      y: -1.4411,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.4601,
      y: -1.2847,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: 0.3511,
      y: -1.2857,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.6523,
      y: -0.9665,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.1387,
      y: -0.9665,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 1.0269,
      y: -0.4307,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.3615,
      y: -0.4626,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.6520,
      y: -0.5818,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.4480,
      y: -0.0732,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.5605,
      y: -0.5579,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.4853,
      y: 0.0698,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.5125,
      y: -0.6313,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.4086,
      y: 0.0719,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.5236,
      y: -0.6393,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.3881,
      y: 0.0103,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.2186,
      y: 0.0503,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.2186,
      y: -0.0503,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: -0.0897,
      y: 0.1261,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.9762,
      y: 0.0318,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: -0.4052,
      y: 1.1829,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.6852,
      y: 0.8071,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: -0.4255,
      y: 1.3134,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.5610,
      y: 0.9255,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.6335,
      y: 1.5353,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.8868,
      y: 1.2169,
      likelihood: 0.99,
    ),
  };

  // Joint Importance Weights for sitting side face view (for Engine 6):
  // {
  //   leftShoulder: 0.77,
  //   rightShoulder: 0.60,
  //   leftElbow: 0.69,
  //   rightElbow: 0.68,
  //   leftWrist: 0.66,
  //   rightWrist: 0.97,
  //   leftHip: 0.51,
  //   rightHip: 0.51,
  //   leftKnee: 0.79,
  //   rightKnee: 1.00,
  //   leftAnkle: 0.81,
  //   rightAnkle: 0.96,
  // }

  // Generated by Pose Authoring Pipeline

  // Source: 31055.jpg
  // Quality: PASSED | Coverage: half | Orientation: standing
  // Camera Distance: far | Symmetric: false | Mirrored: true
  // Auto-Level: 178.4° corrected
  // Joint Angles — LElbow:96° RElbow:106° LKnee:1° RKnee:0°
  // Balance: CoM=(0.14, -0.19) isBalanced=true
  // Warnings:
  //   ⚠ Hip confidence is low. Photo is likely cropped at the waist. Normalization will rely on ML Kit estimation.
  //   ⚠ Ankle joints not visible (confidence < ). Flagging as HALF_BODY pose. Engine 5 will compare only visible joints.

  static final Map<PoseLandmarkType, FrozenLandmark> straightStanding = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.0640,
      y: -1.4472,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.1012,
      y: -1.5191,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.1375,
      y: -1.5205,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.1706,
      y: -1.5216,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: 0.0078,
      y: -1.5117,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.0206,
      y: -1.5069,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.0469,
      y: -1.4997,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.2259,
      y: -1.4873,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.0685,
      y: -1.4461,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.1404,
      y: -1.3679,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: 0.0194,
      y: -1.3515,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.4632,
      y: -0.9944,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.2526,
      y: -0.9944,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.4837,
      y: -0.3910,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.3761,
      y: -0.4015,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.0000,
      y: -0.4273,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: 0.0385,
      y: -0.4336,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: -0.1375,
      y: -0.4267,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: 0.1665,
      y: -0.3794,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: -0.1481,
      y: -0.5034,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: 0.2015,
      y: -0.4981,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: -0.1233,
      y: -0.5088,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: 0.1777,
      y: -0.5021,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.2149,
      y: 0.0166,
      likelihood: 0.32,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.2149,
      y: -0.0166,
      likelihood: 0.38,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.1602,
      y: 0.7627,
      likelihood: 0.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.2841,
      y: 0.7063,
      likelihood: 0.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.0898,
      y: 1.4754,
      likelihood: 0.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.3507,
      y: 1.4308,
      likelihood: 0.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.0924,
      y: 1.5768,
      likelihood: 0.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.3630,
      y: 1.5405,
      likelihood: 0.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.0089,
      y: 1.6898,
      likelihood: 0.00,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.3372,
      y: 1.6564,
      likelihood: 0.00,
    ),
  };

  // Joint Importance Weights for straight standing  (for Engine 6):
  // {
  //   leftShoulder: 0.58,
  //   rightShoulder: 0.49,
  //   leftElbow: 0.66,
  //   rightElbow: 0.67,
  //   leftWrist: 0.98,
  //   rightWrist: 1.00,
  //   leftHip: 0.48,
  //   rightHip: 0.48,
  //   leftKnee: 0.38,
  //   rightKnee: 0.42,
  //   leftAnkle: 0.49,
  //   rightAnkle: 0.52,
  // }

  // Generated by Pose Authoring Pipeline

  // Source: 31057.jpg
  // Quality: PASSED | Coverage: full | Orientation: unknown
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: 177.3° corrected
  // Joint Angles — LElbow:6° RElbow:43° LKnee:25° RKnee:6°
  // Balance: CoM=(0.17, -0.25) isBalanced=true

  static final Map<PoseLandmarkType, FrozenLandmark> sittingOnChair = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.1466,
      y: -1.4549,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.1046,
      y: -1.5355,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: -0.0772,
      y: -1.5349,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: -0.0548,
      y: -1.5339,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.2066,
      y: -1.5262,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.2407,
      y: -1.5209,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.2752,
      y: -1.5151,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: -0.0329,
      y: -1.4903,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.3188,
      y: -1.4688,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: -0.0824,
      y: -1.3697,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.2112,
      y: -1.3630,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.2002,
      y: -0.9852,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.5433,
      y: -0.9852,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.3408,
      y: -0.4191,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.4664,
      y: -0.3853,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.4132,
      y: 0.1061,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.0489,
      y: -0.0426,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.4580,
      y: 0.2824,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: 0.0084,
      y: 0.1044,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.3590,
      y: 0.2441,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: 0.0878,
      y: 0.0854,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.3456,
      y: 0.1876,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: 0.0886,
      y: 0.0228,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.2254,
      y: -0.0244,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.2254,
      y: 0.0244,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.7267,
      y: 0.5186,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.1909,
      y: 0.1092,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 1.0116,
      y: 1.4199,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: 0.0176,
      y: 0.5043,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.9563,
      y: 1.5344,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: 0.0803,
      y: 0.5051,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 1.2455,
      y: 1.6863,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: 0.1419,
      y: 0.7194,
      likelihood: 1.00,
    ),
  };

  // Joint Importance Weights for sitting on chair  (for Engine 6):
  // {
  //   leftShoulder: 0.52,
  //   rightShoulder: 0.63,
  //   leftElbow: 0.64,
  //   rightElbow: 0.62,
  //   leftWrist: 0.94,
  //   rightWrist: 1.00,
  //   leftHip: 0.49,
  //   rightHip: 0.49,
  //   leftKnee: 0.63,
  //   rightKnee: 0.69,
  //   leftAnkle: 0.75,
  //   rightAnkle: 0.95,
  // }

  // Generated by Pose Authoring Pipelin
  // Source: 31060.jpg
  // Quality: PASSED | Coverage: full | Orientation: sitting
  // Camera Distance: far | Symmetric: true | Mirrored: false
  // Auto-Level: -170.7° corrected
  // Joint Angles — LElbow:18° RElbow:144° LKnee:153° RKnee:146°
  // Balance: CoM=(0.07, -0.36) isBalanced=false
  // Warnings:
  //   ⚠ Left thigh / torso ratio () is outside expected human bounds [ – ]. May be a sitting pose or foreshortening from camera angle.

  static final Map<PoseLandmarkType, FrozenLandmark> sittingHandOnHead = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.1584,
      y: -1.3088,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.1126,
      y: -1.4121,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: -0.0779,
      y: -1.4211,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: -0.0476,
      y: -1.4290,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.2133,
      y: -1.3929,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.2470,
      y: -1.3888,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.2774,
      y: -1.3848,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.0207,
      y: -1.4117,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.3040,
      y: -1.3603,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: -0.0786,
      y: -1.2344,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.1992,
      y: -1.2109,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.3888,
      y: -1.0000,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.3836,
      y: -1.0000,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.6054,
      y: -0.3438,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.7247,
      y: -0.7847,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.6086,
      y: 0.1457,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.4839,
      y: -1.3993,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.6201,
      y: 0.2941,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.4223,
      y: -1.5106,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.5467,
      y: 0.2981,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.4035,
      y: -1.5390,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.5031,
      y: 0.2117,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.4074,
      y: -1.4924,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.2202,
      y: 0.0233,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.2202,
      y: -0.0233,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.7786,
      y: 0.0634,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.6359,
      y: -0.5426,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: -0.1990,
      y: 0.4743,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.5485,
      y: 0.4623,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: -0.3317,
      y: 0.4931,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.5269,
      y: 0.5371,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.5276,
      y: 0.7560,
      likelihood: 0.98,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.5476,
      y: 0.7231,
      likelihood: 0.95,
    ),
  };

  // Joint Importance Weights for sitting hand on head  (for Engine 6):
  // {
  //   leftShoulder: 0.51,
  //   rightShoulder: 0.51,
  //   leftElbow: 0.61,
  //   rightElbow: 0.40,
  //   leftWrist: 0.88,
  //   rightWrist: 0.64,
  //   leftHip: 0.48,
  //   rightHip: 0.48,
  //   leftKnee: 0.78,
  //   rightKnee: 1.00,
  //   leftAnkle: 0.94,
  //   rightAnkle: 0.94,
  // }

  // Generated by Pose Authoring Pipeline

  // Source: 31062.jpg
  // Quality: PASSED | Coverage: full | Orientation: unknown
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: -176.4° corrected
  // Joint Angles — LElbow:162° RElbow:27° LKnee:0° RKnee:4°
  // Balance: CoM=(0.12, -0.24) isBalanced=true

  static final Map<PoseLandmarkType, FrozenLandmark> standingRightHandOnColor =
      {
        PoseLandmarkType.nose: FrozenLandmark(
          x: 0.0731,
          y: -1.3394,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftEyeInner: FrozenLandmark(
          x: 0.1136,
          y: -1.4145,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftEye: FrozenLandmark(
          x: 0.1380,
          y: -1.4125,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftEyeOuter: FrozenLandmark(
          x: 0.1581,
          y: -1.4102,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightEyeInner: FrozenLandmark(
          x: 0.0231,
          y: -1.4185,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightEye: FrozenLandmark(
          x: -0.0083,
          y: -1.4188,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightEyeOuter: FrozenLandmark(
          x: -0.0377,
          y: -1.4198,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftEar: FrozenLandmark(
          x: 0.1666,
          y: -1.3799,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightEar: FrozenLandmark(
          x: -0.0910,
          y: -1.3865,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftMouth: FrozenLandmark(
          x: 0.1152,
          y: -1.2660,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightMouth: FrozenLandmark(
          x: 0.0002,
          y: -1.2658,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftShoulder: FrozenLandmark(
          x: 0.3185,
          y: -0.9995,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightShoulder: FrozenLandmark(
          x: -0.3820,
          y: -0.9995,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftElbow: FrozenLandmark(
          x: 0.7135,
          y: -0.6938,
          likelihood: 0.99,
        ),
        PoseLandmarkType.rightElbow: FrozenLandmark(
          x: -0.5026,
          y: -0.4577,
          likelihood: 0.99,
        ),
        PoseLandmarkType.leftWrist: FrozenLandmark(
          x: 0.4487,
          y: -1.0767,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightWrist: FrozenLandmark(
          x: -0.3890,
          y: -0.0022,
          likelihood: 0.98,
        ),
        PoseLandmarkType.leftPinky: FrozenLandmark(
          x: 0.3554,
          y: -1.1494,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightPinky: FrozenLandmark(
          x: -0.3826,
          y: 0.1387,
          likelihood: 0.98,
        ),
        PoseLandmarkType.leftIndex: FrozenLandmark(
          x: 0.3206,
          y: -1.1971,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightIndex: FrozenLandmark(
          x: -0.3432,
          y: 0.1151,
          likelihood: 0.98,
        ),
        PoseLandmarkType.leftThumb: FrozenLandmark(
          x: 0.3164,
          y: -1.1590,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightThumb: FrozenLandmark(
          x: -0.3171,
          y: 0.0772,
          likelihood: 0.98,
        ),
        PoseLandmarkType.leftHip: FrozenLandmark(
          x: 0.1969,
          y: 0.0013,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightHip: FrozenLandmark(
          x: -0.1969,
          y: -0.0013,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftKnee: FrozenLandmark(
          x: 0.2098,
          y: 0.6663,
          likelihood: 0.99,
        ),
        PoseLandmarkType.rightKnee: FrozenLandmark(
          x: -0.2098,
          y: 0.6838,
          likelihood: 0.98,
        ),
        PoseLandmarkType.leftAnkle: FrozenLandmark(
          x: 0.2186,
          y: 1.1134,
          likelihood: 0.85,
        ),
        PoseLandmarkType.rightAnkle: FrozenLandmark(
          x: -0.2504,
          y: 1.1641,
          likelihood: 0.83,
        ),
        PoseLandmarkType.leftHeel: FrozenLandmark(
          x: 0.1589,
          y: 1.1852,
          likelihood: 0.82,
        ),
        PoseLandmarkType.rightHeel: FrozenLandmark(
          x: -0.1965,
          y: 1.2394,
          likelihood: 0.78,
        ),
        PoseLandmarkType.leftFootIndex: FrozenLandmark(
          x: 0.2143,
          y: 1.3815,
          likelihood: 0.67,
        ),
        PoseLandmarkType.rightFootIndex: FrozenLandmark(
          x: -0.2195,
          y: 1.4719,
          likelihood: 0.59,
        ),
      };

  // Joint Importance Weights for standing right hand on color  (for Engine 6):
  // {
  //   leftShoulder: 0.47,
  //   rightShoulder: 0.52,
  //   leftElbow: 0.48,
  //   rightElbow: 0.63,
  //   leftWrist: 0.67,
  //   rightWrist: 1.00,
  //   leftHip: 0.46,
  //   rightHip: 0.46,
  //   leftKnee: 0.43,
  //   rightKnee: 0.42,
  //   leftAnkle: 0.69,
  //   rightAnkle: 0.67,
  // }

  // Generated by Pose Authoring Pipeline
  // Source: 31064.jpg
  // Quality: PASSED | Coverage: full | Orientation: sitting
  // Camera Distance: far | Symmetric: true | Mirrored: false
  // Auto-Level: -168.6° corrected
  // Joint Angles — LElbow:62° RElbow:170° LKnee:8° RKnee:101°
  // Balance: CoM=(-0.05, -0.28) isBalanced=false
  // Warnings:
  //   ⚠ Left upper arm / torso ratio () is outside expected human bounds [ – ]. May be due to arm pointing toward/away from camera (foreshortening).
  //   ⚠ Left thigh / torso ratio () is outside expected human bounds [ – ]. May be a sitting pose or foreshortening from camera angle.

  static final Map<PoseLandmarkType, FrozenLandmark> sityungWithHandOnChik = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.3734,
      y: -1.1618,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.3374,
      y: -1.2785,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: -0.2978,
      y: -1.2875,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: -0.2642,
      y: -1.2971,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.4125,
      y: -1.2483,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.4296,
      y: -1.2477,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.4460,
      y: -1.2478,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: -0.1405,
      y: -1.3163,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.3864,
      y: -1.2647,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: -0.2656,
      y: -1.1013,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.3594,
      y: -1.0719,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.3163,
      y: -1.0000,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.3316,
      y: -1.0000,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.2760,
      y: -0.2030,
      likelihood: 0.94,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.6123,
      y: -0.4742,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: -0.3825,
      y: 0.1094,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.4807,
      y: -0.8821,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: -0.5049,
      y: 0.2340,
      likelihood: 0.95,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.4827,
      y: -0.9916,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: -0.5376,
      y: 0.1669,
      likelihood: 0.96,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.4488,
      y: -1.0511,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: -0.5297,
      y: 0.1471,
      likelihood: 0.96,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.4391,
      y: -1.0238,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1962,
      y: 0.0737,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1962,
      y: -0.0737,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: -0.0559,
      y: 0.4024,
      likelihood: 0.94,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.9566,
      y: -0.2215,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: -0.3088,
      y: 0.8526,
      likelihood: 0.75,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.9603,
      y: 0.5030,
      likelihood: 0.94,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: -0.2766,
      y: 0.8923,
      likelihood: 0.72,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.8455,
      y: 0.6470,
      likelihood: 0.92,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.6511,
      y: 1.1080,
      likelihood: 0.59,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -1.3863,
      y: 0.7275,
      likelihood: 0.79,
    ),
  };

  // Joint Importance Weights for sityung with hand on chik  (for Engine 6):
  // {
  //   leftShoulder: 0.46,
  //   rightShoulder: 0.47,
  //   leftElbow: 0.64,
  //   rightElbow: 0.50,
  //   leftWrist: 1.00,
  //   rightWrist: 0.54,
  //   leftHip: 0.49,
  //   rightHip: 0.49,
  //   leftKnee: 0.51,
  //   rightKnee: 0.82,
  //   leftAnkle: 0.70,
  //   rightAnkle: 0.87,
  // }

  // Generated by Pose Authoring Pipeline

  // Source: 31066.jpg
  // Quality: PASSED | Coverage: full | Orientation: standing
  // Camera Distance: far | Symmetric: true | Mirrored: false
  // Auto-Level: 176.9° corrected
  // Joint Angles — LElbow:20° RElbow:96° LKnee:2° RKnee:30°
  // Balance: CoM=(0.00, -0.18) isBalanced=false

  static final Map<PoseLandmarkType, FrozenLandmark> standingHandOnPoket = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.0575,
      y: -1.3671,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.0103,
      y: -1.4302,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.0164,
      y: -1.4295,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.0426,
      y: -1.4274,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.0847,
      y: -1.4262,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.1090,
      y: -1.4235,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.1303,
      y: -1.4207,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.0906,
      y: -1.3795,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.1451,
      y: -1.3810,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.0025,
      y: -1.2996,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.1015,
      y: -1.2918,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.2859,
      y: -1.0000,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.2887,
      y: -1.0000,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.3710,
      y: -0.5396,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.5338,
      y: -0.5384,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.3435,
      y: -0.3732,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.1464,
      y: -0.3788,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.3179,
      y: -0.2872,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.0631,
      y: -0.2922,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.3151,
      y: -0.3275,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.0074,
      y: -0.3634,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.2853,
      y: -0.3440,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.0427,
      y: -0.3975,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1584,
      y: 0.0118,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1584,
      y: -0.0118,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: -0.0633,
      y: 0.8503,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.3851,
      y: 0.7467,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: -0.2408,
      y: 1.6292,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.9514,
      y: 1.2804,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: -0.3218,
      y: 1.7319,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -1.0170,
      y: 1.3201,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.2462,
      y: 1.8001,
      likelihood: 0.98,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -1.0428,
      y: 1.4763,
      likelihood: 0.98,
    ),
  };

  // Joint Importance Weights for standing  hand on poket  (for Engine 6):
  // {
  //   leftShoulder: 0.46,
  //   rightShoulder: 0.46,
  //   leftElbow: 0.65,
  //   rightElbow: 0.60,
  //   leftWrist: 0.90,
  //   rightWrist: 1.00,
  //   leftHip: 0.47,
  //   rightHip: 0.47,
  //   leftKnee: 0.45,
  //   rightKnee: 0.46,
  //   leftAnkle: 0.58,
  //   rightAnkle: 0.87,
  // }

  // Generated by Pose Authoring Pipeline

  // Source: 31068.jpg
  // Quality: PASSED | Coverage: full | Orientation: unknown
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: 160.0° corrected
  // Joint Angles — LElbow:56° RElbow:19° LKnee:82° RKnee:125°
  // Balance: CoM=(0.20, -0.23) isBalanced=true
  // Warnings:
  //   ⚠ Left thigh / torso ratio () is outside expected human bounds [ – ]. May be a sitting pose or foreshortening from camera angle.

  static final Map<PoseLandmarkType, FrozenLandmark> fullySitting = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.2222,
      y: -1.3651,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.2975,
      y: -1.4525,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.3264,
      y: -1.4480,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.3600,
      y: -1.4432,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: 0.1828,
      y: -1.4724,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: 0.1401,
      y: -1.4803,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: 0.1052,
      y: -1.4872,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.4066,
      y: -1.4096,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: 0.0273,
      y: -1.4702,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.2757,
      y: -1.2612,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: 0.1180,
      y: -1.2815,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.5634,
      y: -0.9944,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.3529,
      y: -0.9944,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.6836,
      y: -0.3353,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.4572,
      y: -0.2284,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.2705,
      y: 0.0736,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.3152,
      y: 0.4694,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.1829,
      y: 0.2548,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.3545,
      y: 0.6794,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.0998,
      y: 0.1822,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.2406,
      y: 0.6966,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.0957,
      y: 0.1439,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.2176,
      y: 0.5892,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.2662,
      y: 0.0073,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.2662,
      y: -0.0073,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.7386,
      y: 0.2531,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.9136,
      y: 0.3386,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.3705,
      y: 1.3027,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.4677,
      y: 0.5656,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.2204,
      y: 1.4266,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.3092,
      y: 0.6057,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.3692,
      y: 1.6657,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.5689,
      y: 0.8442,
      likelihood: 1.00,
    ),
  };

  // Joint Importance Weights for fully sitting  (for Engine 6):
  // {
  //   leftShoulder: 0.62,
  //   rightShoulder: 0.48,
  //   leftElbow: 0.58,
  //   rightElbow: 0.64,
  //   leftWrist: 0.87,
  //   rightWrist: 1.00,
  //   leftHip: 0.50,
  //   rightHip: 0.50,
  //   leftKnee: 0.66,
  //   rightKnee: 0.69,
  //   leftAnkle: 0.52,
  //   rightAnkle: 0.83,
  // }

  // Generated by Pose Authoring Pipeline
  // Source: 31070.jpg
  // Quality: PASSED | Coverage: full | Orientation: unknown
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: -175.7° corrected
  // Joint Angles — LElbow:33° RElbow:3° LKnee:0° RKnee:35°
  // Balance: CoM=(0.10, -0.20) isBalanced=false

  static final Map<PoseLandmarkType, FrozenLandmark> standingFaceCross = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.0169,
      y: -1.3562,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.0486,
      y: -1.4403,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.0687,
      y: -1.4429,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.0884,
      y: -1.4462,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.0420,
      y: -1.4324,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.0765,
      y: -1.4302,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.1086,
      y: -1.4278,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.1147,
      y: -1.4224,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.1565,
      y: -1.3935,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.0637,
      y: -1.2896,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.0461,
      y: -1.2814,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.3681,
      y: -0.9992,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.2885,
      y: -0.9992,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.6163,
      y: -0.4878,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.3223,
      y: -0.5174,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.5571,
      y: 0.0209,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.3766,
      y: -0.0923,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.5785,
      y: 0.1534,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.4341,
      y: 0.0115,
      likelihood: 0.98,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.5066,
      y: 0.1413,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.3995,
      y: 0.0129,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.4794,
      y: 0.1045,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.3773,
      y: -0.0377,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1855,
      y: 0.0181,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1855,
      y: -0.0181,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.0408,
      y: 0.8601,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.4593,
      y: 0.8128,
      likelihood: 0.98,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: -0.0144,
      y: 1.1846,
      likelihood: 0.70,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.3420,
      y: 1.1985,
      likelihood: 0.77,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: -0.0371,
      y: 1.2295,
      likelihood: 0.66,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.2832,
      y: 1.2419,
      likelihood: 0.70,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.0642,
      y: 1.5560,
      likelihood: 0.42,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.4099,
      y: 1.5701,
      likelihood: 0.40,
    ),
  };

  // Joint Importance Weights for standing face cross  (for Engine 6):
  // {
  //   leftShoulder: 0.51,
  //   rightShoulder: 0.46,
  //   leftElbow: 0.61,
  //   rightElbow: 0.67,
  //   leftWrist: 1.00,
  //   rightWrist: 1.00,
  //   leftHip: 0.47,
  //   rightHip: 0.47,
  //   leftKnee: 0.39,
  //   rightKnee: 0.48,
  //   leftAnkle: 0.69,
  //   rightAnkle: 0.68,
  // }

  // Generated by Pose Authoring Pipeline
  // Source: 31072.jpg
  // Quality: PASSED | Coverage: full | Orientation: sitting
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: -157.0° corrected
  // Joint Angles — LElbow:22° RElbow:71° LKnee:122° RKnee:107°
  // Balance: CoM=(-0.12, -0.48) isBalanced=false
  // Warnings:
  //   ⚠ Left upper arm / torso ratio () is outside expected human bounds [ – ]. May be due to arm pointing toward/away from camera (foreshortening).
  //   ⚠ Left thigh / torso ratio () is outside expected human bounds [ – ]. May be a sitting pose or foreshortening from camera angle.

  static final Map<PoseLandmarkType, FrozenLandmark> standingWithFingerZooming =
      {
        PoseLandmarkType.nose: FrozenLandmark(
          x: -0.2256,
          y: -1.3106,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftEyeInner: FrozenLandmark(
          x: -0.2033,
          y: -1.3688,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftEye: FrozenLandmark(
          x: -0.1824,
          y: -1.3654,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftEyeOuter: FrozenLandmark(
          x: -0.1623,
          y: -1.3629,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightEyeInner: FrozenLandmark(
          x: -0.2738,
          y: -1.3758,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightEye: FrozenLandmark(
          x: -0.3027,
          y: -1.3760,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightEyeOuter: FrozenLandmark(
          x: -0.3324,
          y: -1.3749,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftEar: FrozenLandmark(
          x: -0.1670,
          y: -1.3103,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightEar: FrozenLandmark(
          x: -0.4186,
          y: -1.3155,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftMouth: FrozenLandmark(
          x: -0.1911,
          y: -1.2245,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightMouth: FrozenLandmark(
          x: -0.2759,
          y: -1.2384,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftShoulder: FrozenLandmark(
          x: -0.0641,
          y: -0.9431,
          likelihood: 0.99,
        ),
        PoseLandmarkType.rightShoulder: FrozenLandmark(
          x: -0.6012,
          y: -0.9431,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftElbow: FrozenLandmark(
          x: 0.1284,
          y: -0.6193,
          likelihood: 0.94,
        ),
        PoseLandmarkType.rightElbow: FrozenLandmark(
          x: -1.0828,
          y: -0.7125,
          likelihood: 0.99,
        ),
        PoseLandmarkType.leftWrist: FrozenLandmark(
          x: 0.3497,
          y: -0.4486,
          likelihood: 0.94,
        ),
        PoseLandmarkType.rightWrist: FrozenLandmark(
          x: -1.0660,
          y: -0.5733,
          likelihood: 0.98,
        ),
        PoseLandmarkType.leftPinky: FrozenLandmark(
          x: 0.4519,
          y: -0.3875,
          likelihood: 0.92,
        ),
        PoseLandmarkType.rightPinky: FrozenLandmark(
          x: -1.1021,
          y: -0.4871,
          likelihood: 0.96,
        ),
        PoseLandmarkType.leftIndex: FrozenLandmark(
          x: 0.4436,
          y: -0.3897,
          likelihood: 0.93,
        ),
        PoseLandmarkType.rightIndex: FrozenLandmark(
          x: -1.0114,
          y: -0.5162,
          likelihood: 0.97,
        ),
        PoseLandmarkType.leftThumb: FrozenLandmark(
          x: 0.3984,
          y: -0.3935,
          likelihood: 0.94,
        ),
        PoseLandmarkType.rightThumb: FrozenLandmark(
          x: -1.0472,
          y: -0.4978,
          likelihood: 0.98,
        ),
        PoseLandmarkType.leftHip: FrozenLandmark(
          x: 0.1621,
          y: -0.0183,
          likelihood: 0.98,
        ),
        PoseLandmarkType.rightHip: FrozenLandmark(
          x: -0.1621,
          y: 0.0183,
          likelihood: 0.99,
        ),
        PoseLandmarkType.leftKnee: FrozenLandmark(
          x: 0.1964,
          y: -0.6263,
          likelihood: 0.91,
        ),
        PoseLandmarkType.rightKnee: FrozenLandmark(
          x: -0.3336,
          y: -0.6439,
          likelihood: 0.97,
        ),
        PoseLandmarkType.leftAnkle: FrozenLandmark(
          x: -0.2837,
          y: -0.3629,
          likelihood: 0.89,
        ),
        PoseLandmarkType.rightAnkle: FrozenLandmark(
          x: -0.7087,
          y: -0.4100,
          likelihood: 0.91,
        ),
        PoseLandmarkType.leftHeel: FrozenLandmark(
          x: -0.3317,
          y: -0.3360,
          likelihood: 0.90,
        ),
        PoseLandmarkType.rightHeel: FrozenLandmark(
          x: -0.7285,
          y: -0.3602,
          likelihood: 0.90,
        ),
        PoseLandmarkType.leftFootIndex: FrozenLandmark(
          x: -0.4311,
          y: -0.2607,
          likelihood: 0.86,
        ),
        PoseLandmarkType.rightFootIndex: FrozenLandmark(
          x: -0.9138,
          y: -0.3717,
          likelihood: 0.81,
        ),
      };

  // Joint Importance Weights for standing with finger zooming  (for Engine 6):
  // {
  //   leftShoulder: 0.62,
  //   rightShoulder: 0.59,
  //   leftElbow: 0.51,
  //   rightElbow: 0.45,
  //   leftWrist: 0.59,
  //   rightWrist: 0.43,
  //   leftHip: 0.46,
  //   rightHip: 0.46,
  //   leftKnee: 0.77,
  //   rightKnee: 0.78,
  //   leftAnkle: 0.98,
  //   rightAnkle: 1.00,
  // }

  // Generated by Pose Authoring Pipeline
  // Source: 31075.jpg
  // Quality: PASSED | Coverage: full | Orientation: sitting
  // Camera Distance: far | Symmetric: true | Mirrored: false
  // Auto-Level: -166.0° corrected
  // Joint Angles — LElbow:47° RElbow:176° LKnee:72° RKnee:136°
  // Balance: CoM=(-0.02, -0.31) isBalanced=false
  // Warnings:
  //   ⚠ Left thigh / torso ratio () is outside expected human bounds [ – ]. May be a sitting pose or foreshortening from camera angle.

  static final Map<PoseLandmarkType, FrozenLandmark> sittingInStair = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.3287,
      y: -1.3831,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.3097,
      y: -1.4831,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: -0.2769,
      y: -1.5004,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: -0.2454,
      y: -1.5134,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.3832,
      y: -1.4384,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.4007,
      y: -1.4258,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.4174,
      y: -1.4145,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: -0.1429,
      y: -1.4989,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.3882,
      y: -1.3870,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: -0.2183,
      y: -1.3368,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.3154,
      y: -1.2846,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.2822,
      y: -0.9998,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.3226,
      y: -0.9998,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.0430,
      y: -0.3305,
      likelihood: 0.96,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.5580,
      y: -0.6082,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: -0.3094,
      y: -0.1767,
      likelihood: 0.96,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.3926,
      y: -0.8481,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: -0.3580,
      y: -0.1092,
      likelihood: 0.95,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.3702,
      y: -0.8480,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: -0.3734,
      y: -0.1414,
      likelihood: 0.95,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.3420,
      y: -0.9057,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: -0.3579,
      y: -0.1552,
      likelihood: 0.96,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.3323,
      y: -0.8864,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1849,
      y: 0.0620,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1849,
      y: -0.0620,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: -0.0093,
      y: 0.0760,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.6813,
      y: -0.5215,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: -0.2462,
      y: 1.0594,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.6344,
      y: 0.3292,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: -0.2559,
      y: 1.1951,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.5401,
      y: 0.4876,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.5949,
      y: 1.3769,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.9991,
      y: 0.6317,
      likelihood: 1.00,
    ),
  };

  // Joint Importance Weights for sitting in stair  (for Engine 6):
  // {
  //   leftShoulder: 0.46,
  //   rightShoulder: 0.46,
  //   leftElbow: 0.70,
  //   rightElbow: 0.48,
  //   leftWrist: 1.00,
  //   rightWrist: 0.61,
  //   leftHip: 0.49,
  //   rightHip: 0.49,
  //   leftKnee: 0.66,
  //   rightKnee: 0.95,
  //   leftAnkle: 0.67,
  //   rightAnkle: 0.96,
  // }

  // Generated b Pose Authoring Pipeline
  // Source: 31077.jpg
  // Quality: PASSED | Coverage: full | Orientation: sitting
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: 179.3° corrected
  // Joint Angles — LElbow:98° RElbow:24° LKnee:93° RKnee:66°
  // Balance: CoM=(-0.00, -0.34) isBalanced=false

  static final Map<PoseLandmarkType, FrozenLandmark> standingWithWiredPose = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.1110,
      y: -1.0860,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.1285,
      y: -1.1449,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.1342,
      y: -1.1468,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.1393,
      y: -1.1491,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: 0.0980,
      y: -1.1468,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: 0.0978,
      y: -1.1451,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: 0.0958,
      y: -1.1440,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.2106,
      y: -1.1496,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: 0.1229,
      y: -1.1311,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.1838,
      y: -1.0443,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: 0.1287,
      y: -1.0259,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.6099,
      y: -0.9385,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: 0.0808,
      y: -0.9385,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 1.1394,
      y: -0.8151,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.5167,
      y: -0.8771,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 1.1813,
      y: -1.2673,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -1.0614,
      y: -1.0577,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 1.2012,
      y: -1.4147,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -1.2123,
      y: -1.1141,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 1.1871,
      y: -1.4388,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -1.2241,
      y: -1.1321,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 1.1644,
      y: -1.3649,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -1.1546,
      y: -1.1001,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.0776,
      y: 0.0682,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.0776,
      y: -0.0682,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: -0.7190,
      y: -0.1245,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.9496,
      y: -0.2239,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: -0.8119,
      y: 0.3915,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -1.4856,
      y: 0.5681,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: -0.8569,
      y: 0.5050,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -1.4611,
      y: 0.7386,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -1.1889,
      y: 0.8173,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -1.8542,
      y: 0.7788,
      likelihood: 0.99,
    ),
  };

  // Joint Importance Weights for standing with wired pose (for Engine 6):
  // {
  //   leftShoulder: 0.63,
  //   rightShoulder: 0.68,
  //   leftElbow: 0.49,
  //   rightElbow: 0.39,
  //   leftWrist: 0.41,
  //   rightWrist: 0.33,
  //   leftHip: 0.52,
  //   rightHip: 0.52,
  //   leftKnee: 0.83,
  //   rightKnee: 0.83,
  //   leftAnkle: 0.97,
  //   rightAnkle: 1.00,
  // }

  // Generated by Pose Authoring Pipeline
  // Source: 31079.jpg
  // Quality: PASSED | Coverage: full | Orientation: sitting
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: -161.9° corrected
  // Joint Angles — LElbow:9° RElbow:21° LKnee:13° RKnee:28°
  // Balance: CoM=(0.04, -0.25) isBalanced=false
  // Warnings:
  //   ⚠ Left upper arm / torso ratio () is outside expected human bounds [ – ]. May be due to arm pointing toward/away from camera (foreshortening).

  static final Map<PoseLandmarkType, FrozenLandmark> standingWithLegsAndHandUp =
      {
        PoseLandmarkType.nose: FrozenLandmark(
          x: 0.2875,
          y: -1.2582,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftEyeInner: FrozenLandmark(
          x: 0.3275,
          y: -1.3184,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftEye: FrozenLandmark(
          x: 0.3498,
          y: -1.3213,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftEyeOuter: FrozenLandmark(
          x: 0.3852,
          y: -1.3173,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightEyeInner: FrozenLandmark(
          x: 0.2654,
          y: -1.3112,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightEye: FrozenLandmark(
          x: 0.2509,
          y: -1.3072,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightEyeOuter: FrozenLandmark(
          x: 0.2333,
          y: -1.2939,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftEar: FrozenLandmark(
          x: 0.4507,
          y: -1.2844,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightEar: FrozenLandmark(
          x: 0.2395,
          y: -1.2592,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftMouth: FrozenLandmark(
          x: 0.3588,
          y: -1.1759,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightMouth: FrozenLandmark(
          x: 0.2710,
          y: -1.1702,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftShoulder: FrozenLandmark(
          x: 0.7011,
          y: -0.9313,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightShoulder: FrozenLandmark(
          x: 0.0276,
          y: -0.9313,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftElbow: FrozenLandmark(
          x: 0.7031,
          y: -0.5819,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightElbow: FrozenLandmark(
          x: -0.5234,
          y: -0.8303,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftWrist: FrozenLandmark(
          x: 0.7893,
          y: -0.0695,
          likelihood: 0.99,
        ),
        PoseLandmarkType.rightWrist: FrozenLandmark(
          x: -1.0575,
          y: -0.9289,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftPinky: FrozenLandmark(
          x: 0.8110,
          y: 0.0848,
          likelihood: 0.99,
        ),
        PoseLandmarkType.rightPinky: FrozenLandmark(
          x: -1.2145,
          y: -0.9104,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftIndex: FrozenLandmark(
          x: 0.7738,
          y: 0.0889,
          likelihood: 0.99,
        ),
        PoseLandmarkType.rightIndex: FrozenLandmark(
          x: -1.2194,
          y: -0.9187,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftThumb: FrozenLandmark(
          x: 0.7772,
          y: 0.0288,
          likelihood: 0.99,
        ),
        PoseLandmarkType.rightThumb: FrozenLandmark(
          x: -1.1639,
          y: -0.9249,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftHip: FrozenLandmark(
          x: 0.1445,
          y: 0.1093,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightHip: FrozenLandmark(
          x: -0.1445,
          y: -0.1093,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftKnee: FrozenLandmark(
          x: -0.3413,
          y: 0.7875,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightKnee: FrozenLandmark(
          x: -0.7522,
          y: -0.0652,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftAnkle: FrozenLandmark(
          x: -0.8854,
          y: 1.2705,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightAnkle: FrozenLandmark(
          x: -1.3584,
          y: 0.3181,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftHeel: FrozenLandmark(
          x: -0.9958,
          y: 1.2955,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightHeel: FrozenLandmark(
          x: -1.4189,
          y: 0.4010,
          likelihood: 1.00,
        ),
        PoseLandmarkType.leftFootIndex: FrozenLandmark(
          x: -1.0477,
          y: 1.5171,
          likelihood: 1.00,
        ),
        PoseLandmarkType.rightFootIndex: FrozenLandmark(
          x: -1.6522,
          y: 0.4387,
          likelihood: 1.00,
        ),
      };

  // Joint Importance Weights for standing with legs and hand up (for Engine 6):
  // {
  //   leftShoulder: 0.68,
  //   rightShoulder: 0.64,
  //   leftElbow: 0.45,
  //   rightElbow: 0.39,
  //   leftWrist: 0.66,
  //   rightWrist: 0.33,
  //   leftHip: 0.51,
  //   rightHip: 0.51,
  //   leftKnee: 0.50,
  //   rightKnee: 0.71,
  //   leftAnkle: 0.74,
  //   rightAnkle: 1.00,
  // }

  // Generated by Pose Authoring Pipeline

  // Source: 31081.jpg
  // Quality: PASSED | Coverage: full | Orientation: unknown
  // Camera Distance: far | Symmetric: true | Mirrored: false
  // Auto-Level: -177.7° corrected
  // Joint Angles — LElbow:9° RElbow:5° LKnee:1° RKnee:6°
  // Balance: CoM=(0.11, -0.23) isBalanced=true
  // Warnings:
  //   ⚠ Left thigh / torso ratio () is outside expected human bounds [ – ]. May be a sitting pose or foreshortening from camera angle.

  static final Map<PoseLandmarkType, FrozenLandmark> walkingFreelyHand = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.1615,
      y: -1.1650,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.1752,
      y: -1.2547,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.1849,
      y: -1.2601,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.1976,
      y: -1.2663,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: 0.1192,
      y: -1.2499,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: 0.0777,
      y: -1.2535,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: 0.0479,
      y: -1.2614,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.1589,
      y: -1.2832,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.0537,
      y: -1.2961,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.1667,
      y: -1.1171,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: 0.0744,
      y: -1.1184,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.3442,
      y: -1.0000,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.3478,
      y: -1.0000,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.5223,
      y: -0.5491,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.5814,
      y: -0.5403,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.7924,
      y: -0.0940,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.8453,
      y: -0.1147,
      likelihood: 0.96,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.8619,
      y: 0.0157,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.9117,
      y: -0.0093,
      likelihood: 0.92,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.8323,
      y: 0.0292,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.8829,
      y: 0.0007,
      likelihood: 0.92,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.7888,
      y: -0.0170,
      likelihood: 0.98,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.8442,
      y: -0.0263,
      likelihood: 0.94,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1790,
      y: 0.0079,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1790,
      y: -0.0079,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.1286,
      y: 0.5676,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.2748,
      y: 0.5355,
      likelihood: 0.96,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.1002,
      y: 0.9445,
      likelihood: 0.68,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.3061,
      y: 0.9483,
      likelihood: 0.68,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.0751,
      y: 0.9785,
      likelihood: 0.66,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.3007,
      y: 0.9833,
      likelihood: 0.65,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.1047,
      y: 1.1995,
      likelihood: 0.48,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.3204,
      y: 1.2113,
      likelihood: 0.44,
    ),
  };

  // Joint Importance Weights for walking freely hand  (for Engine 6):
  // {
  //   leftShoulder: 0.50,
  //   rightShoulder: 0.50,
  //   leftElbow: 0.65,
  //   rightElbow: 0.65,
  //   leftWrist: 1.00,
  //   rightWrist: 0.97,
  //   leftHip: 0.46,
  //   rightHip: 0.46,
  //   leftKnee: 0.55,
  //   rightKnee: 0.58,
  //   leftAnkle: 0.93,
  //   rightAnkle: 0.93,
  // }

  // Generated by Pose Authoring Pipeline

  // Source: 31085.jpg
  // Quality: PASSED | Coverage: full | Orientation: unknown
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: -166.6° corrected
  // Joint Angles — LElbow:17° RElbow:9° LKnee:1° RKnee:7°
  // Balance: CoM=(0.16, -0.20) isBalanced=false

  static final Map<PoseLandmarkType, FrozenLandmark> standingSilghtlyBend = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.0489,
      y: -1.3362,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.0426,
      y: -1.4033,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: -0.0182,
      y: -1.4067,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.0001,
      y: -1.4084,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.1011,
      y: -1.4016,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.1330,
      y: -1.3954,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.1574,
      y: -1.3917,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: -0.0253,
      y: -1.3681,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.2276,
      y: -1.3526,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: -0.0137,
      y: -1.2713,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.1053,
      y: -1.2600,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: -0.0138,
      y: -0.9739,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.4403,
      y: -0.9739,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.0977,
      y: -0.4537,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.4296,
      y: -0.3133,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.2966,
      y: -0.1010,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.3445,
      y: 0.1982,
      likelihood: 0.97,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.3643,
      y: 0.0018,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.3661,
      y: 0.3486,
      likelihood: 0.95,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.3655,
      y: -0.0031,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.3461,
      y: 0.2972,
      likelihood: 0.95,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.3203,
      y: -0.0325,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.3026,
      y: 0.2727,
      likelihood: 0.96,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1223,
      y: -0.0362,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1223,
      y: 0.0362,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.6299,
      y: 0.5270,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: 0.3707,
      y: 0.7044,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 1.1084,
      y: 1.0317,
      likelihood: 0.98,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: 0.7043,
      y: 1.3009,
      likelihood: 0.97,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 1.1566,
      y: 1.1611,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: 0.7090,
      y: 1.4338,
      likelihood: 0.95,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 1.4644,
      y: 1.1467,
      likelihood: 0.92,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: 1.0170,
      y: 1.4460,
      likelihood: 0.88,
    ),
  };

  // Joint Importance Weights for standing silghtly bend  (for Engine 6):
  // {
  //   leftShoulder: 0.68,
  //   rightShoulder: 0.56,
  //   leftElbow: 0.70,
  //   rightElbow: 0.66,
  //   leftWrist: 0.90,
  //   rightWrist: 1.00,
  //   leftHip: 0.50,
  //   rightHip: 0.50,
  //   leftKnee: 0.59,
  //   rightKnee: 0.59,
  //   leftAnkle: 0.90,
  //   rightAnkle: 0.80,
  // }

  // Generated by Pose Authoring Pipeline
  // Source: 31089.jpg
  // Quality: PASSED | Coverage: full | Orientation: standing
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: 179.0° corrected
  // Joint Angles — LElbow:24° RElbow:6° LKnee:16° RKnee:20°
  // Balance: CoM=(0.00, -0.16) isBalanced=true

  static final Map<PoseLandmarkType, FrozenLandmark> standingCurveBodyBend = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.3407,
      y: -1.2096,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.3116,
      y: -1.3259,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: -0.2807,
      y: -1.3345,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: -0.2422,
      y: -1.3435,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.3814,
      y: -1.3084,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.4012,
      y: -1.3048,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.4176,
      y: -1.3025,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: -0.1461,
      y: -1.3323,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.3867,
      y: -1.2990,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: -0.2492,
      y: -1.1539,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.3497,
      y: -1.1486,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.1947,
      y: -0.9934,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.4234,
      y: -0.9934,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.3637,
      y: -0.4003,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.3589,
      y: -0.5020,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.2858,
      y: 0.1174,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.3489,
      y: -0.1188,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.3066,
      y: 0.2753,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.3799,
      y: 0.0412,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.2389,
      y: 0.2738,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.3441,
      y: 0.0252,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.2160,
      y: 0.2162,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.3354,
      y: -0.0423,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1680,
      y: 0.0104,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1680,
      y: -0.0104,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.0354,
      y: 0.6800,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.4675,
      y: 0.4940,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.1046,
      y: 1.4578,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.6076,
      y: 1.2037,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.1265,
      y: 1.5771,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.5546,
      y: 1.2998,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.1410,
      y: 1.8393,
      likelihood: 0.95,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.9409,
      y: 1.3925,
      likelihood: 0.98,
    ),
  };

  // Joint Importance Weights for standing curve body bend  (for Engine 6):
  // {
  //   leftShoulder: 0.53,
  //   rightShoulder: 0.54,
  //   leftElbow: 0.65,
  //   rightElbow: 0.61,
  //   leftWrist: 1.00,
  //   rightWrist: 0.89,
  //   leftHip: 0.46,
  //   rightHip: 0.46,
  //   leftKnee: 0.43,
  //   rightKnee: 0.55,
  //   leftAnkle: 0.48,
  //   rightAnkle: 0.67,
  // }

  // Generated by Pose Authoring Pipeline
  // Source: 31091.jpg
  // Quality: PASSED | Coverage: full | Orientation: standing
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: 171.6° corrected
  // Joint Angles — LElbow:6° RElbow:29° LKnee:11° RKnee:5°
  // Balance: CoM=(0.06, -0.19) isBalanced=true

  static final Map<PoseLandmarkType, FrozenLandmark> standingWithHandsBack = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.0119,
      y: -1.4693,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.0271,
      y: -1.5340,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.0504,
      y: -1.5318,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.0699,
      y: -1.5273,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.0609,
      y: -1.5376,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.0936,
      y: -1.5360,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.1260,
      y: -1.5333,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.0774,
      y: -1.4898,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.1781,
      y: -1.4890,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.0305,
      y: -1.3831,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.0801,
      y: -1.3857,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.2591,
      y: -0.9983,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.3768,
      y: -0.9983,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.2652,
      y: -0.4770,
      likelihood: 0.95,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.6016,
      y: -0.4917,
      likelihood: 0.98,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.3149,
      y: -0.0247,
      likelihood: 0.88,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.5587,
      y: -0.0010,
      likelihood: 0.91,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.3333,
      y: 0.1332,
      likelihood: 0.83,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.5794,
      y: 0.1333,
      likelihood: 0.84,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.3309,
      y: 0.1341,
      likelihood: 0.85,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.5207,
      y: 0.1346,
      likelihood: 0.85,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.2825,
      y: 0.0785,
      likelihood: 0.87,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.5063,
      y: 0.0840,
      likelihood: 0.88,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1720,
      y: -0.0031,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1720,
      y: 0.0031,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.1201,
      y: 0.7997,
      likelihood: 0.89,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.1941,
      y: 0.7524,
      likelihood: 0.92,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: -0.0316,
      y: 1.3841,
      likelihood: 0.58,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.2592,
      y: 1.3055,
      likelihood: 0.52,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: -0.0932,
      y: 1.4329,
      likelihood: 0.50,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.3096,
      y: 1.4011,
      likelihood: 0.44,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.0013,
      y: 1.6232,
      likelihood: 0.32,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.1789,
      y: 1.6142,
      likelihood: 0.26,
    ),
  };

  // Joint Importance Weights for standing with hands back (for Engine 6):
  // {
  //   leftShoulder: 0.48,
  //   rightShoulder: 0.51,
  //   leftElbow: 0.68,
  //   rightElbow: 0.59,
  //   leftWrist: 1.00,
  //   rightWrist: 0.94,
  //   leftHip: 0.46,
  //   rightHip: 0.46,
  //   leftKnee: 0.37,
  //   rightKnee: 0.38,
  //   leftAnkle: 0.56,
  //   rightAnkle: 0.58,
  // }

  // Generated by Pose Authoring Pipeline
  // Source: 31093.jpg
  // Quality: PASSED | Coverage: full | Orientation: standing
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: 177.5° corrected
  // Joint Angles — LElbow:177° RElbow:130° LKnee:5° RKnee:1°
  // Balance: CoM=(0.01, -0.23) isBalanced=true

  static final Map<PoseLandmarkType, FrozenLandmark>
  standingWithHandOnHeadWithShirt = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.2122,
      y: -1.3208,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: -0.1891,
      y: -1.3805,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: -0.1705,
      y: -1.3778,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: -0.1524,
      y: -1.3752,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.2518,
      y: -1.3810,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.2788,
      y: -1.3783,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.3087,
      y: -1.3741,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: -0.1359,
      y: -1.3413,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.3467,
      y: -1.3311,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: -0.1787,
      y: -1.2529,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.2557,
      y: -1.2539,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.0458,
      y: -0.9727,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.5099,
      y: -0.9727,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.4483,
      y: -0.6403,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.8410,
      y: -1.2131,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.1840,
      y: -0.8346,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.4723,
      y: -1.3046,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.1020,
      y: -0.8794,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.3735,
      y: -1.3518,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.0809,
      y: -0.8991,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.3549,
      y: -1.3215,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.0913,
      y: -0.8863,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.3736,
      y: -1.3005,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1701,
      y: -0.0309,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1701,
      y: 0.0309,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.2552,
      y: 0.7123,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.2454,
      y: 0.8111,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.2755,
      y: 1.4004,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.2977,
      y: 1.4336,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.2043,
      y: 1.4869,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.2734,
      y: 1.4991,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.3934,
      y: 1.6031,
      likelihood: 0.98,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.3103,
      y: 1.6880,
      likelihood: 0.98,
    ),
  };

  // Joint Importance Weights for standing with hand on head with shirt  (for Engine 6):
  // {
  //   leftShoulder: 0.74,
  //   rightShoulder: 0.69,
  //   leftElbow: 0.63,
  //   rightElbow: 0.49,
  //   leftWrist: 1.00,
  //   rightWrist: 0.82,
  //   leftHip: 0.49,
  //   rightHip: 0.49,
  //   leftKnee: 0.45,
  //   rightKnee: 0.38,
  //   leftAnkle: 0.61,
  //   rightAnkle: 0.59,
  // }

  // Generated by Pose Authoring Pipeline

  // Source: 31095.jpg
  // Quality: PASSED | Coverage: half | Orientation: standing
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: -175.6° corrected
  // Joint Angles — LElbow:4° RElbow:10° LKnee:10° RKnee:13°
  // Balance: CoM=(0.15, -0.18) isBalanced=true
  // Warnings:
  //   ⚠ Ankle joints not visible (confidence < ). Flagging as HALF_BODY pose. Engine 5 will compare only visible joints.

  static final Map<PoseLandmarkType, FrozenLandmark> standingWitHandsFall = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.1181,
      y: -1.2631,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.1534,
      y: -1.3548,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.1686,
      y: -1.3604,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.1991,
      y: -1.3689,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: 0.0623,
      y: -1.3510,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: 0.0398,
      y: -1.3840,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.0046,
      y: -1.3925,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.1913,
      y: -1.3730,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.0649,
      y: -1.4029,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.1469,
      y: -1.2094,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: 0.0501,
      y: -1.2092,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.4327,
      y: -0.9994,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.3652,
      y: -0.9994,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.6631,
      y: -0.5199,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.6417,
      y: -0.5442,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.8916,
      y: -0.1248,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.9012,
      y: -0.2510,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.9846,
      y: 0.0021,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -1.0177,
      y: -0.1306,
      likelihood: 0.98,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.9609,
      y: -0.0033,
      likelihood: 0.97,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.9795,
      y: -0.1629,
      likelihood: 0.98,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.9060,
      y: -0.0502,
      likelihood: 0.98,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.9338,
      y: -0.1869,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.2067,
      y: 0.0162,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.2067,
      y: -0.0162,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.2285,
      y: 0.8073,
      likelihood: 0.40,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.2716,
      y: 0.6993,
      likelihood: 0.57,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.1548,
      y: 1.2780,
      likelihood: 0.06,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.1887,
      y: 1.3378,
      likelihood: 0.08,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.1276,
      y: 1.3187,
      likelihood: 0.07,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.1963,
      y: 1.4002,
      likelihood: 0.07,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.1513,
      y: 1.5708,
      likelihood: 0.04,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.1466,
      y: 1.6096,
      likelihood: 0.04,
    ),
  };

  // Joint Importance Weights for standing wit hands fall   (for Engine 6):
  // {
  //   leftShoulder: 0.60,
  //   rightShoulder: 0.53,
  //   leftElbow: 0.67,
  //   rightElbow: 0.66,
  //   leftWrist: 1.00,
  //   rightWrist: 0.90,
  //   leftHip: 0.49,
  //   rightHip: 0.49,
  //   leftKnee: 0.38,
  //   rightKnee: 0.47,
  //   leftAnkle: 0.71,
  //   rightAnkle: 0.66,
  // }

  // Generated by Pose Authoring Pipeline

  // Source: 31097.jpg
  // Quality: PASSED | Coverage: full | Orientation: standing
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: -177.3° corrected
  // Joint Angles — LElbow:176° RElbow:6° LKnee:16° RKnee:4°
  // Balance: CoM=(0.06, -0.17) isBalanced=false

  static final Map<PoseLandmarkType, FrozenLandmark>
  standingWithOneHandBackAndAnotherHandForword = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: -0.0163,
      y: -1.3588,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.0339,
      y: -1.4316,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.0670,
      y: -1.4309,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.1007,
      y: -1.4290,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: -0.0453,
      y: -1.4310,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: -0.0676,
      y: -1.4310,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: -0.0849,
      y: -1.4312,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.1677,
      y: -1.4029,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.0864,
      y: -1.4005,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.0558,
      y: -1.2770,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: -0.0474,
      y: -1.2791,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.4254,
      y: -0.9967,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.2641,
      y: -0.9967,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.4914,
      y: -0.5035,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.5845,
      y: -0.5638,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.4871,
      y: -0.5670,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.9048,
      y: -0.2128,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.4912,
      y: -0.5629,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -1.0082,
      y: -0.1321,
      likelihood: 0.98,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.4678,
      y: -0.6676,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -1.0070,
      y: -0.1249,
      likelihood: 0.98,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.4684,
      y: -0.6603,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.9538,
      y: -0.1485,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1878,
      y: 0.0270,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1878,
      y: -0.0270,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.0478,
      y: 0.8305,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.3367,
      y: 0.7712,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: -0.2695,
      y: 1.4720,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.5189,
      y: 1.4837,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: -0.3401,
      y: 1.5461,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.5579,
      y: 1.5428,
      likelihood: 0.99,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.2187,
      y: 1.7279,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.5376,
      y: 1.7786,
      likelihood: 0.98,
    ),
  };

  // Joint Importance Weights for standing with one hand back and another hand forword  (for Engine 6):
  // {
  //   leftShoulder: 0.61,
  //   rightShoulder: 0.50,
  //   leftElbow: 0.76,
  //   rightElbow: 0.69,
  //   leftWrist: 0.95,
  //   rightWrist: 1.00,
  //   leftHip: 0.49,
  //   rightHip: 0.49,
  //   leftKnee: 0.43,
  //   rightKnee: 0.48,
  //   leftAnkle: 0.78,
  //   rightAnkle: 0.70,
  // }

  // Generated by Pose Authoring Pipeline
  // Source: 31098.jpg
  // Quality: PASSED | Coverage: full | Orientation: kneeling
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: 173.9° corrected
  // Joint Angles — LElbow:0° RElbow:154° LKnee:17° RKnee:101°
  // Balance: CoM=(0.04, -0.27) isBalanced=false

  static final Map<PoseLandmarkType, FrozenLandmark>
  standingWithOneLegCrossAndOneHandOnFace = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.2647,
      y: -1.3326,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.2734,
      y: -1.3924,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.2945,
      y: -1.3957,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.3154,
      y: -1.3990,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: 0.2075,
      y: -1.3784,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: 0.1766,
      y: -1.3665,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: 0.1468,
      y: -1.3550,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.3247,
      y: -1.3665,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: 0.0890,
      y: -1.2984,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.3149,
      y: -1.2668,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: 0.2208,
      y: -1.2422,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.4629,
      y: -0.9781,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.0469,
      y: -0.9781,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.3366,
      y: -0.5435,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.3049,
      y: -0.9008,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.2221,
      y: -0.1446,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.0589,
      y: -1.1310,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.1906,
      y: -0.0859,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: 0.0163,
      y: -1.1918,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.1901,
      y: -0.0884,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: 0.0372,
      y: -1.2402,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.1960,
      y: -0.0888,
      likelihood: 0.99,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: 0.0212,
      y: -1.1881,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1195,
      y: 0.0252,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1195,
      y: -0.0252,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: -0.1644,
      y: 0.8003,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.1802,
      y: 0.6148,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: -0.6457,
      y: 1.4414,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.8782,
      y: 0.4149,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: -0.7961,
      y: 1.5064,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -1.0011,
      y: 0.3548,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.7056,
      y: 1.6769,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -1.0756,
      y: 0.5830,
      likelihood: 1.00,
    ),
  };

  // Joint Importance Weights for standing with one leg cross and one hand on face  (for Engine 6):
  // {
  //   leftShoulder: 0.56,
  //   rightShoulder: 0.62,
  //   leftElbow: 0.56,
  //   rightElbow: 0.48,
  //   leftWrist: 0.85,
  //   rightWrist: 0.77,
  //   leftHip: 0.49,
  //   rightHip: 0.49,
  //   leftKnee: 0.46,
  //   rightKnee: 0.43,
  //   leftAnkle: 0.71,
  //   rightAnkle: 1.00,
  // }

  // Generated by Pose Authoring Pipeline
  // Source: 31101.jpg
  // Quality: PASSED | Coverage: full | Orientation: standing
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: -177.3° corrected
  // Joint Angles — LElbow:16° RElbow:40° LKnee:11° RKnee:25°
  // Balance: CoM=(0.18, -0.20) isBalanced=true

  static final Map<PoseLandmarkType, FrozenLandmark> walkingWithHandFallen = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.1944,
      y: -1.2462,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.2114,
      y: -1.3290,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.2273,
      y: -1.3333,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.2433,
      y: -1.3382,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: 0.1438,
      y: -1.3258,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: 0.1094,
      y: -1.3267,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: 0.0752,
      y: -1.3271,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.2346,
      y: -1.3307,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: 0.0018,
      y: -1.3141,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.2144,
      y: -1.1819,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: 0.1331,
      y: -1.1837,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.4147,
      y: -0.9950,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.2148,
      y: -0.9950,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.7726,
      y: -0.6786,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.5358,
      y: -0.6825,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 1.2036,
      y: -0.4721,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.9136,
      y: -0.6544,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 1.3410,
      y: -0.4481,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -1.0562,
      y: -0.6670,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 1.3447,
      y: -0.4529,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -1.0563,
      y: -0.6986,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 1.2851,
      y: -0.4533,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.9898,
      y: -0.6872,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1475,
      y: 0.0117,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1475,
      y: -0.0117,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: -0.0286,
      y: 0.6961,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.0606,
      y: 0.6743,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: -0.0762,
      y: 1.4328,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: 0.2775,
      y: 1.2184,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: -0.0517,
      y: 1.5586,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: 0.4192,
      y: 1.2706,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: -0.2928,
      y: 1.6740,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: 0.2002,
      y: 1.3973,
      likelihood: 1.00,
    ),
  };

  // Joint Importance Weights for walking with hand fallen   (for Engine 6):
  // {
  //   leftShoulder: 0.61,
  //   rightShoulder: 0.57,
  //   leftElbow: 0.61,
  //   rightElbow: 0.64,
  //   leftWrist: 0.81,
  //   rightWrist: 0.67,
  //   leftHip: 0.50,
  //   rightHip: 0.50,
  //   leftKnee: 0.58,
  //   rightKnee: 0.54,
  //   leftAnkle: 0.72,
  //   rightAnkle: 1.00,
  // }

  // Generated by Pose Authoring Pipeline
  // Source: 31103.jpg
  // Quality: PASSED | Coverage: full | Orientation: unknown
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: 154.4° corrected
  // Joint Angles — LElbow:17° RElbow:9° LKnee:96° RKnee:46°
  // Balance: CoM=(0.33, -0.29) isBalanced=false

  static final Map<PoseLandmarkType, FrozenLandmark>
  sittingWithOneLegUpAndOnThatHand = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.4184,
      y: -1.3243,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.4042,
      y: -1.4111,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.4037,
      y: -1.4132,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.4040,
      y: -1.4150,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: 0.3682,
      y: -1.4125,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: 0.3472,
      y: -1.4132,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: 0.3215,
      y: -1.4142,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.2958,
      y: -1.3832,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: 0.1765,
      y: -1.3915,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.3943,
      y: -1.2451,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: 0.3353,
      y: -1.2494,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.3667,
      y: -0.9968,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.2057,
      y: -0.9968,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.7076,
      y: -0.7486,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.4515,
      y: -0.4498,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.9308,
      y: -0.6705,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.6005,
      y: 0.1000,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 1.0761,
      y: -0.6103,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.6880,
      y: 0.2241,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 1.0134,
      y: -0.6227,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.5974,
      y: 0.2465,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.9379,
      y: -0.6514,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.5693,
      y: 0.1968,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.1741,
      y: -0.0691,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.1741,
      y: 0.0691,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.9208,
      y: -0.5727,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: 0.4411,
      y: 0.5047,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 1.2754,
      y: 0.0933,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: 0.6004,
      y: 1.5762,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 1.2587,
      y: 0.2547,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: 0.5187,
      y: 1.7300,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 1.6656,
      y: 0.2639,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: 0.9477,
      y: 1.9713,
      likelihood: 0.99,
    ),
  };

  // Joint Importance Weights for sitting with one leg up and on that hand  (for Engine 6):
  // {
  //   leftShoulder: 0.48,
  //   rightShoulder: 0.50,
  //   leftElbow: 0.39,
  //   rightElbow: 0.51,
  //   leftWrist: 0.43,
  //   rightWrist: 0.72,
  //   leftHip: 0.49,
  //   rightHip: 0.49,
  //   leftKnee: 0.87,
  //   rightKnee: 0.55,
  //   leftAnkle: 1.00,
  //   rightAnkle: 0.58,
  // }

  // Generated by Pose Authoring Pipeline

  // Source: 31107.jpg
  // Quality: PASSED | Coverage: full | Orientation: unknown
  // Camera Distance: far | Symmetric: false | Mirrored: false
  // Auto-Level: -179.8° corrected
  // Joint Angles — LElbow:119° RElbow:9° LKnee:10° RKnee:8°
  // Balance: CoM=(0.16, -0.26) isBalanced=true
  // Warnings:
  //   ⚠ Left upper arm / torso ratio () is outside expected human bounds [ – ]. May be due to arm pointing toward/away from camera (foreshortening).
  //   ⚠ Left thigh / torso ratio () is outside expected human bounds [ – ]. May be a sitting pose or foreshortening from camera angle.

  static final Map<PoseLandmarkType, FrozenLandmark>
  standingWithOneHandOnFourHead = {
    PoseLandmarkType.nose: FrozenLandmark(
      x: 0.1230,
      y: -1.3406,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeInner: FrozenLandmark(
      x: 0.1827,
      y: -1.3911,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEye: FrozenLandmark(
      x: 0.2240,
      y: -1.3862,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEyeOuter: FrozenLandmark(
      x: 0.2487,
      y: -1.3827,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeInner: FrozenLandmark(
      x: 0.0917,
      y: -1.4008,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEye: FrozenLandmark(
      x: 0.0546,
      y: -1.4015,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEyeOuter: FrozenLandmark(
      x: 0.0319,
      y: -1.4021,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftEar: FrozenLandmark(
      x: 0.2953,
      y: -1.3465,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightEar: FrozenLandmark(
      x: -0.0217,
      y: -1.3760,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftMouth: FrozenLandmark(
      x: 0.1883,
      y: -1.2438,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightMouth: FrozenLandmark(
      x: 0.0548,
      y: -1.2649,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftShoulder: FrozenLandmark(
      x: 0.4358,
      y: -0.9959,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightShoulder: FrozenLandmark(
      x: -0.2554,
      y: -0.9959,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftElbow: FrozenLandmark(
      x: 0.7969,
      y: -1.1517,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightElbow: FrozenLandmark(
      x: -0.3740,
      y: -0.4793,
      likelihood: 0.97,
    ),
    PoseLandmarkType.leftWrist: FrozenLandmark(
      x: 0.3704,
      y: -1.4792,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightWrist: FrozenLandmark(
      x: -0.4053,
      y: -0.0425,
      likelihood: 0.94,
    ),
    PoseLandmarkType.leftPinky: FrozenLandmark(
      x: 0.2463,
      y: -1.5459,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightPinky: FrozenLandmark(
      x: -0.3847,
      y: 0.1862,
      likelihood: 0.90,
    ),
    PoseLandmarkType.leftIndex: FrozenLandmark(
      x: 0.2455,
      y: -1.5720,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightIndex: FrozenLandmark(
      x: -0.3149,
      y: 0.1312,
      likelihood: 0.91,
    ),
    PoseLandmarkType.leftThumb: FrozenLandmark(
      x: 0.2566,
      y: -1.5312,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightThumb: FrozenLandmark(
      x: -0.3187,
      y: 0.0516,
      likelihood: 0.93,
    ),
    PoseLandmarkType.leftHip: FrozenLandmark(
      x: 0.2039,
      y: 0.0203,
      likelihood: 1.00,
    ),
    PoseLandmarkType.rightHip: FrozenLandmark(
      x: -0.2039,
      y: -0.0203,
      likelihood: 1.00,
    ),
    PoseLandmarkType.leftKnee: FrozenLandmark(
      x: 0.2905,
      y: 0.6559,
      likelihood: 0.94,
    ),
    PoseLandmarkType.rightKnee: FrozenLandmark(
      x: -0.2134,
      y: 0.5663,
      likelihood: 0.91,
    ),
    PoseLandmarkType.leftAnkle: FrozenLandmark(
      x: 0.2705,
      y: 1.1344,
      likelihood: 0.60,
    ),
    PoseLandmarkType.rightAnkle: FrozenLandmark(
      x: -0.2944,
      y: 1.1014,
      likelihood: 0.50,
    ),
    PoseLandmarkType.leftHeel: FrozenLandmark(
      x: 0.2249,
      y: 1.1900,
      likelihood: 0.53,
    ),
    PoseLandmarkType.rightHeel: FrozenLandmark(
      x: -0.3200,
      y: 1.1672,
      likelihood: 0.41,
    ),
    PoseLandmarkType.leftFootIndex: FrozenLandmark(
      x: 0.3484,
      y: 1.4086,
      likelihood: 0.36,
    ),
    PoseLandmarkType.rightFootIndex: FrozenLandmark(
      x: -0.2270,
      y: 1.3704,
      likelihood: 0.26,
    ),
  };

  // Joint Importance Weights for standing with one hand on four head   (for Engine 6):
  // {
  //   leftShoulder: 0.57,
  //   rightShoulder: 0.49,
  //   leftElbow: 0.41,
  //   rightElbow: 0.66,
  //   leftWrist: 0.82,
  //   rightWrist: 1.00,
  //   leftHip: 0.48,
  //   rightHip: 0.48,
  //   leftKnee: 0.46,
  //   rightKnee: 0.50,
  //   leftAnkle: 0.70,
  //   rightAnkle: 0.72,
  // }
}
