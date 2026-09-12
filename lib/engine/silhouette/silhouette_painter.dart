import 'dart:typed_data' show Float64List;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../guidance/guidance_signal.dart';
import '../silhouette/silhouette_engine.dart';
import '../silhouette/vec2.dart';
import '../state/app_state.dart';
import '../state/camera_mirror_mode.dart';
import 'dart:math' as math;

/// The visual heart of Frozen AI.
///
/// Consumes the output of [SilhouetteEngine] and renders a smooth,
/// glowing white body outline on Flutter's [Canvas].
///
/// Rendering design:
///   Layer 1 — Outer glow:  wide, very low-opacity white stroke (bloom effect)
///   Layer 2 — Inner glow:  medium, low-opacity white stroke
///   Layer 3 — Core line:   thin, fully opaque white stroke (crisp edge)
///
/// This three-layer technique is identical to how professional AR overlays
/// (Apple Fitness+, Huawei Health) achieve the premium "holographic silhouette"
/// appearance without any shader complexity.
///
/// Coordinate system:
///   [SilhouetteEngine] outputs coordinates in **raw ML Kit pixel space**
///   (same space as [PosePainter]). The painter maps those to canvas pixels
///   using the same [_translateX] / [_translateY] logic from [PosePainter].
class SilhouettePainter extends CustomPainter {
  final SilhouetteResult result;
  final Size imageSize;
  final int sensorRotation;

  /// Controls X-axis mirroring for front vs rear camera.
  /// RULE: Only SilhouettePainter applies the flip — engines 5 and 6 never flip.
  final CameraMirrorMode mirrorMode;

  /// Current session state. Used to switch the outline color:
  ///   poseMatched / captureCountdown → green outline (success feedback)
  ///   all other states               → white outline (live body tracker)
  final AppState? appState;

  /// When true, renders in CYAN ghost style (target pose outline).
  /// When false (default), renders in WHITE / GREEN (user's live body outline).
  final bool ghostMode;

  /// Engine 7 — Priority 1 (Visual Guidance): Outline Shift.
  ///
  /// When provided and [GuidanceSignal.isPostureAcceptable] is false,
  /// the silhouette outline is gently shifted in the correction direction
  /// to give the user a "step inside the shape" visual cue.
  ///
  /// Optional: existing callers that don’t yet wire up Engine 6 continue
  /// to work normally with no shift applied.
  final GuidanceSignal? guidanceSignal;

  final Paint _fill;    // subtle body fill — gives silhouette its “solid” feel
  final Paint _glow3;
  final Paint _glow2;
  final Paint _coreLine;

  /// Cache transform parameters for the ghost
  final double? ghostAnchorX;
  final double? ghostAnchorY;
  final double? ghostTorsoPx;
  final bool? ghostMirrorX;

