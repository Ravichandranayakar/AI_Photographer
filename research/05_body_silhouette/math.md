# Math Reference: Topic 5 — Body Silhouette Generation

**Version:** v1.3 (Locked — matches implementation_plan.md)

---

## Pre-Stage: Confidence Gate

Remove any joint where MediaPipe confidence `c < 0.5` before topology begins.
Low-confidence joints output invalid or identical coordinates that corrupt the hull.

---

## Stage 1: Topology Router

Clockwise perimeter order forming a single closed loop:

```
Nose (CAP) → Left Ear → Left Shoulder → Left Elbow (HINGE) → Left Wrist (CAP)
  → Left Wrist Inner → Left Elbow Inner (HINGE) → Left Axilla (HINGE) → Left Hip
  → Left Knee (HINGE) → Left Ankle (CAP)
  → Crotch Anchor (SYNTHETIC)
  → Right Ankle (CAP) → Right Knee (HINGE) → Right Hip
  → Right Axilla (HINGE) → Right Elbow Inner (HINGE) → Right Wrist Inner
  → Right Wrist (CAP) → Right Elbow Outer (HINGE) → Right Shoulder → Right Ear
  → CLOSE LOOP
```

Joint classifications:
- **Standard** → Phase A Steps 1–4 (normal offset)
- **HINGE** → Phase A Step 5 (angle bisector)
- **CAP** → Phase A Step 6 (axial extrusion)
- **SYNTHETIC** → Computed geometric point, not a MediaPipe landmark

---

## Stage 2: Kinematic Expansion (Phase A)

### Step 1: Bone Direction Vector
$$\vec{u} = P_2 - P_1 = \begin{bmatrix} x_2 - x_1 \\ y_2 - y_1 \end{bmatrix}$$

### Step 2: Normalize (with ε-guard)
$$\|\vec{u}\| = \sqrt{(x_2-x_1)^2 + (y_2-y_1)^2}$$

**If `‖u‖ < ε = 1e-6`:** Skip edge, reuse previous valid normal.

$$\hat{u} = \frac{\vec{u}}{\|\vec{u}\|}$$

### Step 3: Perpendicular Normal
$$\hat{n} = \begin{bmatrix} -\hat{u}_y \\ \hat{u}_x \end{bmatrix}$$

**Orientation Rule:** Verify normals point outward on first prototype run.
If inward-facing: flip sign → $\hat{n} = \begin{bmatrix} \hat{u}_y \\ -\hat{u}_x \end{bmatrix}$

### Step 4: Radius Offset with Linear Interpolation

Interpolate radius smoothly along bone (prevents hard width steps):
$$r(t) = (1 - t) \cdot r_1 + t \cdot r_2, \quad t \in [0, 1]$$

Boundary points:
$$P'_{left}(t) = P(t) + r(t) \cdot \hat{n} \cdot \text{scaleFactor}$$
$$P'_{right}(t) = P(t) - r(t) \cdot \hat{n} \cdot \text{scaleFactor}$$

### Step 5: Angle Bisector at Hinge Joints

At elbow, knee, axilla — where two bones meet at an angle:

$$\hat{n}_{hinge} = \text{normalize}\!\left(\hat{n}_{in} + \hat{n}_{out}\right)$$

$$P_{hinge\_outer} = P_{hinge} + r_{hinge} \cdot \hat{n}_{hinge} \cdot \text{scaleFactor}$$

Produces exactly one outer point at the hinge, keeping the hull as a single unbroken loop.

### Step 6: Axial Extrusion at Cap Joints

At wrist, foot, nose — push forward along bone direction instead of sideways:

$$P_{cap} = P_{joint} + \hat{u}_{bone} \cdot r_{cap} \cdot \text{scaleFactor}$$

