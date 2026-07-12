# Benchmark Results: 04 — Landmark Smoothing (Jitter Removal)

**Status:** LOCKED — v1.0
**Validated Against:** Benchmark Suite 1 (9 Jul 2026)
**Benchmark Script:** `lib/engine/research/evaluate_topic_4.dart`

---

## 1. Final Validated Filter Profiles

| Profile | Target Joints | $f_{min}$ | $\beta$ | Notes |
|---------|---------------|-----------|---------|-------|
| **Core** | Hips, Shoulders | 0.1 | 0.005 | Aggressively rejects resting noise to anchor the Normalizer translation grid. |
| **Primary** | Elbows, Knees, Face | 0.5 | 0.01 | Balanced between stability and responsiveness. |
| **Extremity** | Wrists, Ankles, Fingers | 1.0 | 0.05 | High $\beta$ releases the filter weight on fast movement to meet zero-lag target. |

**Score EMA (UI smoother):** $\gamma = 0.2$

---

## 2. Benchmark Suite 1 Results

| Test | Objective | Metric | Result | Target | Pass |
|------|-----------|--------|--------|--------|------|
| **1. Stationary Variance** | 30s still. Jitter eliminated? | Right Wrist X-axis Variance | `0.000386` | `< 0.005` | ✅ |
| **2. Arm Wave (Tracking)** | Wave one hand. Does filter track high velocity? | Right Wrist Vertical Range | `1.6003` | `> 1.0` (unrestricted) | ✅ |
| **3. Oscillation (Overshoot)** | Fast Left/Right. Does filter keep up without overshoot? | Right Wrist Horizontal Range | `0.6297` | Coherent range | ✅ |
| **4. EMA Stability (Slouch)** | Does EMA prevent erratic UI score jumping? | Score Variance | `0.023701` | Smooth decay vs raw flash | ✅ |
| **5. Hold Pose (Drift)** | 20s hold. Does core drift? | Core (Hip) X-axis Variance | `0.000003` | `< 0.005` | ✅ |
| **6. FPS (Performance)** | Does filter reduce frame rate? | Filter execution time | `0.043ms` | `< 1ms` per frame | ✅ |
| **7. Low Light (Noise)** | Does it stabilize MediaPipe noise in poor lighting? | Right Wrist Variance (low confidence data) | `0.000000` | Visually stable | ✅ |
| **8. Camera Distance (Scale)** | Near/Far. Does core remain stable? | Core (Hip) X-axis Variance | `0.002322` | `< 0.005` | ✅ |

---

## 3. Critical Validation: EMA Score Smoother (Test 6 OFF vs ON)

This is the most important comparative test. Both tests were recorded during the same physical movement profile.

| State | Min Score Observed | Max Score Observed | UI Behaviour |
|-------|-------------------|-------------------|--------------|
| **EMA OFF** (`test_4_6_1`) | `0.0` (score crashed on occluded frame) | ~0.85 | Catastrophic flash — score hits zero instantly on partial occlusion |
| **EMA ON** (`test_4_6_2`) | `0.3161` (absorbed the crash) | `0.8207` | Score smoothly absorbs the drop and recovers. User never sees a zero. |

**Engineering conclusion:** The $\gamma = 0.2$ EMA successfully decouples raw vision tracking errors from the User Experience. It provides sufficient shock absorption for a single dropped frame without introducing noticeable lag in score recovery.

---

## 4. Performance Profiling

| Measurement | Value |
|-------------|-------|
| Filter execution time per frame | `0.043 ms` |
| Full pipeline time per frame | `0.099 ms` |
| Theoretical max FPS (filter alone) | `~23,255 FPS` |
| Observed app FPS (filter ON vs OFF) | `30 FPS` → `30 FPS` (zero regression) |
