# Engine B - Capsule + Implicit Body Field
## STATUS: RESEARCH PHASE (2026-07-09)

---

## The Core Mathematical Idea

Instead of drawing a polygon around the body, we model the body as a
POTENTIAL FIELD. Every bone emits energy. The outline is the contour
where the total energy equals a threshold.

This is inspired by metaball / implicit surface techniques used in
computer graphics and robotics for representing articulated bodies.

---

## Mathematical Model: Frozen Body Field

### Step 1 — Capsule Representation

Every bone i is a line segment from joint A to joint B.

The shortest distance from any pixel point P to capsule i is:

  t = clamp( dot(P - A, B - A) / |B - A|^2 ,  0, 1 )
  closest = A + t * (B - A)
  d_i(P) = |P - closest|

This is the SIGNED DISTANCE to the capsule skeleton.

### Step 2 — Field Accumulation (Gaussian Falloff)

Each capsule contributes to a scalar field F at every pixel P:

  F_i(P) = w_i * exp( -d_i(P)^2 / (2 * sigma_i^2) )

Where:
  d_i(P)   = capsule distance (from Step 1)
  sigma_i  = anatomical thickness for this bone (scaled by torsoPx)
  w_i      = anatomical weight for this bone (torso=1.0, arm=0.7, leg=0.8)

Total field:
  F(P) = sum_i( F_i(P) )

### Step 3 — Adaptive Radius

The field radius is NOT fixed. It adapts to:
  sigma_i = r_i * S * C_i

Where:
  r_i  = anatomical radius (same registry as Engine A)
  S    = torsoPx / referenceTorsoLength  (distance scaling)
  C_i  = ML Kit confidence of the joint  (if low, capsule shrinks)

This means: low confidence joints contribute less to the field.
No more garbage rendering when the camera points at the sky.

### Step 4 — Contour Extraction (Marching Squares)

We sample F(P) on a grid. The outline is the iso-contour where:
  F(x, y) = T   (threshold, tunable, start at 0.5)

We use the Marching Squares algorithm to trace this contour.
The result is a list of (x, y) pixel points forming the body outline.

This is fundamentally different from Engine A. Instead of:
  "Walk around the body joints in order"
We do:
  "Find all pixels where the body field = T"

### Step 5 — Chaikin Smoothing (same as Engine A)

The Marching Squares contour has staircase artifacts.
One pass of Chaikin smooths it to a clean organic curve.

---

## Bone Capsule Registry (17 capsules)

| Index | Bone               | Joints              | r_i   | w_i |
|-------|--------------------|---------------------|-------|-----|
| 0     | Neck               | nose - mid_shoulder | 18.0  | 0.9 |
| 1     | Left upper arm     | L_shoulder - L_elbow | 14.0 | 0.7 |
| 2     | Right upper arm    | R_shoulder - R_elbow | 14.0 | 0.7 |
| 3     | Left forearm       | L_elbow - L_wrist   | 10.0  | 0.7 |
| 4     | Right forearm      | R_elbow - R_wrist   | 10.0  | 0.7 |
| 5     | Torso left         | L_shoulder - L_hip  | 22.0  | 1.0 |
| 6     | Torso right        | R_shoulder - R_hip  | 22.0  | 1.0 |
| 7     | Torso center       | mid_shoulder - mid_hip | 20.0 | 1.0 |
| 8     | Left upper leg     | L_hip - L_knee      | 16.0  | 0.8 |
| 9     | Right upper leg    | R_hip - R_knee      | 16.0  | 0.8 |
| 10    | Left lower leg     | L_knee - L_ankle    | 12.0  | 0.8 |
| 11    | Right lower leg    | R_knee - R_ankle    | 12.0  | 0.8 |
| 12    | Left foot          | L_ankle - L_foot    | 9.0   | 0.6 |
| 13    | Right foot         | R_ankle - R_foot    | 9.0   | 0.6 |
| 14    | Shoulder span      | L_shoulder - R_shoulder | 24.0 | 1.0 |
| 15    | Hip span           | L_hip - R_hip       | 22.0  | 1.0 |
| 16    | Head               | nose (sphere)       | 24.0  | 1.0 |

---

## Why This Solves Engine A Problems

Problem                          | Engine A             | Engine B
---------------------------------|----------------------|-----------------------------
Self-intersecting polygon        | Always               | Impossible (no polygon)
Cap direction bug                | Yes (wrist crash)    | No caps needed
Non-canonical pose               | Hardcoded topology   | Field adapts to any pose
Low confidence = garbage render  | Yes                  | Low C_i shrinks capsule
Arms/legs crossing               | Infinity loop        | Field blends naturally
Shoulder triangular corner       | Yes (hinge artifact) | Smooth blending in field

---

## Implementation Plan

### Files to Create

research/05_body_silhouette/engine_b_capsule/
  capsule.dart          -- CapsulePoint struct + distance math
  body_field.dart       -- Field accumulation F(P)
  marching_squares.dart -- Contour extraction from grid
  engine_b.dart         -- Top-level orchestrator
  engine_b_evaluator.dart -- Benchmark against same 63-frame JSONL

### Grid Resolution Decision

The grid samples F(P) at resolution W x H pixels.
This determines quality vs speed trade-off.

Start at: 64x96 grid (portrait aspect)
If too slow: 48x72
If too fast and quality is good: 80x120

At 64x96:
  - 6144 pixels to evaluate
  - Each pixel: 17 capsule distance calculations
  - Total operations per frame: 104,448

On a modern mobile CPU: ~1-2ms per frame.
Target: under 8ms (to stay within 60fps budget with pose detection).

### Threshold Tuning

Start at T = 0.3
If outline too fat: increase T
If outline too thin: decrease T
Range: 0.1 to 0.8

---

## Prototype Benchmark Checklist

Same 8 tests as Engine A:

- [ ] Test 1: Arms Crossed
- [ ] Test 2: Hands in Pockets
- [ ] Test 3: Sitting
- [ ] Test 4: Squat
- [ ] Test 5: Side Pose
- [ ] Test 6: One Arm Raised
- [ ] Test 7: Wide Stance
- [ ] Test 8: Walking

---

## Reference Papers

Blinn, J. F. (1982). A generalization of algebraic surface drawing.
  ACM Transactions on Graphics. (Original metaball paper)

Nishita, T. and Nakamae, E. (1994). A method for displaying metaballs
  by using bezier clipping. Computer Graphics Forum.

Turk, G. and O'Brien, J. (1999). Shape transformation using variational
  implicit functions. SIGGRAPH.

The Gaussian field formulation in this engine is an original adaptation
of these techniques to the 2D landmark problem. It is not copied from any paper.