| Cap Joint | Push Direction | Effect |
|-----------|---------------|--------|
| Nose | −Y (upward in screen coords) | Closes top of head |
| Left/Right Wrist | Along forearm direction | Extends past wrist for hand cap |
| Left/Right Foot | Along shin/ankle direction (downward) | Closes toe region |

### Scale Factor

$$\text{scaleFactor} = \frac{\text{torso\_px}}{\text{referenceTorsoLength}}$$

- `torso_px`: computed by `LandmarkNormalizer` on every frame
- `referenceTorsoLength`: configurable, default `200.0` px

### Synthetic Crotch Anchor

$$P_{crotch} = \text{midpoint}(P_{leftHip}, P_{rightHip}) + \begin{bmatrix} 0 \\ r_{crotch} \cdot \text{scaleFactor} \end{bmatrix}$$

(Positive Y = downward in screen coordinates → pushes anchor toward knees to separate inner thighs)

---

## Stage 3: Chaikin Subdivision (Phase B)

For each consecutive edge $(v_k, v_{k+1})$ in the closed hull loop:

$$q_k = \frac{3}{4} v_k + \frac{1}{4} v_{k+1}$$
$$r_k = \frac{1}{4} v_k + \frac{3}{4} v_{k+1}$$

| Iterations | Points (from N input) |
|-----------|----------------------|
| 0 (raw hull) | N |
| 1 | 2N |
| 2 | 4N |
| 3 | 8N |
| 4 | 16N |

Convergence: As iterations → ∞, converges to quadratic B-Spline. At 3–4 iterations, visually indistinguishable from the limit curve.

**Chaikin preserves the convex hull of the control polygon**, greatly reducing self-intersection risk. The outline can still self-intersect if the input hull is invalid — hence the Confidence Gate and Bisector steps are critical prerequisites.

---

# Engine B � Capsule + Offset Curves

> **Research question:** Can capsules approximate the human body?

---

## Core Concept

Every bone becomes a capsule (a line segment with a radius).
The outline is the outer surface of all capsule unions.

Unlike Engine A (which traces joints in a fixed order), Engine B
asks: which pixels are on the outer surface of all capsules combined?

---

## Equation B1: Capsule Closest Point

For a capsule defined by segment A?B, the closest point on the
segment to any image point P is:

```
t  = clamp( dot(P - A, B - A) / |B - A|^2 ,  0, 1 )
Q  = A + t * (B - A)
```

The shortest distance from P to the capsule skeleton is:

```
d_i(P) = |P - Q|
```

P is INSIDE capsule i if d_i(P) < r_i.

---

## Equation B2: Adaptive Base Radius

The capsule radius adapts to camera distance (torso scale) and
joint confidence:

```
Phase 1 (distance only):
  r_i = r_base * S

Phase 2 (confidence-gated):
  r_i = r_base * S * C_i
```

Where:
  r_base = anatomical radius (bone-specific constant)
  S      = torsoPx / referenceTorsoLength    (camera distance)
  C_i    = average confidence of the two endpoint joints

Effect: when ML Kit confidence drops (arm behind back), the
capsule SHRINKS instead of exploding to a random position.
This prevents garbage rendering for partially detected poses.

---

## Equation B3: Angle-Aware Thickness

Human bodies are not constant width. A bent elbow appears wider
in 2D than a straight arm. Introduce angle-dependent thickness:

```
r_i' = r_i * (1 + k * (1 - cos(theta_i)))
```

Where:
  theta_i = joint angle at the connecting joint
           = arccos( dot( normalize(B-A), normalize(C-B) ) )
  k       = tuning coefficient, start at 0.3

Values:
  theta = 0   (straight limb)  : r_i' = r_i            (no change)
  theta = pi/2 (90 deg bend)   : r_i' = r_i * (1 + k)  = 1.3 * r_i
  theta = pi   (fully folded)  : r_i' = r_i * (1 + 2k) = 1.6 * r_i

Anatomical basis: a bent limb projects more width onto the camera plane.

---

## Equation B4: Waist Correction

