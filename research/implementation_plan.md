# Engine B — Contour Extraction Research Plan
## v2 (CSG / Regularized Union) + v3 (Marching Squares)

> **Status:** APPROVED — ready to implement  
> **Reviewer verdict:** Research 9.8/10 | Architecture 9.7/10 | Math 9.4/10 | Build order 10/10  
> **Principle:** Keep the Capsule skeleton unchanged. Only the Contour Extractor changes.

---

## What the Research Confirmed

### The Polar Binning Wall (v1 — proven dead)
Polar Binning only works on **star-shaped polygons**.  
A human body is NOT star-shaped. Therefore:
- Arms at sides → permanently invisible (torso shadows the arm ray)
- No tuning of `_eps`, `_nBins`, or radii will ever fix this
- **v1 is officially frozen as the baseline**

### What to build instead

| Algorithm | Research Source | Solves |
|---|---|---|
| **Capsule CSG** (Regularized Union) | Requicha & Voelcker (1977) | Arms at sides, thigh gap |
| **Gaussian Body Field + Marching Squares** | Lorensen & Cline (1987), Metaball lit. | All poses, organic blending |

---

## Architecture

```
lib/engine/silhouette_b/
    capsule.dart                  ← [UNCHANGED] Pure math primitive
    capsule_body.dart             ← [SMALL CHANGE] Add groin bridge + A_i term

    contour/
        v1_polar/
            capsule_outline.dart  ← [FROZEN] Polar extractor (baseline)

        v2_csg/                   ← [NEW] Build first (renamed from boolean_union)
            capsule_path_ext.dart  ← toFlutterPath() extension, keeps capsule.dart pure
            csg_extractor.dart     ← Path.combine fold — the CSG engine

        v3_marching_squares/      ← [NEW] Build after v2 is benchmarked
            body_field.dart        ← Gaussian field evaluator (F = Σ w_i · G_i)
            marching_squares.dart  ← Contour + Asymptotic Decider

    engine_b.dart                 ← [MODIFY] Single flag switches extractor version
```

> **Why `v2_csg` not `v2_boolean_union`?**  
> The folder holds a CSG extractor. Tomorrow we may use Union, Difference, or Intersection  
> without renaming anything. Boolean Union is just the first operation we test.

---

## Updated Radius Equation (Applied to ALL versions)

### Change 1: Reviewer addition — Anatomical Scaling Term `A_i`

Previous equation:
$$r_i = r_{base,i} \cdot S \cdot C_i \cdot (1 + k(1 - \cos\theta_i))$$

**Updated equation:**
$$r_i = r_{base,i} \cdot S \cdot C_i \cdot A_i \cdot (1 + k(1 - \cos\theta_i))$$

where $A_i$ is the **anatomical scaling factor** — a per-bone multiplier that reflects real human body proportions independently of the torso reference scale.

| Bone | $A_i$ |
|---|---|
| `torso` (shoulder→hip) | 1.00 |
| `shoulder span` | 0.95 |
| `hip span` | 0.90 |
| `upperArm` (shoulder→elbow) | 0.85 |
| `forearm` (elbow→wrist) | 0.70 |
| `upperLeg` (hip→knee) | 1.00 |
| `lowerLeg` (knee→ankle) | 0.80 |
| `head` | 1.10 |
| `neck` | 0.55 |
| `groinBridge` (midHip→midKnee) | 0.75 |

These are **independently tunable** for each bone, unlike the current system where all bones scale together. This is the same approach used in professional animation rigs.

---

## Engine B v2 — CSG / Regularized Union

### Mathematical Foundation

The correct operation (Requicha, 1977) is the **regularized union**:

$$S = C_1 \cup^* C_2 \cup^* \ldots \cup^* C_n = \text{cl}(\text{int}(C_1 \cup C_2 \cup \ldots \cup C_n))$$

Each capsule $C_i$ is the **Minkowski sum** (research Section 2.3):

$$C_i = L_i \oplus B(r_i)$$

where $L_i$ is the bone line segment and $B(r_i)$ is a disk of radius $r_i$.

The outline = the perimeter of $S$.

### Why this fixes arms at sides

When the arm capsule touches the torso capsule, they **merge into one shape**.  
No centroid. No rays. No shadows. The outer boundary is mathematically exact.

### Implementation steps (`csg_extractor.dart`)

```
1. Receive List<Capsule> from CapsuleBody.build()
2. For each capsule: call capsule.toFlutterPath() [from capsule_path_ext.dart]
3. Fold: body = capsules.fold(Path(), (acc, c) =>
             Path.combine(PathOperation.union, acc, c.toFlutterPath()))
4. Return body — a single merged Flutter Path with the outer boundary only
5. Painter strokes: paint..style = PaintingStyle.stroke
   Skia automatically gives us the outer contour (no interior lines)
```

### `capsule_path_ext.dart` — Math specification

```
Given capsule (A, B, r):
  1. Compute axis direction: e = normalize(B - A)
  2. Compute perpendicular offset: n = (-e.y, e.x) * r
  3. Four rectangle corners:
       topLeft  = A + n,  topRight  = B + n
       botRight = B - n,  botLeft   = A - n
  4. Path.moveTo(topLeft)
     Path.lineTo(topRight)
     Path.arcTo(center=B, radius=r, from 90° rotated, sweep π)
     Path.lineTo(botLeft)
     Path.arcTo(center=A, radius=r, from 270° rotated, sweep π)
     Path.close()
```

### Expected v2 vs v1

