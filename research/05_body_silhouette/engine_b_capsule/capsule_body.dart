// ============================================================
// Engine B — CapsuleBody.dart
// Math reference: research/05_body_silhouette/math.md (B2, B3, B4)
// ============================================================
// Builds the 17-capsule skeleton from smoothed ML Kit landmarks.
//
// Equations implemented:
//   B2: Adaptive radius  — r_i = r_base * A_i * S * C_i
//   B3: Angle-aware      — r_i' = r_i * (1 + k*(1 - cos(theta)))
//   B4: Waist correction — r_waist = r_torso * (1 - lambda)
//   A_i: Anatomical scaling — independent per-bone multiplier
//   Floor: r_min = 8.0px — prevents collapse at far distances
// ============================================================

import 'dart:math' as math;
import 'capsule.dart';

// Landmark type constants (matching google_mlkit_pose_detection enum values)
// We use int constants here so this file can run without the Flutter plugin.
// The evaluator will cast them when creating the PoseLandmark objects.
class LandmarkIdx {
  static const int nose = 0;
  static const int leftEyeInner = 1;
  static const int leftEye = 2;
  static const int leftEyeOuter = 3;
  static const int rightEyeInner = 4;
  static const int rightEye = 5;
  static const int rightEyeOuter = 6;
  static const int leftEar = 7;
  static const int rightEar = 8;
  static const int leftMouth = 9;
  static const int rightMouth = 10;
  static const int leftShoulder = 11;
  static const int rightShoulder = 12;
  static const int leftElbow = 13;
  static const int rightElbow = 14;
  static const int leftWrist = 15;
  static const int rightWrist = 16;
  static const int leftPinky = 17;
  static const int rightPinky = 18;
  static const int leftIndex = 19;
  static const int rightIndex = 20;
  static const int leftThumb = 21;
  static const int rightThumb = 22;
  static const int leftHip = 23;
  static const int rightHip = 24;
  static const int leftKnee = 25;
  static const int rightKnee = 26;
  static const int leftAnkle = 27;
  static const int rightAnkle = 28;
  static const int leftHeel = 29;
  static const int rightHeel = 30;
  static const int leftFootIndex = 31;
  static const int rightFootIndex = 32;
}

// A simple landmark struct for the evaluator
class RawLandmark {
  final double x, y, confidence;
  const RawLandmark(this.x, this.y, this.confidence);
}

// ─────────────────────────────────────────────────────────────────────────────

class CapsuleBody {
  // ── Tuning coefficients ──────────────────────────────────────────────────
  static const double referenceTorsoLength =
      150.0; // pixels — calibrated to real arm's-length distance
  static const double k = 0.30; // Equation B3: angle-aware tuning
  static const double lambda = 0.15; // Equation B4: waist narrowing
  static const double minConfidence = 0.50; // Confidence gate

  // ── Anatomical base radii (pixels at reference torso = 150px) ────────────
  // Calibrated against real recordings where torsoPx ≈ 98-139px (arm's length).
  // Increased from v1 to correctly enclose body width.
  static const Map<String, double> _rBase = {
    'head': 32.0, // slightly reduced — was 42, too far from head
    'neck': 16.0, // neck tube (narrow)
    'shoulder': 30.0, // shoulder span capsule (wide to cover deltoid)
    'upperArm': 17.0,
    'forearm': 13.0,
    'torso': 34.0, // side torso — increased for body width
    'hip': 26.0, // hip span capsule
    'upperLeg': 22.0,
    'lowerLeg': 16.0,
    'foot': 11.0,
  };

  // Anatomical weights for Engine C field accumulation (stored on capsule)
  static const Map<String, double> _weight = {
    'head': 0.9,
    'neck': 0.8,
    'shoulder': 1.0,
    'upperArm': 0.7,
    'forearm': 0.65,
    'torso': 1.0,
    'hip': 1.0,
    'upperLeg': 0.85,
    'lowerLeg': 0.75,
    'foot': 0.55,
    'groin': 0.80,
  };

