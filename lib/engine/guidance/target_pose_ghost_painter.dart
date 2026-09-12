import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/frozen_landmark.dart';
import '../state/app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Target Pose Ghost Painter
// ─────────────────────────────────────────────────────────────────────────────
//
// PURPOSE:
//   Draws the selected TARGET pose as a ghostly skeleton silhouette on screen.
//   The user moves their body to "fill" this ghost outline.
//
// COORDINATE SYSTEM:
//   FrozenLandmarks use normalized coordinates:
//     - Origin (0, 0) = mid-hip center
//     - Y axis: negative = UP, positive = DOWN
//     - Scale = torso length units
//
//   This painter maps those normalized coordinates to screen space using
//   a fixed anchor at the vertical center of the screen and an auto-scale
//   factor based on screen height.
//
// VISUAL DESIGN:
//   - Dashed cyan glow skeleton (NOT a solid body shape)
//   - Semi-transparent so camera feed shows through
//   - Pulses gently to indicate "this is your target"
//   - Color: cyan (#00FFFF) to contrast with the white live silhouette
// ─────────────────────────────────────────────────────────────────────────────

/// The body connections to draw as the ghost skeleton.
/// Each entry is a pair of [PoseLandmarkType] endpoints.
const List<(PoseLandmarkType, PoseLandmarkType)> _kSkeletonBones = [
  // Torso
  (PoseLandmarkType.leftShoulder,  PoseLandmarkType.rightShoulder),
  (PoseLandmarkType.leftShoulder,  PoseLandmarkType.leftHip),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftHip,       PoseLandmarkType.rightHip),

  // Left arm
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
  (PoseLandmarkType.leftElbow,    PoseLandmarkType.leftWrist),

  // Right arm
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
  (PoseLandmarkType.rightElbow,    PoseLandmarkType.rightWrist),

  // Left leg
  (PoseLandmarkType.leftHip,   PoseLandmarkType.leftKnee),
  (PoseLandmarkType.leftKnee,  PoseLandmarkType.leftAnkle),

  // Right leg
  (PoseLandmarkType.rightHip,   PoseLandmarkType.rightKnee),
  (PoseLandmarkType.rightKnee,  PoseLandmarkType.rightAnkle),

  // Head to shoulders
  (PoseLandmarkType.nose,          PoseLandmarkType.leftShoulder),
  (PoseLandmarkType.nose,          PoseLandmarkType.rightShoulder),
];

class TargetPoseGhostPainter extends CustomPainter {
  final Map<PoseLandmarkType, FrozenLandmark> targetPose;

  /// Animation value [0.0 – 1.0] from pulse controller for breathing effect.
  final double animationValue;

  /// Scale factor from [GlobalAlignmentCheck.evaluate] (Q5 resolution).
  ///
  /// Computed as `(liveTorsoLength / targetTorsoLength).clamp(0.5, 2.0)`.
  /// Default 1.0 = no scaling (pre-alignment phase).
  ///
  /// Pass this every frame from the state machine so the ghost
  /// automatically grows/shrinks to match the user's actual body size.
  final double scaleFactor;

  /// Current session state. Used to switch the ghost color:
  ///   poseMatched / captureCountdown → green ghost (success feedback)
  ///   all other states               → cyan ghost (target guide)
  final AppState? appState;

