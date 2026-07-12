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
import 'capsule_validator.dart';

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
  static const double k =
      0.05; // Equation B3: angle-aware tuning (reduced from 0.30 to stop knee bulbs)
  static const double lambda =
      0.05; // Equation B4: waist narrowing (reduced from 0.15 to stop torso pinch)
  static const double minConfidence = 0.50; // Confidence gate
  static const double doodleInflation =
      20.0; // Sweet spot: not massive balloons (25.0), not shrink-wrapped (15.0).

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
    'heel': 11.0,
    'hand': 14.0,
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
    'heel': 0.50,
    'hand': 0.60,
  };

  // ── Anatomical Scaling (A_i) — Equation B2 addition ─────────────────────
  // A_i is a per-bone multiplier independent of torso scale S.
  // Allows tuning each bone's visual thickness independently.
  // Research basis: animation rig proportions, human body atlas ratios.
  static const Map<String, double> _aScale = {
    'head': 1.35, 
    'neck': 0.95, // Thicker than 0.70 (to reduce gap) but not blocky (1.30)
    'shoulder': 0.65, 
    'upperArm': 1.20, 
    'forearm': 1.15, 
    'torso': 1.25, 
    'hip': 1.15, 
    'upperLeg': 1.30, 
    'lowerLeg': 1.15, 
    'foot': 1.10, 
    'heel': 1.15, 
    'hand': 1.30, // Wide single 'mitt' instead of 3 thin prongs
    'groin': 0.95, 
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
    CapsuleValidator.resetTelemetry(); // Clear telemetry for new frame
    final capsules = <Capsule>[];
    final S = torsoPx / referenceTorsoLength; // Equation B2: scale factor

    // Validate joints via CapsuleValidator (Phase 1.5)
    final validScores = CapsuleValidator.evaluateJointScores(landmarks);

    // ── Helper: get Vec2 from landmark (null if missing) ───────
    Vec2? joint(int idx) {
      final lm = landmarks[idx];
      if (lm == null) return null;
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
      // B2: torso scale + confidence, then clamp to floor, then add doodle inflation
      return (rAngle * S * ci).clamp(8.0, double.infinity) +
          (doodleInflation * S);
    }

    // ── Helper: add capsule if validity score allows it ─────
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

      final dx = b.x - a.x;
      final dy = b.y - a.y;
      final length = math.sqrt(dx * dx + dy * dy);

      // Calculate overall validity score
      // baseConf already includes Visibility Graph penalties from validScores.
      final scoreA = validScores[ia] ?? 0.0;
      final scoreB = validScores[ib] ?? 0.0;
      var validity = (scoreA + scoreB) / 2.0;
      final baseConf = avgConf(ia, ib); // Raw ML Kit confidence for telemetry

      // 2. Bone Length penalty (Observational Mode)
      validity -= CapsuleValidator.getBoneLengthPenalty(
        key,
        length,
        torsoPx,
        baseConf,
      );

      // 3. Joint Angle penalty (Observational Mode)
      if (key == 'upperArm' || key == 'forearm') {
        validity -= CapsuleValidator.getJointAnglePenalty(
          'elbow',
          angle,
          baseConf,
        );
      } else if (key == 'upperLeg' || key == 'lowerLeg') {
        validity -= CapsuleValidator.getJointAnglePenalty(
          'knee',
          angle,
          baseConf,
        );
      }

      // Final decision
      if (validity < 0.5) return;

      final r = rOverride ?? radius(key, ia, ib, angleTheta: angle);
      if (r < 1.5) return; // Skip sub-pixel capsules
      capsules.add(Capsule(a: a, b: b, r: r, weight: _weight[key]!));
    }

    // ── Helper: extend a capsule outward to reach fingertips ─────
    void addExtendedCap(Vec2? a, Vec2? b, int ia, int ib, String key, {double factor = 1.25}) {
      if (a == null || b == null) return;
      final extEnd = Vec2(a.x + (b.x - a.x) * factor, a.y + (b.y - a.y) * factor);
      addCap(a, extEnd, ia, ib, key);
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
    final lIndex = joint(LandmarkIdx.leftIndex);
    final rIndex = joint(LandmarkIdx.rightIndex);
    final lThumb = joint(LandmarkIdx.leftThumb);
    final rThumb = joint(LandmarkIdx.rightThumb);
    final lPinky = joint(LandmarkIdx.leftPinky);
    final rPinky = joint(LandmarkIdx.rightPinky);
    final lHeel = joint(LandmarkIdx.leftHeel);
    final rHeel = joint(LandmarkIdx.rightHeel);

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
          shWidth *
          0.20; // Reduced from 0.30 to 0.20 to pull the top of the head down slightly
      // Direction: straight up in image coords (y decreases upward)
      final topOfHead = Vec2(nose.x, nose.y - headHeight);
      final S = torsoPx / referenceTorsoLength;

      final ci = avgConf(LandmarkIdx.leftEar, LandmarkIdx.rightEar);
      final rH = (_rBase['head']! * S * ci) + (doodleInflation * S);
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
        final rWaist =
            (_rBase['torso']! * (1.0 - lambda) * S * ci) +
            (doodleInflation * S);
        if (rWaist >= 1.5) {
          capsules.add(Capsule(a: midSh, b: midHip, r: rWaist, weight: 1.0));
        }
      }
    }

    // 11. Hip span
    addCap(lHip, rHip, LandmarkIdx.leftHip, LandmarkIdx.rightHip, 'hip');

    // 11b. Groin Bridge (Mathematically Correct Adaptive Topology)
    // Prevents the sharp V-shape crotch artifact by filling the gap with a U-shape.
    if (lKn != null && rKn != null && lHip != null && rHip != null) {
      final ci = (avgConf(LandmarkIdx.leftHip, LandmarkIdx.rightHip) +
              avgConf(LandmarkIdx.leftKnee, LandmarkIdx.rightKnee)) / 2.0;

      if (ci >= minConfidence) {
        // 1. Calculate Vectors for Thighs
        final lDx = lKn.x - lHip.x;
        final lDy = lKn.y - lHip.y;
        final lLen = math.sqrt(lDx * lDx + lDy * lDy);

        final rDx = rKn.x - rHip.x;
        final rDy = rKn.y - rHip.y;
        final rLen = math.sqrt(rDx * rDx + rDy * rDy);

        if (lLen > 0 && rLen > 0) {
          // Normalized thigh vectors
          final vlX = lDx / lLen;
          final vlY = lDy / lLen;
          final vrX = rDx / rLen;
          final vrY = rDy / rLen;

          // 2. Angle Bisector (Direction of the bridge)
          var bx = vlX + vrX;
          var by = vlY + vrY;
          final bLen = math.sqrt(bx * bx + by * by);
          if (bLen > 1e-5) {
            bx /= bLen;
            by /= bLen;
          } else {
            bx = 0.0;
            by = 1.0; // Fallback pointing straight down
          }

          // 3. Mathematical Bridge Length
          final hipDx = rHip.x - lHip.x;
          final hipDy = rHip.y - lHip.y;
          final hipWidth = math.sqrt(hipDx * hipDx + hipDy * hipDy);
          final avgThighLen = (lLen + rLen) / 2.0;

          // Clamped by Hip Width and Thigh Length so it never hangs too low
          final bridgeLen = math.min(0.8 * hipWidth, 0.3 * avgThighLen);

          // 4. Bridge Endpoint
          final midHip = Vec2((lHip.x + rHip.x) / 2.0, (lHip.y + rHip.y) / 2.0);
          final endPoint = Vec2(midHip.x + bx * bridgeLen, midHip.y + by * bridgeLen);

          // 5. Proportional Radius (75% of average thigh radius)
          final lThighR = radius('upperLeg', LandmarkIdx.leftHip, LandmarkIdx.leftKnee, angleTheta: lKneeAngle);
          final rThighR = radius('upperLeg', LandmarkIdx.rightHip, LandmarkIdx.rightKnee, angleTheta: rKneeAngle);
          final rGroin = ((lThighR + rThighR) / 2.0) * 0.75;

          if (rGroin >= 1.5) {
            capsules.add(Capsule(a: midHip, b: endPoint, r: rGroin, weight: 1.0));
          }
        }
      }
    }
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

    // 14. Left foot (ankle to toes)
    if ((validScores[LandmarkIdx.leftAnkle] ?? 0.0) >= minConfidence) {
      final r = radius('foot', LandmarkIdx.leftAnkle, LandmarkIdx.leftAnkle);
      if (r >= 1.5) capsules.add(Capsule(a: lAnk!, b: lAnk, r: r, weight: _weight['foot']!));
    }
    addExtendedCap(lAnk, lFoot, LandmarkIdx.leftAnkle, LandmarkIdx.leftFootIndex, 'foot', factor: 1.20);
    addCap(lAnk, lHeel, LandmarkIdx.leftAnkle, LandmarkIdx.leftHeel, 'heel');

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

    // 17. Right foot (ankle to toes)
    if ((validScores[LandmarkIdx.rightAnkle] ?? 0.0) >= minConfidence) {
      final r = radius('foot', LandmarkIdx.rightAnkle, LandmarkIdx.rightAnkle);
      if (r >= 1.5) capsules.add(Capsule(a: rAnk!, b: rAnk, r: r, weight: _weight['foot']!));
    }
    addExtendedCap(rAnk, rFoot, LandmarkIdx.rightAnkle, LandmarkIdx.rightFootIndex, 'foot', factor: 1.20);
    addCap(rAnk, rHeel, LandmarkIdx.rightAnkle, LandmarkIdx.rightHeel, 'heel');

    // 18. Left hand (palm + fingers single unified mitt)
    if ((validScores[LandmarkIdx.leftWrist] ?? 0.0) >= minConfidence) {
      final r = radius('hand', LandmarkIdx.leftWrist, LandmarkIdx.leftWrist);
      if (r >= 1.5) capsules.add(Capsule(a: lWr!, b: lWr, r: r, weight: _weight['hand']!));
    }
    // Single wide extended capsule covering all fingers smoothly
    addExtendedCap(lWr, lIndex, LandmarkIdx.leftWrist, LandmarkIdx.leftIndex, 'hand', factor: 1.35);

    // 19. Right hand (palm + fingers single unified mitt)
    if ((validScores[LandmarkIdx.rightWrist] ?? 0.0) >= minConfidence) {
      final r = radius('hand', LandmarkIdx.rightWrist, LandmarkIdx.rightWrist);
      if (r >= 1.5) capsules.add(Capsule(a: rWr!, b: rWr, r: r, weight: _weight['hand']!));
    }
    addExtendedCap(rWr, rIndex, LandmarkIdx.rightWrist, LandmarkIdx.rightIndex, 'hand', factor: 1.35);

    return capsules;
  }
}