| Failure case | v1 Polar | v2 CSG |
|---|---|---|
| Arms at sides | ❌ Invisible | ✅ Merged, visible edge |
| Inner thigh gap | ❌ 20.5px hole | ✅ Groin bridge capsule fills it |
| Far distance | ❌ Collapses to stick | ✅ 8px floor prevents collapse |
| Sitting disconnected blobs | ❌ Fragments | ✅ Each capsule is self-contained |
| Smoothness | ⚠️ Jagged bins | ✅ Mathematically smooth (Skia) |
| Arm/torso junction | n/a | ⚠️ Hard seam (visible join line) |

---

## Engine B v3 — Marching Squares

> **Build only after v2 is benchmarked and failure cases identified.**

### Mathematical Foundation

#### Stage 1: Gaussian Body Field (abstracted for extensibility)

### Change 2: Reviewer addition — `G_i(P)` kernel abstraction

$$F(P) = \sum_{i=1}^{N} w_i \cdot G_i(P)$$

where $G_i(P)$ is the **kernel function**. Currently:

$$G_i(P) = \exp\!\left(-\frac{d_i(P)^2}{2\sigma_i^2}\right) \quad \text{(Gaussian)}$$

By abstracting to $G_i(P)$, tomorrow we can swap in:
- `Polynomial kernel` — faster, no exp() call
- `Wyvill blobby kernel` — classic metaball
- `SDF-based kernel` — for Engine C
- `R-function kernel` — for analytical CSG blending

Without changing the field evaluator or marching squares code at all.

**Field parameters:**
- $\sigma_i = r_i$ (the adaptive radius IS the field width — no new tuning required)
- $w_i$ = anatomical weight (already in `capsule.dart` as `weight` field)
- Threshold $T = 0.3$ (starting point; adjustable per-frame)

#### Stage 2: Marching Squares Contour Extraction

From research (Section 4.1):
- Grid: **64 × 128** cells over the camera preview
- Each cell: 4 corners → evaluate $F(P)$ → 4-bit index (0–15)
- Lookup table → edge configuration → connect midpoints → contour segment
- **Asymptotic Decider** (Nielson & Hamann, 1991) for cases 5 and 10 (saddle points)
- Apply Chaikin smoothing to the extracted polygon segments

#### Performance estimate

| Step | Cost |
|---|---|
| Field evaluation | 64×128×4 corners × 17 capsules = ~557K ops |
| Marching squares | 8,192 table lookups |
| Chaikin (2 passes) | ~200 point ops |
| **Total** | **~16ms** at 30fps budget (33ms) ✅ |

### Why v3 is better than v2

| Feature | v2 CSG | v3 Marching Squares |
|---|---|---|
| Arm/torso junction | Hard seam | **Organic smooth merge** |
| Leg separation | Cannot show gap | **Can show leg gap** |
| Thickness control | Fixed | **Adjustable via threshold T** |
| Sitting pose | Good | **Best** |
| Self-occlusion (Test 9) | ⚠️ Unknown | ✅ Fields add naturally |

---

## 9-Test Benchmark Suite

> **Change 3: Reviewer addition — Test 9 (Self-Occlusion)**

| # | Test | Key challenge |
|---|---|---|
| T1 | T-Pose (arms horizontal) | Arm tip spikes |
| T2 | A-Pose (arms at sides) | Polar shadow — arm invisible |
| T3 | Arms crossed at chest | Torso/forearm overlap |
| T4 | Hands on hips | Concave armpit gap |
| T5 | One leg raised | Asymmetric lower body |
| T6 | Wide stance (legs apart) | Inner thigh gap |
| T7 | Side profile | Thin projection, depth loss |
| T8 | Fast jumping jack | Motion blur, latency |
| **T9** | **Self-occlusion (arms crossed tightly, lean forward)** | **Shoulder/forearm/torso all intersecting — hardest CSG case** |

---

## Build Order (Approved)

```
Phase 0 — Groin Bridge [1 change to capsule_body.dart]
  Quick win: adds midHip→midKnee capsule with A_i=0.75
  Benefits v1, v2, and v3 immediately

Phase 1 — v2 CSG [2 new files]
  capsule_path_ext.dart
  csg_extractor.dart
  Wire into engine_b.dart → test all 9 poses → benchmark

Phase 2 — v2 Failure Analysis [data, not code]
  For each failure: record in open_questions.md
  Research the math for that specific failure

Phase 3 — v3 Marching Squares [3 new files]
  body_field.dart + G_i(P) kernel interface
  marching_squares.dart + Asymptotic Decider
  Wire into engine_b.dart (behind version flag)

Phase 4 — Final Benchmark [v1 vs v2 vs v3]
  Same 9 tests, same conditions
  Winner becomes production silhouette engine
```

---

## Research Cycle (Every Iteration)

```
Paper → Math → Prototype → Benchmark → Failure Analysis → Paper → ...
```

Not: "Internet says → implement."

Every failure goes to `open_questions.md` with:
- The visual symptom
- The geometric hypothesis  
- The research area to study
- The attempted fix
- The result

---

*Research source: Requicha & Voelcker (CSG), Marching Squares, Gaussian Metaballs, Asymptotic Decider*  
*Plan version: 3.0 — APPROVED | Updated: 2026-07-10 with all 4 reviewer changes*



------------------------------------------------------------------------------------

Topic 5

Engine A
    Polygon
    Hull
    Chaikin

Engine B
    Capsules
    Adaptive Radius
    Angle Radius
    Waist Correction
    Chaikin

Engine C
    Capsule Field
    Gaussian
    Inverse Quadratic
    Contour Extraction
    Chaikin