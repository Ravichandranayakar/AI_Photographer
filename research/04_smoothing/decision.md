# Engineering Decision Record: 04 — Landmark Smoothing

**Date:** 2026-07-09
**Status:** LOCKED — v1.0
**Author:** Frozen AI Research Engine
**Validated Against:** Benchmark Suite 1

---

## Decision

Implement **two independent, permanently active filters** in the production pipeline:

1. **1 Euro Filter** — Applied to landmark **coordinates** (spatial domain)
2. **EMA Score Smoother** — Applied to the final **pose match score** (scalar domain)

Both filters are always active in production. There is no toggle.

---

## Context

MediaPipe ML Kit outputs raw landmark coordinates that contain two categories of noise:
- **High-frequency jitter:** Sub-pixel vibrations from camera sensor noise, even when the subject is stationary.
- **Dropped frames / occlusion spikes:** Momentary frames where confidence drops and coordinates jump to incorrect positions.

A naive smoothing approach (e.g., simple EMA on coordinates) causes visible lag — the skeleton visually trails behind the user's body. This is the **Jitter-Lag Trade-off**, documented in *Casiez, Roussel & Vogel (CHI 2012)*.

---

## Chosen Algorithm: 1 Euro Filter (Coordinates)

**Why selected over alternatives:**
- Simple EMA on coordinates: Rejected. Fails lag test — wrist trails by multiple frames at high velocity.
- Kalman Filter: Rejected for MVP. Requires motion model tuning per joint type; over-engineered for current scope.
- **1 Euro Filter: Selected.** Velocity-sensitive cutoff frequency means it aggressively smooths when the subject is still, and automatically reduces smoothing when movement accelerates. Passes both static variance test and dynamic lag test.

### Validated Configuration (v1.0)

| Profile | Joints | $f_{min}$ | $\beta$ | Derivation |
|---------|--------|-----------|---------|------------|
| `Core` | Hips, Shoulders | `0.1` | `0.005` | Low $f_{min}$ = maximum static suppression to anchor the Normalizer |
| `Primary` | Elbows, Knees, Face | `0.5` | `0.01` | Balanced |
| `Extremity` | Wrists, Ankles, Fingers | `1.0` | `0.05` | High $\beta$ = filter drops drag immediately on acceleration |

---

## Chosen Algorithm: EMA Score Smoother (Scalar)

**Why a separate filter on the score:**
The 1 Euro Filter is a spatial filter. It is not designed for 1D scalars. More importantly, the problem it solves is different: the score does not lag — it crashes to `0.0` when a landmark is momentarily occluded, then jumps back. This requires a shock absorber, not a spatial filter.

### Validated Configuration (v1.0)

| Parameter | Value | Derivation |
|-----------|-------|------------|
| $\gamma$ (smoothing factor) | `0.2` | Empirically selected. Absorbs single-frame drops without introducing noticeable recovery lag. |

### Evidence from Benchmark Suite 1, Test 6:

| Condition | Min Score | Behaviour |
|-----------|-----------|-----------|
| EMA OFF | `0.0` | Score crashes to zero on partial occlusion. UI would flash failure state. |
| EMA ON | `0.3161` | Score absorbs the crash. Never hits zero. Recovers smoothly. |

---

## Final Production Pipeline

```
Camera Frame (raw pixels)
      ↓
ML Kit Pose Detection (33 raw landmarks)
      ↓
1 Euro Filter (per-joint, coordinate-level smoothing)
      ↓
LandmarkNormalizer (Topic 2: torso-anchored normalization)
      ↓
PoseMatcher (Topic 3: Kinematic Weighted Cosine)
      ↓
EMA Score Smoother (scalar shock absorber)
      ↓
UI Score (displayed to user)
```

---

## What This Decision Is NOT Claiming

- This does not claim the algorithm **completely eliminates** jitter.
  - Accurate claim: It **significantly reduces** landmark jitter under Benchmark Suite 1 conditions.
- This does not claim the configuration is **perfectly calibrated**.
  - Accurate claim: It was **selected based on benchmark results** and met the defined thresholds.
- This does not claim the torso is **mathematically frozen**.
  - Accurate claim: Core (Hip) variance **remained below the target threshold** (`0.000003 < 0.005`) under benchmark conditions.

---

## Constraints and Future Re-evaluation Triggers

This configuration should be revisited if any of the following occur:
- A new MediaPipe model version is adopted (noise characteristics may change).
- The app targets devices below the current benchmark device class.
- User testing reveals visible lag in high-velocity movements (consider raising $\beta$ on Extremity profile).
- User testing reveals visible jitter during slow movements (consider lowering $f_{min}$ on Primary profile).

Any changes must be documented in `research/04_smoothing/tuning.md` with a new configuration attempt entry.