  // ── Anatomical Scaling (A_i) — Equation B2 addition ─────────────────────
  // A_i is a per-bone multiplier independent of torso scale S.
  // Allows tuning each bone's visual thickness independently.
  // Research basis: animation rig proportions, human body atlas ratios.
  static const Map<String, double> _aScale = {
    'head': 1.10, // Head is proportionally wider than shoulder radius implies
    'neck': 0.55, // Neck is narrow
    'shoulder': 0.95, // Shoulder span — slightly conservative
    'upperArm': 0.85, // Upper arm thinner than torso
    'forearm': 0.70, // Forearm thinner than upper arm
    'torso': 1.00, // Reference bone — A_i = 1.0
    'hip': 0.90, // Hip span slightly narrower than shoulder span
    'upperLeg': 1.00, // Thigh as thick as torso reference
    'lowerLeg': 0.80, // Shin thinner than thigh
    'foot': 0.55, // Foot is narrow in 2D projection
    'groin': 0.75, // Bridge capsule — moderate width to close inner-thigh gap
  };

  // ── Public API ───────────────────────────────────────────────────────────
  /// Build all capsules from smoothed landmark map.
  ///
  /// [landmarks] : Map<int index, RawLandmark> — raw pixel coordinates.
  /// [torsoPx]   : Euclidean distance mid-shoulder to mid-hip in pixels.
  static List<Capsule> build({
    required Map<int, RawLandmark> landmarks,
    required double torsoPx,
  }) {
    final capsules = <Capsule>[];
    final S = torsoPx / referenceTorsoLength; // Equation B2: scale factor

    // ── Helper: get Vec2 from landmark (null if missing or low confidence) ─
    Vec2? joint(int idx) {
      final lm = landmarks[idx];
      if (lm == null || lm.confidence < minConfidence) return null;
      return Vec2(lm.x, lm.y);
    }

    double conf(int idx) => landmarks[idx]?.confidence ?? 0.0;
    double avgConf(int a, int b) => (conf(a) + conf(b)) / 2.0;

    // ── Helper: Equation B3 — joint angle at B between bones A→B and B→C ──
    double jointAngle(Vec2 a, Vec2 b, Vec2 c) {
      final abx = b.x - a.x;
      final aby = b.y - a.y;
      final bcx = c.x - b.x;
      final bcy = c.y - b.y;
      final lenAB = math.sqrt(abx * abx + aby * aby);
      final lenBC = math.sqrt(bcx * bcx + bcy * bcy);
      if (lenAB < 1e-6 || lenBC < 1e-6) return 0.0;
      final cosTheta = (abx * bcx + aby * bcy) / (lenAB * lenBC);
      return math.acos(cosTheta.clamp(-1.0, 1.0));
    }

    // ── Helper: compute adaptive radius (B2 + B3 + A_i + floor) ────────────
    // Full equation: r_i = r_base * A_i * (1 + k*(1-cosθ)) * S * C_i
    // Clamped to minimum 8.0px — prevents invisible sticks at far distances.
    double radius(String key, int jA, int jB, {double angleTheta = 0.0}) {
      final ci = avgConf(jA, jB);
      if (ci < minConfidence) return 0.0;
      final rBase = _rBase[key]!;
      final aScale = _aScale[key]!; // A_i anatomical scaling
      // B3: angle-aware thickness
      final rAngle = rBase * aScale * (1.0 + k * (1.0 - math.cos(angleTheta)));
      // B2: torso scale + confidence, then clamp to floor
      return (rAngle * S * ci).clamp(8.0, double.infinity);
    }

    // ── Helper: add capsule if both endpoints are available ───────────────
    void addCap(
      Vec2? a,
      Vec2? b,
      int ia,
      int ib,
      String key, {
      double angle = 0.0,
      double? rOverride,
    }) {
      if (a == null || b == null) return;
      final r = rOverride ?? radius(key, ia, ib, angleTheta: angle);
      if (r < 1.5) return; // Skip sub-pixel capsules
      capsules.add(Capsule(a: a, b: b, r: r, weight: _weight[key]!));
    }

    // ── Retrieve all joints ───────────────────────────────────────────────
    final nose = joint(LandmarkIdx.nose);
    final lSh = joint(LandmarkIdx.leftShoulder);
    final rSh = joint(LandmarkIdx.rightShoulder);
    final lEl = joint(LandmarkIdx.leftElbow);
    final rEl = joint(LandmarkIdx.rightElbow);
    final lWr = joint(LandmarkIdx.leftWrist);
    final rWr = joint(LandmarkIdx.rightWrist);
    final lHip = joint(LandmarkIdx.leftHip);
    final rHip = joint(LandmarkIdx.rightHip);
    final lKn = joint(LandmarkIdx.leftKnee);
    final rKn = joint(LandmarkIdx.rightKnee);
    final lAnk = joint(LandmarkIdx.leftAnkle);
    final rAnk = joint(LandmarkIdx.rightAnkle);
    final lFoot = joint(LandmarkIdx.leftFootIndex);
    final rFoot = joint(LandmarkIdx.rightFootIndex);

    // Derived mid-points (not landmarks — computed from pairs)
    Vec2? midSh;
    if (lSh != null && rSh != null) {
      midSh = Vec2((lSh.x + rSh.x) / 2, (lSh.y + rSh.y) / 2);
    }
    Vec2? midHip;
    if (lHip != null && rHip != null) {
      midHip = Vec2((lHip.x + rHip.x) / 2, (lHip.y + rHip.y) / 2);
    }

    // ── Precompute joint angles (Equation B3) ─────────────────────────────
    // At elbow: angle between upper-arm and forearm
    double lElbowAngle = 0.0;
    if (lSh != null && lEl != null && lWr != null) {
      lElbowAngle = jointAngle(lSh, lEl, lWr);
    }
    double rElbowAngle = 0.0;
    if (rSh != null && rEl != null && rWr != null) {
      rElbowAngle = jointAngle(rSh, rEl, rWr);
    }
    // At knee: angle between thigh and shin
    double lKneeAngle = 0.0;
    if (lHip != null && lKn != null && lAnk != null) {
      lKneeAngle = jointAngle(lHip, lKn, lAnk);
    }
    double rKneeAngle = 0.0;
    if (rHip != null && rKn != null && rAnk != null) {
      rKneeAngle = jointAngle(rHip, rKn, rAnk);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  17-CAPSULE SKELETON (anatomically ordered)
    // ═══════════════════════════════════════════════════════════════════════

    // 1. Head (synthetic head-top above nose)
    // FIX: Nose is the LOWEST visible face point. The actual head top is above.
    // Compute a synthetic topOfHead point by moving upward from the nose
    // by the estimated head height (≈ 0.6 × shoulder-width).
    if (nose != null && lSh != null && rSh != null) {
      final shWidth = (rSh.x - lSh.x).abs().clamp(10.0, double.infinity);
      final headHeight =
          shWidth * 0.35; // anatomical ratio — reduced from 0.55 (was too high)
      // Direction: straight up in image coords (y decreases upward)
      final topOfHead = Vec2(nose.x, nose.y - headHeight);
      final S = torsoPx / referenceTorsoLength;
      final ci = conf(LandmarkIdx.nose);
      final rH = _rBase['head']! * S * ci;
      if (rH >= 1.5) {
        capsules.add(
          Capsule(a: topOfHead, b: nose, r: rH, weight: _weight['head']!),
        );
      }
    }

    // 2. Neck (nose → mid-shoulder, narrower)
    addCap(nose, midSh, LandmarkIdx.nose, LandmarkIdx.leftShoulder, 'neck');

    // 3. Shoulder span (left shoulder → right shoulder)
    addCap(
      lSh,
      rSh,
      LandmarkIdx.leftShoulder,
      LandmarkIdx.rightShoulder,
      'shoulder',
    );

    // 4. Left upper arm (shoulder → elbow, angle-aware at elbow)
    addCap(
      lSh,
      lEl,
      LandmarkIdx.leftShoulder,
      LandmarkIdx.leftElbow,
      'upperArm',
      angle: lElbowAngle,
    );

    // 5. Left forearm (elbow → wrist, angle-aware at elbow)
    addCap(
      lEl,
      lWr,
      LandmarkIdx.leftElbow,
      LandmarkIdx.leftWrist,
      'forearm',
      angle: lElbowAngle,
    );

    // 6. Right upper arm
    addCap(
      rSh,
      rEl,
      LandmarkIdx.rightShoulder,
      LandmarkIdx.rightElbow,
      'upperArm',
      angle: rElbowAngle,
    );

    // 7. Right forearm
    addCap(
      rEl,
      rWr,
      LandmarkIdx.rightElbow,
      LandmarkIdx.rightWrist,
      'forearm',
      angle: rElbowAngle,
    );

    // 8 & 9. Torso sides (left/right column — full r_torso width)
    addCap(lSh, lHip, LandmarkIdx.leftShoulder, LandmarkIdx.leftHip, 'torso');
    addCap(rSh, rHip, LandmarkIdx.rightShoulder, LandmarkIdx.rightHip, 'torso');

    // 10. Center torso — Equation B4: waist correction
    //     r_waist = r_torso * (1 - lambda)
    if (midSh != null && midHip != null) {
      final ci =
          (avgConf(LandmarkIdx.leftShoulder, LandmarkIdx.rightShoulder) +
              avgConf(LandmarkIdx.leftHip, LandmarkIdx.rightHip)) /
          2.0;
      if (ci >= minConfidence) {
        final rWaist = _rBase['torso']! * (1.0 - lambda) * S * ci;
        if (rWaist >= 1.5) {
          capsules.add(Capsule(a: midSh, b: midHip, r: rWaist, weight: 1.0));
        }
      }
    }

    // 11. Hip span
    addCap(lHip, rHip, LandmarkIdx.leftHip, LandmarkIdx.rightHip, 'hip');

    // 11b. Groin bridge — Phase 0 fix for inner-thigh gap (OQ-002)
    // Math proof: at torsoPx=130, knee separation=58.5px, leg coverage=38px → 20.5px gap.
    // Fix: synthetic midHip→midKnee capsule with r = r_upperLeg * A_groin fills the gap.
    // Does NOT use ML Kit landmark — computed from two averaged midpoints.
    if (midHip != null && lKn != null && rKn != null) {
      final midKnee = Vec2((lKn.x + rKn.x) / 2, (lKn.y + rKn.y) / 2);
      final ci =
          (avgConf(LandmarkIdx.leftHip, LandmarkIdx.rightHip) +
              avgConf(LandmarkIdx.leftKnee, LandmarkIdx.rightKnee)) /
          2.0;
      if (ci >= minConfidence) {
        final rGroin =
            (_rBase['upperLeg']! * _aScale['groin']! * (1.0 + k * 0.0) * S * ci)
                .clamp(8.0, double.infinity);
        if (rGroin >= 1.5) {
          capsules.add(
            Capsule(
              a: midHip,
              b: midKnee,
              r: rGroin,
              weight: _weight['groin']!,
            ),
          );
        }
      }
    }

    // 12 & 13. Left leg (thigh + shin with knee angle)
    addCap(
      lHip,
      lKn,
      LandmarkIdx.leftHip,
      LandmarkIdx.leftKnee,
      'upperLeg',
      angle: lKneeAngle,
    );
    addCap(
      lKn,
      lAnk,
      LandmarkIdx.leftKnee,
      LandmarkIdx.leftAnkle,
      'lowerLeg',
      angle: lKneeAngle,
    );

    // 14. Left foot
    addCap(
      lAnk,
      lFoot,
      LandmarkIdx.leftAnkle,
      LandmarkIdx.leftFootIndex,
      'foot',
    );

    // 15 & 16. Right leg
    addCap(
      rHip,
      rKn,
      LandmarkIdx.rightHip,
      LandmarkIdx.rightKnee,
      'upperLeg',
      angle: rKneeAngle,
    );
    addCap(
      rKn,
      rAnk,
      LandmarkIdx.rightKnee,
      LandmarkIdx.rightAnkle,
      'lowerLeg',
      angle: rKneeAngle,
    );

    // 17. Right foot
    addCap(
      rAnk,
      rFoot,
      LandmarkIdx.rightAnkle,
      LandmarkIdx.rightFootIndex,
      'foot',
    );

    return capsules;
  }
}
