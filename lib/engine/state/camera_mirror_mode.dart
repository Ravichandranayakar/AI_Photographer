// ─────────────────────────────────────────────────────────────────────────────
// State Machine — Step 1
// File: camera_mirror_mode.dart
// Layer: Rendering contract — front vs rear camera coordinate alignment
//
// DESIGN PRINCIPLE (Q4 resolution from frozen_ai_state_machine.md):
//   Front cameras mirror the preview horizontally. ML Kit landmarks are
//   in un-mirrored camera space. Without correction, every guidance arrow
//   points the WRONG direction on front camera.
//
//   RULE: Engines 5 and 6 ALWAYS work in raw landmark space.
//         Only Engine 7 (renderers) flip coordinates at paint time.
// ─────────────────────────────────────────────────────────────────────────────

/// Defines how camera preview coordinates relate to ML Kit landmark space.
///
/// Create one instance per camera session based on the active lens direction.
/// Pass it into every Engine 7 renderer (SilhouettePainter, GuidanceArrowPainter).
///
/// Usage:
/// ```dart
/// final mirrorMode = lensDirection == CameraLensDirection.front
///     ? CameraMirrorMode.mirrored
///     : CameraMirrorMode.unmirrored;
/// ```
enum CameraMirrorMode {
  /// Front camera — preview is horizontally flipped relative to ML Kit space.
  /// Engine 7 must flip X: `screenX = frameWidth - rawLandmarkX`
  mirrored,

  /// Rear camera — no flip needed.
  /// Raw ML Kit landmark X maps directly to screen X.
  unmirrored,
}

/// Convenience helpers for resolving coordinates in Engine 7 renderers.
extension CameraMirrorModeX on CameraMirrorMode {
  /// Resolves a raw ML Kit landmark X coordinate to screen X.
  ///
  /// Apply this ONLY inside CustomPainter paint() methods.
  /// NEVER call this in Engine 5 or 6 math code.
  double resolveX(double rawLandmarkX, double frameWidth) {
    return this == CameraMirrorMode.mirrored
        ? frameWidth - rawLandmarkX
        : rawLandmarkX;
  }

  /// Flips a correction direction dx when in mirrored mode.
  ///
  /// When the camera is mirrored, "move right" in landmark space means
  /// the user sees an arrow pointing left. Flip the dx so the arrow
  /// always points in the direction the user perceives as correct.
  double resolveDirectionX(double dx) {
    return this == CameraMirrorMode.mirrored ? -dx : dx;
  }
}
