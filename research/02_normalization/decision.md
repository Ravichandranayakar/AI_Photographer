# Decision Record: 02 — Skeleton Normalization

**Status:** LOCKED
**Date:** 2026-07-08
**Implementation:** `lib/engine/normalizer/landmark_normalizer.dart`

---

## Problem Statement

ML Kit returns 33 landmarks as raw pixel coordinates relative to the camera frame.
Two people holding the exact same pose will produce completely different raw
coordinate values if they differ in height, distance from camera, or body proportions.
We cannot compare two raw coordinate sets directly.

## Candidates Evaluated

| Approach | Mechanism | Decision |
|---|---|---|
| **Bounding Box Scaling** | Scale by the pixel extent of the skeleton | ❌ Rejected |
| **Torso Length Scaling** | Scale by mid-hip to mid-shoulder distance | ✅ Locked |
| **Procrustes Analysis (full)** | SVD-based rotation + scale + translation | ⏳ Future (post-MVP) |

## Rejection: Bounding Box Scaling

**Fatal flaw:** The bounding box is defined by the extrema of all landmarks.
If a user raises their arms, the box expands. The math then falsely interprets the
skeleton as having shrunk, corrupting every normalized coordinate in the pipeline.
This is a catastrophic failure mode for a real-time pose coaching app.

## Selection: Mid-Hip Translation + Torso-Length Scaling

**Rationale:** The human torso (mid-shoulder to mid-hip) is the only segment
of the skeleton that remains geometrically rigid regardless of what the limbs
are doing. It changes only when the user physically moves closer to or further
from the camera.

## Locked Mathematics

**Anchors:**
```
mid_hip_x      = (left_hip.x + right_hip.x) / 2
mid_hip_y      = (left_hip.y + right_hip.y) / 2
mid_shoulder_x = (left_shoulder.x + right_shoulder.x) / 2
mid_shoulder_y = (left_shoulder.y + right_shoulder.y) / 2
```

**Scale Denominator (Torso Length S):**
```
S = √((mid_shoulder_x - mid_hip_x)² + (mid_shoulder_y - mid_hip_y)²)
```

**Normalized coordinates for every landmark i:**
```
X_normalized_i = (X_raw_i - mid_hip_x) / S
Y_normalized_i = (Y_raw_i - mid_hip_y) / S
```

## Note on Rotation Normalization

Full Procrustes Analysis also normalizes the rotation of the skeleton via SVD.
We deliberately DO NOT apply rotation normalization in this version.

**Reason:** If a user is supposed to be doing a pose with arms raised, and their arms
are at their sides, we want the system to register that as an error. Auto-rotating
the skeleton to match the target computationally would produce a false 100% score.
Rotation is an intentional signal, not noise.

## Guard Condition

If the computed torso length `S < 0.03` (screen-space units), normalization aborts
and returns `null`. This indicates the subject is not present or too far from the camera.
