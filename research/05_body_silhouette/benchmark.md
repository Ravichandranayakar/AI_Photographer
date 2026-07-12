# Benchmark Suite: Topic 5 — Body Silhouette Generation

**Status:** PENDING — Not yet executed
**Version:** v1.0
**Benchmark Method:** Real human, real-time camera. JSONL logs saved per test. Visual inspection on-screen.

---

## Pre-Benchmark Checklist

- [x] `geometry_evaluator.dart` Phase 1 passed (< 1.0 ms, no NaN/Infinity output)
- [ ] `SilhouetteEngine` integrated into camera stream
- [ ] `SilhouettePainter` rendering on device

---

## Phase 1 Geometry Evaluator Results (2026-07-09)

**Script:** `research/05_body_silhouette/geometry_evaluator.dart`
**Input data:** 63 real landmark frames from `test_4_1`, `test_4_5`, `test_4_7` JSONL logs

| Metric | Target | Result | Status |
|--------|--------|--------|--------|
| Valid joints (confidence ≥ 0.5) | All present | 33 / 33 | ✅ |
| Hull vertices (Phase A output) | ~14 (13 topology + 1 synthetic) | 14 | ✅ |
| Final path points (3 iterations) | 14 × 8 = 112 | 112 | ✅ |
| NaN / Infinity in output | 0 | 0 | ✅ |
| Execution time (4 Chaikin iterations) | < 1.0 ms | **0.0112 ms** | ✅ |
| FPS budget | No regression | Safe | ✅ |

**Performance headroom:** 0.0112 ms against a 1.0 ms budget = **89× headroom**.
The full 22-joint production topology can expand to ~22 hull vertices and ~176 final points and still remain well within budget.

**ε-guard:** Validated. Zero degenerate vectors produced NaN or Infinity across all 63 real landmark frames.

**Normal orientation:** Hull points printed for inspection:
- `hull[0] = (-7.731, 0.154)`
- `hull[1] = (-5.284, -0.906)`
- `hull[2] = (-0.391, -2.798)`

Orientation is in **normalized coordinate space** (not pixels). Final outward/inward direction verification requires visual inspection once `SilhouettePainter` is rendering on device. If inward-facing, flip `normalCCW → normalCW` in `kinematic_hull.dart`.

---

## Vertex Count Telemetry (Record for every test)

At each benchmark session, record:
- Input joints used
- Hull vertices generated (after Phase A)
- Final path points (after Chaikin)

Example target: `22 joints → 44 hull vertices → 352 final points (3 iterations)`

---

## Benchmark Suite v1.0

### Test 1 — Arms Crossed

**Purpose:** Stress-test elbow/shoulder bisector math. Bowtie anomaly check.

**Procedure:**
1. Stand facing camera, arms relaxed.
2. Cross both arms over chest.
3. Hold 5 seconds.
4. Uncross.
5. Repeat 5 times.

**Measuring:** Elbow self-crossing, shoulder overlap region, contour continuity.

**Pass:** No contour crossing. No holes. No spikes.
**File:** `topic_05_test 1_TIMESTAMP.jsonl`
**Result:** ⏳ Pending

---

### Test 2 — Hands in Pockets

**Purpose:** Partial limb disappearance. Confidence Gate validation.

**Procedure:**
1. Stand normally.
2. Put both hands in pockets.
3. Remove one hand. Put back. Repeat.

**Measuring:** Wrist disappearance handling, arm contour continuity, hip transition.

**Pass:** Smooth body contour. No floating wrist artifacts.
**File:** `topic_05_test 2_TIMESTAMP.jsonl`
**Result:** ⏳ Pending

---

### Test 3 — Sitting

**Purpose:** Large hip and knee fold geometry.

**Procedure:**
1. Stand.
2. Sit on chair.
3. Lean forward. Lean back.
4. Stand again.

**Measuring:** Hip geometry at large angle, knee bisector, torso shape change.

**Pass:** No contour collapse. Smooth bends at hip and knee.
**File:** `topic_05_test 3_TIMESTAMP.jsonl`
**Result:** ⏳ Pending

---

### Test 4 — Squat

**Purpose:** Worst-case knee geometry (deepest possible bend).

**Procedure:**
1. Stand.
2. Half squat.
3. Full squat (as deep as possible).
4. Stand.
5. Repeat 5 times.

**Measuring:** Knee bisector at extreme angle, leg thickness, foot cap.

**Pass:** No knee spikes. No self-intersection. Smooth inner knee curve.
**File:** `topic_05_test 4_TIMESTAMP.jsonl`
**Result:** ⏳ Pending

---

### Test 5 — Side Pose

**Purpose:** Half-body occlusion. Confidence Gate + topology gap handling.

**Procedure:**
1. Face camera (0°).
2. Slowly rotate to 30°, 60°, 90°.
3. Return to 0°.

**Measuring:** Half-body landmark loss, outline stability under occlusion, no crash.

**Pass:** Outline remains believable. No collapse. No crash on missing joints.
**File:** `topic_05_test 5_TIMESTAMP.jsonl`
**Result:** ⏳ Pending

---

### Test 6 — One Arm Raised

**Purpose:** Shoulder and armpit (axilla) geometry.

**Procedure:**
1. Raise left arm overhead. Lower.
2. Raise right arm overhead. Lower.
3. Raise both arms. Lower.

**Measuring:** Shoulder bisector, axilla hinge point, wrist axial extrusion overhead.

**Pass:** Smooth shoulder transition. No armpit tearing. No wrist stump.
**File:** `topic_05_test 6_TIMESTAMP.jsonl`
**Result:** ⏳ Pending

---

### Test 7 — Wide Stance

**Purpose:** Crotch topology and inner thigh separation.

**Procedure:**
1. Feet together.
2. Shoulder-width stance.
3. Wide stance.
4. Feet together.

**Measuring:** Crotch synthetic anchor, inner thigh geometry, clean leg separation.

**Pass:** Clean separation between legs. No merged thighs. No gap at crotch.
**File:** `topic_05_test 7_TIMESTAMP.jsonl`
**Result:** ⏳ Pending

---

### Test 8 — Walking

**Purpose:** Real-time dynamic stability under continuous motion.

**Procedure:**
1. Walk toward camera.
2. Walk away from camera.
3. Walk left.
4. Walk right.

**Measuring:** Outline stability, scale factor adaptation, FPS under motion, no flicker.

**Pass:** No outline flicker. No stretching. Scale stays proportional. FPS unchanged.
**File:** `topic_05_test 8_TIMESTAMP.jsonl`
**Result:** ⏳ Pending

---

## Performance Profiling

| Metric | Target | Result |
|--------|--------|--------|
| Silhouette engine execution time | < 1.0 ms | **0.0112 ms** ✅ |
| FPS before silhouette | Baseline | ⏳ TBD (Flutter) |
| FPS after silhouette | Baseline ± 0 | ⏳ TBD (Flutter) |
| Input joints used | 13 (evaluator) / 22+ (production) | 13 ✅ |
| Hull vertices | ~14 | 14 ✅ |
| Final path points (3 iterations) | ~112 | 112 ✅ |

---

## Summary Table

| Test | Status | Notes |
|------|--------|-------|
| 1. Arms Crossed | ⏳ Pending | |
| 2. Hands in Pockets | ⏳ Pending | |
| 3. Sitting | ⏳ Pending | |
| 4. Squat | ⏳ Pending | |
| 5. Side Pose | ⏳ Pending | |
| 6. One Arm Raised | ⏳ Pending | |
| 7. Wide Stance | ⏳ Pending | |
| 8. Walking | ⏳ Pending | |
