# Frozen AI — Algorithm Constitution

This document is the canonical reference for every algorithm, filter, and mathematical decision that forms the Frozen Intelligence Engine.

Each entry represents a **locked architectural decision** backed by a research cycle, implementation, and benchmark validation.

---

## Algorithm Registry

| Topic | Component | Algorithm / Method | Status | Decision Record |
|-------|-----------|-------------------|--------|-----------------|
| **01** | Pose Detection | ML Kit Pose Landmarker (Base Model, Stream Mode) | 🔒 LOCKED | — |
| **02** | Skeleton Normalization | Torso-anchored coordinate normalization (hip midpoint origin, torso-length scale) | 🔒 LOCKED | `research/02_normalization/` |
| **03** | Pose Matching | Kinematic Weighted Cosine Similarity (Hybrid Engine) | 🔒 LOCKED | `research/03_pose_matching/` |
| **04** | Coordinate Smoothing | 1 Euro Filter (per-joint, velocity-sensitive, independent state matrix) | 🔒 LOCKED | `research/04_smoothing/decision.md` |
| **04** | Score Smoothing | Exponential Moving Average (EMA, $\gamma = 0.2$) | 🔒 LOCKED | `research/04_smoothing/decision.md` |

---

## Production Pipeline (Frozen AI Engine v0.1)

```
Camera Frame
      ↓
[Topic 01] ML Kit Pose Detection
      ↓  33 raw landmarks
[Topic 04] 1 Euro Filter (spatial smoothing)
      ↓  33 smoothed landmarks
[Topic 02] LandmarkNormalizer (torso-anchored scale)
      ↓  33 normalized landmarks
[Topic 03] PoseMatcher (Kinematic Weighted Cosine)
      ↓  raw match score (0.0–1.0)
[Topic 04] EMA Score Smoother (UI shock absorber)
      ↓  stable UI score
User Interface
```

---

## Lock Policy

An algorithm is **LOCKED** only after completing the full research cycle:

- [x] Research & mathematical justification documented
- [x] Prototype implemented in isolation
- [x] Integrated into production pipeline
- [x] Physical device benchmark executed
- [x] Benchmark results documented with evidence-based language
- [x] Engineering Decision Record written
- [x] No regressions introduced to previously locked topics

**A locked algorithm may only be changed if:**
1. A new benchmark re-evaluation is conducted.
2. The results are logged in the relevant `tuning.md` file.
3. The decision record is updated.

---

## Deprecated / Rejected Algorithms

| Algorithm | Reason for Rejection |
|-----------|---------------------|
| Euclidean Distance Matching | Z-axis blind; breaks on scale change and camera distance. Replaced by Topic 03. |
| Simple EMA on Coordinates | Fails lag test at high movement velocity. Replaced by 1 Euro Filter in Topic 04. |
| Kalman Filter | Over-engineered for current MVP scope; requires per-joint motion model. Deferred. |
