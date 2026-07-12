import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'silhouette_config.dart';
import 'topology_router.dart';
import 'vec2.dart';

/// Phase A of the Silhouette Pipeline: Kinematic Expansion.
///
/// Transforms the ordered topology of 1D skeleton joint positions
/// into a 2D closed blocky polygon hull (the Kinematic Control Polygon).
///
/// Mathematical reference: research/05_body_silhouette/math.md — Stage 2
///
/// Applies in order:
///   - Confidence Gate (pre-filter joints)
///   - Standard joint: perpendicular normal expansion with radius lerp
///   - Hinge joint:    angle bisector (average incoming + outgoing normals)
///   - Cap joint:      axial extrusion (push along bone direction)
///   - Synthetic point: computed crotch anchor
abstract final class KinematicHull {
  /// Generates the closed hull polygon from the ordered topology.
  ///
  /// [landmarks] — smoothed, normalized landmarks from the 1 Euro Filter output.
  /// [config]    — biological radius registry and scale configuration.
  /// [torsoPx]   — live torso pixel length from LandmarkNormalizer for scaling.
  ///
  /// Returns the ordered list of hull vertices forming the closed control polygon.
  /// Returns an empty list if insufficient valid joints are detected.
  static List<Vec2> generate({
    required Map<PoseLandmarkType, PoseLandmark> landmarks,
    required SilhouetteConfig config,
    required double torsoPx,
  }) {
    final scaleFactor = config.scaleFactorFor(torsoPx);
    final topology = TopologyRouter.build(config);
    final List<Vec2> hull = [];

    // ── Confidence Gate ────────────────────────────────────────────────────
    // Build a confidence-filtered coordinate map.
    final Map<PoseLandmarkType, Vec2> validJoints = {};
    for (final entry in landmarks.entries) {
      if (entry.value.likelihood >= config.minConfidence) {
        validJoints[entry.key] = Vec2(entry.value.x, entry.value.y);
      }
    }

    // ── Build the synthetic crotch anchor ─────────────────────────────────
    final leftHip = validJoints[PoseLandmarkType.leftHip];
    final rightHip = validJoints[PoseLandmarkType.rightHip];
    Vec2? crotch;
    if (leftHip != null && rightHip != null) {
      crotch = TopologyRouter.crotchAnchor(
        leftHip, rightHip, config.rCrotch, scaleFactor,
      );
    }

    // ── Process each topology entry ────────────────────────────────────────
    Vec2? prevNormal; // Retained for bisector calculation and ε-guard fallback

    for (int i = 0; i < topology.length; i++) {
      final entry = topology[i];

      // Synthetic crotch anchor
      if (entry.role == JointRole.synthetic) {
        if (crotch != null) {
          hull.add(crotch);
        }
        continue;
      }

      final jointType = entry.joint!;
      final current = validJoints[jointType];

      // Skip missing/low-confidence joints gracefully
      if (current == null) continue;

      // Peek at next entry to compute bone direction
      final nextEntry = topology[(i + 1) % topology.length];
      final nextType = nextEntry.joint;
      final next = nextType != null ? validJoints[nextType] : null;

      switch (entry.role) {
        case JointRole.standard:
          if (next == null) continue;
          final bone = next - current;
          if (bone.isDegenerate) {
            // ε-guard: reuse previous valid normal if this bone is degenerate
            if (prevNormal != null) {
              final r = entry.radiusStart * scaleFactor;
              hull.add(current + prevNormal! * r);
            }
            continue;
          }
          final normal = bone.normalCCW; // Verify outward direction on prototype
          prevNormal = normal;
          final r = entry.radiusStart * scaleFactor;
          hull.add(current + normal * r);

        case JointRole.hinge:
          // Bisector: average the incoming and outgoing normals
          if (prevNormal == null || next == null) continue;
          final outBone = next - current;
          if (outBone.isDegenerate) continue;
          final outNormal = outBone.normalCCW;
          final bisector = Vec2(
            prevNormal!.x + outNormal.x,
            prevNormal!.y + outNormal.y,
          );
          if (bisector.isDegenerate) continue;
          final bisectorNorm = bisector.normalized;
          prevNormal = bisectorNorm;
          final r = entry.radiusStart * scaleFactor;
          hull.add(current + bisectorNorm * r);

        case JointRole.cap:
          // Axial extrusion: we need the bone pointing INTO this cap to know the outward direction.
          // Look backwards in the topology to find the previous valid joint.
          Vec2? prev;
          for (int step = 1; step <= topology.length; step++) {
            final prevEntry = topology[(i - step + topology.length) % topology.length];
            if (prevEntry.joint != null) {
              prev = validJoints[prevEntry.joint!];
              if (prev != null) break;
            }
          }
          if (prev == null) continue;

          final bone = current - prev; // Outward pointing bone
          if (bone.isDegenerate) continue;
          
          final boneDir = bone.normalized;
          final sideNormal = boneDir.normalCCW;
          final r = entry.radiusStart * scaleFactor;

          // Clockwise 180-degree turn at the cap:
          // 1. Arriving side (left of bone direction when facing outward)
          hull.add(current - sideNormal * r);
          // 2. Forward tip
          hull.add(current + boneDir * r);
          // 3. Departing side (right of bone direction)
          hull.add(current + sideNormal * r);

        case JointRole.synthetic:
          break; // Handled above
      }
    }

    return hull;
  }
}
