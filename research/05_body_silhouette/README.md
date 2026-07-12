# Research Topic 5 — Body Silhouette Generation

**Status:** Implementation Phase
**Started:** 2026-07-09

## Problem Statement

Topics 1–4 built a mathematically accurate, stable, scored pose engine. The output is 33 smoothed, normalized landmark coordinates. This is correct but invisible to the user.

**Topic 5 answers:** How do we generate a smooth, biologically plausible, real-time body silhouette from those landmarks — with zero self-intersections, zero lag, and proportional biological scaling?

This is a **computational geometry problem**, not a curve fitting problem.

## Pipeline Summary

```
33 Smoothed Landmarks
      ↓
Confidence Gate (filter c < 0.5)
      ↓
Topology Router (clockwise perimeter order)
      ↓
Kinematic Expansion (normal offsets + bisectors + caps)
      ↓
Chaikin Subdivision (3–4 iterations)
      ↓
Flutter CustomPainter → drawPath()
```

## Folder Contents

| File | Purpose |
|------|---------|
| `README.md` | This file |
| `papers.md` | Literature review |
| `math.md` | All equations extracted from research |
| `comparison.md` | Algorithm comparison matrix |
| `benchmark.md` | 8-test benchmark suite |
| `decision.md` | Engineering decision record |
| `artifact_gallery/` | Debug PNGs saved per geometry issue |

## Reference

Full implementation plan: See implementation_plan.md in brain artifacts.
Engine code: `lib/engine/silhouette/`
