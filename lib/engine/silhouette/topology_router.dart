import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'silhouette_config.dart';
import 'vec2.dart';

/// Classifies how a joint participates in the hull expansion.
enum JointRole {
  /// Normal offset — perpendicular normal push left/right.
  standard,

  /// Angle bisector — average the normals of the two bones meeting at this joint.
  hinge,

  /// Axial extrusion — push forward along the bone direction (not sideways).
  cap,

  /// Computed synthetic point, not a MediaPipe landmark.
  synthetic,
}

/// A single entry in the ordered topology loop.
class TopologyEntry {
  final PoseLandmarkType? joint; // null for synthetic points
  final JointRole role;
  final double radiusStart; // r₁ at this joint
  final double radiusEnd;   // r₂ at the next joint (for lerp)

  const TopologyEntry({
    required this.joint,
    required this.role,
    required this.radiusStart,
    required this.radiusEnd,
  });

  const TopologyEntry.synthetic({
    required this.radiusStart,
    required this.radiusEnd,
  })  : joint = null,
        role = JointRole.synthetic;
}

/// Defines the clockwise perimeter traversal order for the full body silhouette.
///
/// This is the Topology Router — Stage 1 of the Silhouette Pipeline.
///
/// The order must form a single closed loop around the body without gaps.
/// Joint classifications:
///   [JointRole.standard] → perpendicular normal expansion
///   [JointRole.hinge]    → angle bisector at elbow/knee/axilla
///   [JointRole.cap]      → axial extrusion at wrist/foot/nose
///   [JointRole.synthetic]→ computed geometric point (crotch anchor)
abstract final class TopologyRouter {
  /// Builds the ordered topology entries using radii from [config].
  static List<TopologyEntry> build(SilhouetteConfig config) {
    return [
      // ── Left side, going down ────────────────────────────────────────────
      TopologyEntry(
        joint: PoseLandmarkType.nose,
        role: JointRole.cap,
        radiusStart: config.rHead,
        radiusEnd: config.rShoulder,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.leftEar,
        role: JointRole.standard,
        radiusStart: config.rHead,
        radiusEnd: config.rShoulder,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.leftShoulder,
        role: JointRole.standard,
        radiusStart: config.rShoulder,
        radiusEnd: config.rUpperArm,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.leftElbow,
        role: JointRole.hinge,
        radiusStart: config.rUpperArm,
        radiusEnd: config.rForearm,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.leftWrist,
        role: JointRole.cap, // generates arriving, forward, and departing points
        radiusStart: config.rWrist,
        radiusEnd: config.rForearm,
      ),
      // ── Left arm inner (coming back up) ─────────────────────────────────
      TopologyEntry(
        joint: PoseLandmarkType.leftElbow,
        role: JointRole.hinge,   // inner elbow
        radiusStart: config.rForearm,
        radiusEnd: config.rUpperArm,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.leftShoulder,
        role: JointRole.hinge,   // axilla
        radiusStart: config.rUpperArm,
        radiusEnd: config.rTorso,
      ),
      // ── Left torso + leg ────────────────────────────────────────────────
      TopologyEntry(
        joint: PoseLandmarkType.leftHip,
        role: JointRole.standard,
        radiusStart: config.rHip,
        radiusEnd: config.rThigh,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.leftKnee,
        role: JointRole.hinge,
        radiusStart: config.rThigh,
        radiusEnd: config.rCalf,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.leftAnkle,
        role: JointRole.cap,
        radiusStart: config.rAnkle,
        radiusEnd: config.rFoot,
      ),
      // ── Crotch anchor (synthetic) ────────────────────────────────────────
      TopologyEntry.synthetic(
        radiusStart: config.rCrotch,
        radiusEnd: config.rCrotch,
      ),
      // ── Right leg ────────────────────────────────────────────────────────
      TopologyEntry(
        joint: PoseLandmarkType.rightAnkle,
        role: JointRole.cap,
        radiusStart: config.rAnkle,
        radiusEnd: config.rFoot,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.rightKnee,
        role: JointRole.hinge,
        radiusStart: config.rCalf,
        radiusEnd: config.rThigh,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.rightHip,
        role: JointRole.standard,
        radiusStart: config.rThigh,
        radiusEnd: config.rHip,
      ),
      // ── Right arm + side going up ────────────────────────────────────────
      TopologyEntry(
        joint: PoseLandmarkType.rightShoulder,
        role: JointRole.hinge,
        radiusStart: config.rTorso,
        radiusEnd: config.rUpperArm,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.rightElbow,
        role: JointRole.hinge,   // inner elbow
        radiusStart: config.rUpperArm,
        radiusEnd: config.rForearm,
      ),
      // ── Right arm cap + outer ────────────────────────────────────────────
      TopologyEntry(
        joint: PoseLandmarkType.rightWrist,
        role: JointRole.cap, // generates arriving, forward, departing points
        radiusStart: config.rWrist,
        radiusEnd: config.rForearm,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.rightElbow,
        role: JointRole.hinge,
        radiusStart: config.rForearm,
        radiusEnd: config.rUpperArm,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.rightShoulder,
        role: JointRole.standard,
        radiusStart: config.rUpperArm,
        radiusEnd: config.rShoulder,
      ),
      TopologyEntry(
        joint: PoseLandmarkType.rightEar,
        role: JointRole.standard,
        radiusStart: config.rShoulder,
        radiusEnd: config.rHead,
      ),
      // Loop closes back to Nose
    ];
  }

  /// Returns the position of the synthetic crotch anchor point.
  static Vec2 crotchAnchor(
    Vec2 leftHip,
    Vec2 rightHip,
    double radius,
    double scaleFactor,
  ) {
    // Midpoint between hips, pushed downward (positive Y in screen coords)
    final mx = (leftHip.x + rightHip.x) / 2.0;
    final my = (leftHip.y + rightHip.y) / 2.0;
    return Vec2(mx, my + radius * scaleFactor);
  }
}