  const TargetPoseGhostPainter({
    required this.targetPose,
    required this.animationValue,
    this.scaleFactor = 1.0,
    this.appState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (targetPose.isEmpty) return;

    // ── State-aware color ───────────────────────────────────────────────────────
    // Matched state: ghost turns green to confirm success before capture.
    final bool isMatchState = appState == AppState.poseMatched ||
        appState == AppState.captureCountdown;
    final Color ghostColor = isMatchState
        ? const Color(0xFF00FF88)  // green: matched
        : const Color(0xFF00FFFF); // cyan:  guiding

    // ── Compute scale + anchor ───────────────────────────────────────────────────
    // FrozenLandmarks: 1 unit ≈ 1 torso length.
    // [scaleFactor] adapts the ghost to the user's actual body size.
    // A typical person occupies ~3 torso lengths head-to-toe.
    // We target 75% of screen height for the full body at scaleFactor=1.0.
    const double targetBodyHeightRatio = 0.75;
    const double normalizedBodyHeight  = 2.8; // approx head-to-ankle in torso units
    final double baseScale = (size.height * targetBodyHeightRatio) / normalizedBodyHeight;
    final double scale = baseScale * scaleFactor;

    // Anchor: center of screen horizontally, 45% down vertically (slightly above center
    // so feet land near the bottom of the visible area).
    final double anchorX = size.width  * 0.50;
    final double anchorY = size.height * 0.45;

    // ── Convert normalized → screen ────────────────────────────────────────
    Offset? toScreen(PoseLandmarkType type) {
      final lm = targetPose[type];
      if (lm == null) return null;
      // Note: FrozenLandmark Y is negative-up, so we negate to flip to screen-down.
      return Offset(anchorX + lm.x * scale, anchorY + lm.y * scale);
    }

    // ── Pulse opacity: breathes between 0.55 and 0.85 ──────────────────────────
    // Matched state: pulse faster (0.85–1.0) for celebration effect.
    final double opacity = isMatchState
        ? 0.85 + animationValue * 0.15
        : 0.55 + animationValue * 0.30;

    // ── Paints ─────────────────────────────────────────────────────────────────
    // Outer glow
    final Paint glow = Paint()
      ..color = ghostColor.withValues(alpha: 0.12 * opacity)
      ..style  = PaintingStyle.stroke
      ..strokeWidth = 22.0
      ..strokeCap   = StrokeCap.round
      ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 14.0);

    // Inner glow
    final Paint innerGlow = Paint()
      ..color = ghostColor.withValues(alpha: 0.30 * opacity)
      ..style  = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap   = StrokeCap.round
      ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 4.0);

    // Core dashed line
    final Paint core = Paint()
      ..color = ghostColor.withValues(alpha: 0.85 * opacity)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap   = StrokeCap.round
      ..isAntiAlias = true;

    // ── Draw each bone ─────────────────────────────────────────────────────
    for (final (start, end) in _kSkeletonBones) {
      final Offset? p1 = toScreen(start);
      final Offset? p2 = toScreen(end);
      if (p1 == null || p2 == null) continue;

      canvas.drawLine(p1, p2, glow);
      canvas.drawLine(p1, p2, innerGlow);
      _drawDashedLine(canvas, p1, p2, core);
    }

    // ── Draw joint dots at key points ─────────────────────────────────────
    final Paint dot = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.90 * opacity)
      ..style = PaintingStyle.fill;

    for (final type in _kJointDots) {
      final Offset? p = toScreen(type);
      if (p == null) continue;
      canvas.drawCircle(p, 5.0, dot);
    }
  }

  // ── Dashed line helper ──────────────────────────────────────────────────────
  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashLen  = 10.0;
    const double gapLen   =  6.0;

    final double dx    = p2.dx - p1.dx;
    final double dy    = p2.dy - p1.dy;
    final double total = math.sqrt(dx * dx + dy * dy);
    if (total == 0) return;

    final double ux = dx / total;
    final double uy = dy / total;

    double traveled = 0.0;
    bool drawing = true;

    while (traveled < total) {
      final double segEnd = math.min(traveled + (drawing ? dashLen : gapLen), total);
      if (drawing) {
        canvas.drawLine(
          Offset(p1.dx + ux * traveled, p1.dy + uy * traveled),
          Offset(p1.dx + ux * segEnd,   p1.dy + uy * segEnd),
          paint,
        );
      }
      traveled = segEnd;
      drawing  = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant TargetPoseGhostPainter old) =>
      old.targetPose     != targetPose ||
      old.animationValue != animationValue ||
      old.scaleFactor    != scaleFactor ||
      old.appState       != appState;
}

/// Joints to render as dots (key anatomical anchors).
const List<PoseLandmarkType> _kJointDots = [
  PoseLandmarkType.nose,
  PoseLandmarkType.leftShoulder,
  PoseLandmarkType.rightShoulder,
  PoseLandmarkType.leftElbow,
  PoseLandmarkType.rightElbow,
  PoseLandmarkType.leftWrist,
  PoseLandmarkType.rightWrist,
  PoseLandmarkType.leftHip,
  PoseLandmarkType.rightHip,
  PoseLandmarkType.leftKnee,
  PoseLandmarkType.rightKnee,
  PoseLandmarkType.leftAnkle,
  PoseLandmarkType.rightAnkle,
];