  SilhouettePainter({
    required this.result,
    required this.imageSize,
    required this.sensorRotation,
    this.mirrorMode = CameraMirrorMode.mirrored,
    this.appState,
    this.guidanceSignal,
    this.ghostMode = false,
    this.ghostAnchorX,
    this.ghostAnchorY,
    this.ghostTorsoPx,
    this.ghostMirrorX,
  })  : _fill = Paint()
          ..color = (ghostMode
              ? const Color(0xFF00FFFF).withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.04))
          ..style = PaintingStyle.fill,
        _glow3 = Paint()
          ..color = (ghostMode
              ? const Color(0xFF00FFFF).withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.07))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 36.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22.0),
        _glow2 = Paint()
          ..color = (ghostMode
              ? const Color(0xFF00FFFF).withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.20))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0),
        _coreLine = Paint()
          ..color = (ghostMode
              ? const Color(0xFF00FFFF).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.92))
          ..style = PaintingStyle.stroke
          ..strokeWidth = ghostMode ? 2.0 : 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    if (!result.isValid) return;

    // ── State-aware color override ───────────────────────────────────────────────────
    // When the pose is matched, flash the outline green.
    // This gives the user immediate visual confirmation before the ring fills.
    final bool isMatchState = appState == AppState.poseMatched ||
        appState == AppState.captureCountdown;

    if (isMatchState && !ghostMode) {
      // Override paint colors to green for matched state.
      _glow2.color = const Color(0xFF00FF88).withValues(alpha: 0.28);
      _coreLine.color = const Color(0xFF00FF88).withValues(alpha: 0.92);
    }

    // ── v2 CSG path (pre-merged by CsgExtractor) — use directly ────────────
    if (result.csgPath != null) {
      var basePath = _transformCsgPath(result.csgPath!, size);
      
      // Apply Curvature-Aware Selective Smoothing (Phase 3: Corner rendering)
      basePath = _smoothCorners(basePath);

      // ── Engine 7 Priority 1: Outline Shift ─────────────────────────────────
      // Shift the outline gently toward the target position.
      // Max shift = 20px. User’s instinct: “step inside the glowing shape.”
      basePath = _applyGuidanceShift(basePath, size);
      
      canvas.drawPath(basePath, _fill);
      canvas.drawPath(basePath, _glow3);
      canvas.drawPath(basePath, _glow2);
      canvas.drawPath(basePath, _coreLine);
      return;
    }

    // ── v1 / Engine A path (List<Vec2> polygon) — build from points ─────────
    final basePath = _buildPath(result.path, size);
    if (basePath == null) return;
    
    // === TEMPORARILY DISABLED DOODLE FOR RESEARCH ===
    // final doodlePath = _stylizePathToDoodle(basePath);
    // canvas.drawPath(doodlePath, _coreLine);

    // ── Engine 7 Priority 1: Outline Shift ───────────────────────────────────
    final shiftedPath = _applyGuidanceShift(basePath, size);

    canvas.drawPath(shiftedPath, _fill);
    canvas.drawPath(shiftedPath, _glow3);
    canvas.drawPath(shiftedPath, _glow2);
    canvas.drawPath(shiftedPath, _coreLine);
  }

  /// [v2 CSG] Applies the same coordinate transform as _buildPath() but via
  /// matrix transformation on the pre-built CSG path.
  ///
  /// The CSG path is in ML Kit raw pixel space. We need to map it to canvas
  /// coordinates using the same _tx / _ty logic.
  ui.Path _transformCsgPath(ui.Path csgPath, Size canvasSize) {
    double sx, sy, tx, ty;

    // Whether to apply an X-flip:
    // - Live user silhouette (mirrorMode.mirrored): always flip on rotated sensors
    //   because ML Kit returns unmirrored coords but the front-camera preview is mirrored.
    // - Target ghost (mirrorMode.unmirrored): NEVER flip here — EngineBAdapter.processTargetPose
    //   already applied the correct chirality via mirrorX. A second flip would invert it.
    final bool shouldFlipX = mirrorMode == CameraMirrorMode.mirrored &&
        (sensorRotation == 90 || sensorRotation == 270);

    if (sensorRotation == 90 || sensorRotation == 270) {
      // Rotated sensor: image width maps to canvas height, height to width.
      if (shouldFlipX) {
        // Front camera: mirror X
        sx = -canvasSize.width  / imageSize.height;
        tx =  canvasSize.width;
      } else {
        // Rear camera / target ghost: no X-flip
        sx =  canvasSize.width  / imageSize.height;
        tx =  0;
      }
      sy = canvasSize.height / imageSize.width;
      ty = 0;
    } else {
      sx =  canvasSize.width  / imageSize.width;
      sy =  canvasSize.height / imageSize.height;
      tx =  0;
      ty =  0;
    }

    // Build a transform matrix: scale then translate
    final matrix = Float64List(16);
    // Column-major identity
    matrix[0]  = sx;
    matrix[5]  = sy;
    matrix[10] = 1.0;
    matrix[15] = 1.0;
    matrix[12] = tx;
    matrix[13] = ty;

    ui.Path pathToTransform = csgPath;
    
    // Apply ghost pre-transform (scale to user's body size and anchor to their hips)
    if (ghostAnchorX != null && ghostAnchorY != null && ghostTorsoPx != null) {
      final preMatrix = Float64List(16);
      final scale = ghostTorsoPx! / 100.0;
      preMatrix[0] = (ghostMirrorX == true) ? -scale : scale;
      preMatrix[5] = scale;
      preMatrix[10] = 1.0;
      preMatrix[15] = 1.0;
      preMatrix[12] = ghostAnchorX!;
      preMatrix[13] = ghostAnchorY!;
      pathToTransform = pathToTransform.transform(preMatrix);
    }

    ui.Path transformedPath = pathToTransform.transform(matrix);

    // ── Disconnected Island Filter ────────────────────────────────────────────
    // When a pose has a raised limb (e.g., leg lifted in air), Engine B CSG
    // creates a separate floating subpath "island" disconnected from the main body.
    // We compute the bounding box of each subpath and DISCARD any subpath whose
    // area is less than 20% of the main subpath — these are phantom artifacts.
    final metrics = transformedPath.computeMetrics().toList();
    if (metrics.length > 1) {
      // Measure each subpath's bounding box area
      final List<ui.Path> subPaths = [];
      final List<double> areas = [];
      for (final metric in metrics) {
        final sub = metric.extractPath(0, metric.length);
        final bounds = sub.getBounds();
        areas.add(bounds.width * bounds.height);
        subPaths.add(sub);
      }
      final maxArea = areas.reduce((a, b) => a > b ? a : b);
      final filtered = ui.Path();
      for (int i = 0; i < subPaths.length; i++) {
        if (areas[i] >= maxArea * 0.20) {
          filtered.addPath(subPaths[i], Offset.zero);
        }
      }
      return filtered;
    }

    return transformedPath;
  }

  /// Converts [Vec2] points (in ML Kit raw pixel space) to a closed Flutter [Path]
  /// mapped to canvas coordinates.
  ui.Path? _buildPath(List<Vec2> points, Size canvasSize) {
    if (points.isEmpty) return null;

    final path = ui.Path();
    
    double applyX(double rawX) {
      if (ghostAnchorX != null && ghostTorsoPx != null) {
        final scale = ghostTorsoPx! / 100.0;
        return ghostAnchorX! + ((ghostMirrorX == true) ? -rawX : rawX) * scale;
      }
      return rawX;
    }

    double applyY(double rawY) {
      if (ghostAnchorY != null && ghostTorsoPx != null) {
        final scale = ghostTorsoPx! / 100.0;
        return ghostAnchorY! + rawY * scale;
      }
      return rawY;
    }

    final first = points.first;
    path.moveTo(
      _tx(applyX(first.x), canvasSize),
      _ty(applyY(first.y), canvasSize),
    );

    for (int i = 1; i < points.length; i++) {
      path.lineTo(
        _tx(applyX(points[i].x), canvasSize),
        _ty(applyY(points[i].y), canvasSize),
      );
    }

    path.close();
    return path;
  }

  /// Translate ML Kit X coordinate to canvas X pixel.
  /// Mirrors horizontally only for live user silhouette on front camera.
  /// Target ghost (mirrorMode.unmirrored) is never flipped here.
  double _tx(double x, Size canvasSize) {
    if (sensorRotation == 90 || sensorRotation == 270) {
      if (mirrorMode == CameraMirrorMode.mirrored) {
        // Front camera: mirror X so live body matches the preview
        return canvasSize.width - (x * canvasSize.width / imageSize.height);
      } else {
        // Rear camera / target ghost: no flip
        return x * canvasSize.width / imageSize.height;
      }
    }
    return x * canvasSize.width / imageSize.width;
  }

  /// Translate ML Kit Y coordinate to canvas Y pixel.
  double _ty(double y, Size canvasSize) {
    if (sensorRotation == 90 || sensorRotation == 270) {
      return y * canvasSize.height / imageSize.width;
    }
    return y * canvasSize.height / imageSize.height;
  }

  /// ── Phase 3: Curvature-Aware Selective Smoothing ─────────────────────────
  /// Detects sharp internal creases (e.g., armpits, inner elbows, neck base)
  /// and applies mathematical Laplacian smoothing ONLY to the corners.
  /// Flat areas (forearms, thighs) are left 100% untouched to preserve anatomy.
  ui.Path _smoothCorners(ui.Path rawPath) {
    final outPath = ui.Path();
    final metrics = rawPath.computeMetrics();
    
    for (final metric in metrics) {
      if (metric.length == 0) continue;
      
      const double step = 5.0; // Restored to 5.0 for high fidelity (CSG caching fixes the frame lag!)
      final List<ui.Offset> points = [];
      for (double d = 0.0; d < metric.length; d += step) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) points.add(tangent.position);
      }
      
      if (points.length < 10) continue;

      final smoothed = List<ui.Offset>.from(points);
      // Run 2 iterations instead of 4 to keep 60fps performance high
      for (int iter = 0; iter < 2; iter++) {
        final temp = List<ui.Offset>.from(smoothed);
        for (int i = 0; i < smoothed.length; i++) {
          // Look 2 points ahead and behind to calculate the local curve angle
          final pPrev = smoothed[(i - 2 + smoothed.length) % smoothed.length];
          final pCurr = smoothed[i];
          final pNext = smoothed[(i + 2) % smoothed.length];

          final v1x = pPrev.dx - pCurr.dx;
          final v1y = pPrev.dy - pCurr.dy;
          final len1 = math.sqrt(v1x * v1x + v1y * v1y);

          final v2x = pNext.dx - pCurr.dx;
          final v2y = pNext.dy - pCurr.dy;
          final len2 = math.sqrt(v2x * v2x + v2y * v2y);

          if (len1 < 1e-3 || len2 < 1e-3) continue;

          final dot = (v1x * v2x + v1y * v2y) / (len1 * len2);
          final angle = math.acos(dot.clamp(-1.0, 1.0));
          final angleDeg = angle * 180.0 / math.pi;

          // If the angle is less than 150 degrees, it is a crease/corner.
          // 180 degrees is a perfectly flat line.
          if (angleDeg < 150.0) {
            // The sharper the corner, the stronger the smoothing intensity
            final intensity = ((150.0 - angleDeg) / 150.0).clamp(0.0, 0.6);
            
            // Move point towards the average of its immediate neighbors
            final immPrev = smoothed[(i - 1 + smoothed.length) % smoothed.length];
            final immNext = smoothed[(i + 1) % smoothed.length];
            final midX = (immPrev.dx + immNext.dx) / 2.0;
            final midY = (immPrev.dy + immNext.dy) / 2.0;

            temp[i] = ui.Offset(
              pCurr.dx + (midX - pCurr.dx) * intensity,
              pCurr.dy + (midY - pCurr.dy) * intensity,
            );
          }
        }
        for (int i = 0; i < smoothed.length; i++) smoothed[i] = temp[i];
      }

      outPath.moveTo(smoothed.first.dx, smoothed.first.dy);
      for (int i = 1; i < smoothed.length; i++) {
        outPath.lineTo(smoothed[i].dx, smoothed[i].dy);
      }
      outPath.close();
    }
    return outPath;
  }

  /// ── Stylization: Doodle Animation Algorithm ────────────────────────────
  /// Converts a smooth path into a hand-drawn wavy marker path.
  /// Animates over time using Sine wave noise along the path normals.
  ui.Path _stylizePathToDoodle(ui.Path smoothPath) {
    final outPath = ui.Path();
    final metrics = smoothPath.computeMetrics();
    // Time variable creates the frame-by-frame stop-motion animation effect
    final time = DateTime.now().millisecondsSinceEpoch / 150.0; 
    
    for (final metric in metrics) {
      if (metric.length == 0) continue;
      
      const double step = 12.0; // Distance between noise samples
      bool first = true;
      for (double d = 0.0; d < metric.length; d += step) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent == null) continue;
        
        final pos = tangent.position;
        final vec = tangent.vector; // normalized tangent vector
        
        // Calculate normal vector (perpendicular to tangent pointing outward)
        final nx = -vec.dy;
        final ny = vec.dx;
        
        // Math: Add multiple sine waves with different frequencies and offsets
        final noise = math.sin(d * 0.12 + time) * 3.5 + 
                      math.sin(d * 0.04 - time) * 5.0;
        
        final px = pos.dx + nx * noise;
        final py = pos.dy + ny * noise;
        
        if (first) {
          outPath.moveTo(px, py);
          first = false;
        } else {
          outPath.lineTo(px, py);
        }
      }
      outPath.close();
    }
    return outPath;
  }

  @override
  bool shouldRepaint(covariant SilhouettePainter old) {
    return old.result != result ||
        old.appState != appState ||
        old.guidanceSignal != guidanceSignal ||
        old.mirrorMode != mirrorMode ||
        old.ghostAnchorX != ghostAnchorX ||
        old.ghostAnchorY != ghostAnchorY ||
        old.ghostTorsoPx != ghostTorsoPx;
  }

  // ── Engine 7 Priority 1: Outline Shift ──────────────────────────────────────
  /// Applies a gentle translation to the silhouette path in the direction of
  /// the correction vector from [guidanceSignal].
  ///
  /// Max shift = 20 screen pixels. This "feedforward" technique (HCI research,
  /// Casiez et al. 2014) lets the user instinctively "step inside the glowing shape."
  ///
  /// When [guidanceSignal] is null or posture is acceptable, the path is
  /// returned unchanged.
  ui.Path _applyGuidanceShift(ui.Path path, Size canvasSize) {
    final signal = guidanceSignal;
    if (signal == null || signal.isPostureAcceptable) return path;

    // Scale the normalized correction vector to screen pixels.
    // Clamp to ±1.0 on each axis then scale to max 20px.
    const double maxShiftPx = 20.0;
    final double shiftX = signal.correctionDx.clamp(-1.0, 1.0) * maxShiftPx;
    final double shiftY = signal.correctionDy.clamp(-1.0, 1.0) * maxShiftPx;

    // Build a column-major 4x4 translation matrix.
    final matrix = Float64List(16);
    matrix[0]  = 1.0;
    matrix[5]  = 1.0;
    matrix[10] = 1.0;
    matrix[15] = 1.0;
    matrix[12] = shiftX;
    matrix[13] = shiftY;

    return path.transform(matrix);
  }
}
