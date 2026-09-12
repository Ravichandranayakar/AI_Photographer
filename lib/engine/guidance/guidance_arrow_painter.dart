import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../guidance/guidance_signal.dart';
import '../state/camera_mirror_mode.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EDR DECISION — Research Topic 06: Guidance Engine
// ─────────────────────────────────────────────────────────────────────────────
//
// File: guidance_arrow_painter.dart
// Layer: Engine 7 — Guidance Renderer (Priority 2: Arrow)
//
// DESIGN PRINCIPLE:
//   This painter receives a GuidanceSignal and renders it blindly.
//   It does NOT analyze. It does NOT score. It only draws.
//   All coaching decisions (which joint, which direction, how urgent) are
//   made by Engine 6. Engine 7 converts those decisions into pixels.
//
// VISUAL DESIGN:
//   The arrow matches the existing doodle glow aesthetic:
//   - Outer glow bloom (wide, low opacity)
//   - Inner glow (medium opacity)
//   - Core arrow stroke (crisp, fully opaque)
//   - Animated: opacity pulses at 1.5Hz using the animationValue parameter
//   - Priority-aware: critical = large arrow, minor = small arrow
// ─────────────────────────────────────────────────────────────────────────────

/// Engine 7 — Arrow Painter.
///
/// Draws a single directional arrow near the bottleneck joint on screen.
/// The arrow pulses via [animationValue] (driven by an [AnimationController]
/// in the parent widget).
///
/// Usage:
/// ```dart
/// CustomPaint(
///   painter: GuidanceArrowPainter(
///     signal: guidanceSignal,
///     userLandmarks: normalizedLandmarks,
///     imageSize: cameraImageSize,
///     sensorRotation: rotation,
///     animationValue: _pulseAnimation.value,
///   ),
/// )
/// ```
class GuidanceArrowPainter extends CustomPainter {
  final GuidanceSignal signal;

  /// The raw user landmarks — used to find the bottleneck joint position.
  final Map<PoseLandmarkType, PoseLandmark> userLandmarks;

  final Size imageSize;
  final int sensorRotation;

  /// Controls X-axis mirroring for front vs rear camera.
  ///
  /// RULE: This is the ONLY place where mirror logic is applied for arrows.
  /// Engines 5 and 6 always work in raw ML Kit landmark space.
  /// This painter resolves the direction at paint time.
  final CameraMirrorMode mirrorMode;

  /// Animation value in [0.0 – 1.0] driving the pulse.
  final double animationValue;

