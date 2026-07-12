import 'dart:typed_data' show Float64List;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../silhouette/silhouette_engine.dart';
import '../silhouette/vec2.dart';
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

  final Paint _fill;    // subtle body fill — gives silhouette its "solid" feel
  final Paint _glow3;
  final Paint _glow2;
  final Paint _coreLine;

  SilhouettePainter({
    required this.result,
    required this.imageSize,
    required this.sensorRotation,
  })  : _fill = Paint()
          ..color = Colors.white.withOpacity(0.04)
          ..style = PaintingStyle.fill,
        _glow3 = Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 36.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22.0),
        _glow2 = Paint()
          ..color = Colors.white.withOpacity(0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0),
        _coreLine = Paint()
          ..color = Colors.white.withOpacity(0.92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    if (!result.isValid) return;

    // ── v2 CSG path (pre-merged by CsgExtractor) — use directly ────────────
    if (result.csgPath != null) {
      var basePath = _transformCsgPath(result.csgPath!, size);
      
      // Apply Curvature-Aware Selective Smoothing (Phase 3: Corner rendering)
      basePath = _smoothCorners(basePath);
      
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

    canvas.drawPath(basePath, _fill);
    canvas.drawPath(basePath, _glow3);
    canvas.drawPath(basePath, _glow2);
    canvas.drawPath(basePath, _coreLine);
  }

  /// [v2 CSG] Applies the same coordinate transform as _buildPath() but via
  /// matrix transformation on the pre-built CSG path.
  ///
  /// The CSG path is in ML Kit raw pixel space. We need to map it to canvas
  /// coordinates using the same _tx / _ty logic.
  ui.Path _transformCsgPath(ui.Path csgPath, Size canvasSize) {
    double sx, sy, tx, ty;

    if (sensorRotation == 90 || sensorRotation == 270) {
      // Rotated sensor: image width maps to canvas height, height to width.
      // x_canvas = canvasWidth  - x_image * (canvasWidth  / imageHeight)
      // y_canvas =               y_image * (canvasHeight / imageWidth)
      sx = -canvasSize.width  / imageSize.height;  // negative = mirror X
      sy =  canvasSize.height / imageSize.width;
      tx =  canvasSize.width;                       // horizontal flip offset
      ty =  0;
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

    return csgPath.transform(matrix);
  }

  /// Converts [Vec2] points (in ML Kit raw pixel space) to a closed Flutter [Path]
  /// mapped to canvas coordinates.
  ui.Path? _buildPath(List<Vec2> points, Size canvasSize) {
    if (points.isEmpty) return null;

    final path = ui.Path();
    final first = points.first;
    path.moveTo(
      _tx(first.x, canvasSize),
      _ty(first.y, canvasSize),
    );

    for (int i = 1; i < points.length; i++) {
      path.lineTo(
        _tx(points[i].x, canvasSize),
        _ty(points[i].y, canvasSize),
      );
    }

    path.close();
    return path;
  }

  /// Translate ML Kit X coordinate to canvas X pixel.
  /// Mirrors horizontally for front camera (sensor rotation 270° or 90°).
  double _tx(double x, Size canvasSize) {
    if (sensorRotation == 90 || sensorRotation == 270) {
      // Image is rotated: image width maps to canvas height, image height to canvas width
      return canvasSize.width - (x * canvasSize.width / imageSize.height);
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
      
      const double step = 15.0; // Increased from 5.0 to 15.0 to drastically reduce native Skia calls and fix frame lag
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
    return true; // Always repaint because the doodle noise is animated over time
  }
}