The convex hull always destroys the waist indentation.
Add a local contraction at the center torso capsule:

```
r_waist = r_torso * (1 - lambda)
```

Where:
  lambda = narrowing coefficient, start at 0.15
  Range:  0 < lambda < 0.3

This applies ONLY to the center torso capsule (mid-shoulder to mid-hip).
The side torso capsules retain full r_torso to define the lateral boundary.

Note: This narrowing only becomes visible in Engine C (field-based contour).
In the convex hull approach it has minimal effect.

---

## Equation B5: Capsule Boundary Points (Stadium Shape)

For capsule from A to B with radius r and unit direction e = (B-A)/|B-A|,
left normal n = (-e.y, e.x):

Right semicircle at B (phi from -pi/2 to pi/2):
```
P = B + r * (cos(phi) * e.x - sin(phi) * e.y,
             cos(phi) * e.y + sin(phi) * e.x)
```

Left semicircle at A (phi from pi/2 to 3*pi/2):
```
P = A + r * (cos(phi) * e.x - sin(phi) * e.y,
             cos(phi) * e.y + sin(phi) * e.x)
```

Together these trace the complete perimeter of the stadium shape.

---

## Equation B6: Outer Surface Extraction

A boundary point P from capsule i is on the TRUE OUTER SURFACE
if and only if it is NOT inside any other capsule j:

```
P is outer surface iff:  d_j(P) >= r_j   for all j != i
```

Due to discrete sampling, use a small buffer (epsilon = 0.97):
```
P is outer surface iff:  d_j(P) >= r_j * 0.97   for all j != i
```

This correctly identifies points where only one capsule contributes
to the body surface at that location.

---

## Pipeline: Engine B

```
Smoothed Raw Pixel Landmarks (1 Euro Filter output)
        |
        v
CapsuleBody.build()   -- 17 capsules with adaptive radii (B2, B3, B4)
        |
        v
Generate boundary points for each capsule (B5)
        |
        v
Filter: keep only outer surface points (B6)
        |
        v
Sort by angle from body centroid
        |
        v
Bin by angle (72 bins = 5deg each), keep outermost in each bin
        |
        v
ChaikinEngine.subdivide (2 iterations)
        |
        v
SilhouettePainter (same as Engine A)
```

Key difference from Engine A:
  Engine A: hardcoded 22-entry traversal order (breaks on non-canonical poses)
  Engine B: pose-independent field surface extraction (works for any pose)

---

# Engine C � Implicit Body Field
## (Equations documented separately after Engine B benchmark)

Engine C uses a CONTINUOUS MATHEMATICAL FIELD instead of discrete geometry.

## Equation C1: Gaussian Field per Capsule

```
F_i(P) = w_i * exp( -d_i(P)^2 / (2 * sigma_i^2) )
```

Where:
  d_i(P)   = capsule distance from Equation B1
  sigma_i  = adaptive radius from Equation B2 (same as Engine B)
  w_i      = anatomical weight (torso=1.0, arm=0.7, leg=0.8)

## Equation C2: Total Field Accumulation

```
F(P) = sum over all i: F_i(P)
```

## Equation C3: Iso-Contour Extraction

Choose threshold T (start at 0.5). The outline is:
```
F(x, y) = T
```

Computed via Marching Squares algorithm on a 64x96 grid.

## Equation C4: Inverse Quadratic Field (Alternative to Gaussian)

```
F_i(P) = w_i / (1 + (d_i(P) / sigma_i)^2)
```

Gaussian decays quickly (thin joins between limbs).
Inverse quadratic decays slowly (smoother shoulder/hip joins).
Benchmark BOTH before choosing.

## Equation C5: Shoulder Blending

Blend neighboring capsule fields to prevent triangular corners:
```
F_shoulder = F_neck + F_torso + F_upper_arm
```

These are naturally blended in Engine C because all capsule fields
add together � no explicit blending code is needed.