  const GuidanceArrowPainter({
    required this.signal,
    required this.userLandmarks,
    required this.imageSize,
    required this.sensorRotation,
    required this.animationValue,
    this.mirrorMode = CameraMirrorMode.mirrored, // front camera default
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Engine 7 rule: if guidance is not needed, draw nothing.
    if (signal.isPostureAcceptable) return;
    if (signal.intent == CorrectionIntent.success) return;
    if (signal.intent == CorrectionIntent.ready) return;

    // ── Reposition intent: full-body instruction, NOT a joint arrow ──────────
    // When the whole body is off-center, show a directional text prompt.
    // Do NOT draw a joint arrow — the user needs to move their entire body.
    if (signal.intent == CorrectionIntent.reposition) {
      _drawRepositionIndicator(canvas, size);
      return;
    }

    // Find the screen position of the bottleneck joint.
    final Offset? jointScreen = _getJointScreenPosition(size);
    if (jointScreen == null) return;

    // Resolve correction direction with mirror mode.
    // Engine 6 produces dx/dy in raw ML Kit space.
    // Front camera: flip X so the arrow points the direction the USER perceives.
    final double resolvedDx = mirrorMode.resolveDirectionX(signal.correctionDx);
    final double resolvedDy = signal.correctionDy;

    // Compute arrow direction angle from resolved correction vector.
    final double angle = math.atan2(resolvedDy, resolvedDx);

    final double arrowLength = _arrowLengthForPriority(signal.priority);
    final double opacity = _pulseOpacity();

    _drawArrow(canvas, jointScreen, angle, arrowLength, opacity);
  }

  // ── Drawing ────────────────────────────────────────────────────────────────

  void _drawArrow(
    Canvas canvas,
    Offset position,
    double angle,
    double arrowLength,
    double opacity,
  ) {
    // Offset the arrow away from the joint body so it doesn't overlap.
    // 8px = ~2-3cm gap from the body outline edge.
    const double jointOffset = 8.0;
    final Offset arrowBase = position + Offset(
      math.cos(angle) * jointOffset,
      math.sin(angle) * jointOffset,
    );
    final Offset arrowTip = arrowBase + Offset(
      math.cos(angle) * arrowLength,
      math.sin(angle) * arrowLength,
    );

    // ── Outer glow (bloom) ───────────────────────────────────────────────
    final Paint glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    // ── Inner glow ─────────────────────────────────────────────────────────
    final Paint innerGlowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    // ── Core arrow line ────────────────────────────────────────────────────
    final Paint corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // ── Core arrowhead fill ───────────────────────────────────────────────
    final Paint headFillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92 * opacity)
      ..style = PaintingStyle.fill;

    // Build the arrow shaft path.
    final Path shaft = Path()
      ..moveTo(arrowBase.dx, arrowBase.dy)
      ..lineTo(arrowTip.dx, arrowTip.dy);

    // Build the arrowhead triangle.
    const double headSize = 9.0;
    final double headAngle1 = angle + math.pi * 0.75;
    final double headAngle2 = angle - math.pi * 0.75;

    final Path head = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(
        arrowTip.dx + math.cos(headAngle1) * headSize,
        arrowTip.dy + math.sin(headAngle1) * headSize,
      )
      ..lineTo(
        arrowTip.dx + math.cos(headAngle2) * headSize,
        arrowTip.dy + math.sin(headAngle2) * headSize,
      )
      ..close();

    // Draw layers (glow first, then core on top).
    canvas.drawPath(shaft, glowPaint);
    canvas.drawPath(shaft, innerGlowPaint);
    canvas.drawPath(shaft, corePaint);
    canvas.drawPath(head, headFillPaint);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Maps the bottleneck [signal.targetJoint] to its screen pixel position.
  /// Returns null if the joint is not in the user landmark map.
  Offset? _getJointScreenPosition(Size canvasSize) {
    final PoseLandmark? landmark = userLandmarks[signal.targetJoint];
    if (landmark == null) return null;

    final double x = _tx(landmark.x, canvasSize);
    final double y = _ty(landmark.y, canvasSize);
    return Offset(x, y);
  }

  double _tx(double x, Size canvasSize) {
    if (sensorRotation == 90 || sensorRotation == 270) {
      // Rotated sensor — image width maps to canvas height.
      // Mirror mode is applied to the direction vector above, not here.
      return canvasSize.width - (x * canvasSize.width / imageSize.height);
    }
    return x * canvasSize.width / imageSize.width;
  }

  double _ty(double y, Size canvasSize) {
    if (sensorRotation == 90 || sensorRotation == 270) {
      return y * canvasSize.height / imageSize.width;
    }
    return y * canvasSize.height / imageSize.height;
  }

  // ── Reposition Indicator ────────────────────────────────────────────────────

  /// Draws a full-body directional instruction when [CorrectionIntent.reposition] fires.
  /// Renders a centered pill with directional text — NOT a joint arrow.
  void _drawRepositionIndicator(Canvas canvas, Size size) {
    final String text = _repositionText();
    final double opacity = _pulseOpacity();

    // Background pill
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.18),
        width: 220,
        height: 44,
      ),
      const Radius.circular(22),
    );

    final Paint pillPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(pillRect, pillPaint);

    // Border
    final Paint borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(pillRect, borderPaint);

    // Text
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92 * opacity),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        size.width * 0.5 - tp.width / 2,
        size.height * 0.18 - tp.height / 2,
      ),
    );
  }

  /// Maps the current correction direction to a reposition text hint.
  String _repositionText() {
    // correctionDx/Dy from Engine 6 reposition signal:
    //   negative dx = user is right-of-center → tell them to step left
    //   positive dy = user is above center    → tell them to step down
    final double dx = mirrorMode.resolveDirectionX(signal.correctionDx);
    final double dy = signal.correctionDy;
    if (dx.abs() > dy.abs()) {
      return dx < 0 ? '← Step left' : 'Step right →';
    } else {
      return dy < 0 ? '↑ Move closer' : '↓ Step back';
    }
  }

  /// Arrow length in pixels, scaled by coaching priority.
  double _arrowLengthForPriority(CorrectionPriority priority) {
    switch (priority) {
      case CorrectionPriority.critical:
        return 40.0;
      case CorrectionPriority.major:
        return 32.0;
      case CorrectionPriority.minor:
        return 22.0;
    }
  }

  /// Pulse opacity between 0.6 and 1.0 at ~1.5Hz using the animation value.
  /// animationValue is driven by an AnimationController in the parent widget.
  double _pulseOpacity() {
    // animationValue oscillates 0.0 → 1.0. Map it to 0.6 → 1.0.
    return 0.6 + (animationValue * 0.4);
  }

  @override
  bool shouldRepaint(covariant GuidanceArrowPainter old) {
    return old.signal != signal ||
        old.animationValue != animationValue ||
        old.mirrorMode != mirrorMode ||
        old.userLandmarks != userLandmarks;
  }
}
