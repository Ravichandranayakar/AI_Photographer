# Engine A — Topology + Kinematic Hull + Chaikin
## STATUS: FROZEN AS BASELINE ?? (2026-07-09)

---

## What Was Built

A three-stage explicit geometry pipeline:

```
Raw Landmarks (pixel space)
        ¦
        ?
1 Euro Filter
        ¦
        ?
Confidence Gate (c >= 0.5)
        ¦
        ?
TopologyRouter  ? ordered 22-entry clockwise perimeter list
        ¦
        ?
KinematicHull   ? normal expansion, bisector, cap, crotch anchor
        ¦
        ?
ChaikinEngine   ? 3 iterations of 25%/75% corner cutting
        ¦
        ?
SilhouettePainter ? 3-layer glow
```

## Files (preserved in lib/engine/silhouette/)

- vec2.dart, silhouette_config.dart, topology_router.dart
- kinematic_hull.dart, chaikin_engine.dart, silhouette_engine.dart
- silhouette_painter.dart

## Evaluator Results (Offline — PASSED)

- 63 real frames, 0.0112ms/frame, 112 final points, zero NaN

## Device Test Results (Live Camera)

| Test           | Result  | Failure                           |
|----------------|---------|-----------------------------------|
| Standing front | Partial | Thin, mostly correct              |
| Standing side  | Fail    | Ghost shape detached from body    |
| Walking        | Fail    | Infinity loops, 10-second freeze  |
| Arms raised    | Fail    | Figure-8 crossings at shoulders   |
| Close-up       | Fail    | Loop at face/chin                 |
| Camera at sky  | Fail    | Renders 9-shape (no body visible) |

## Root Cause

Three fundamental limits:

1. Self-intersecting polygons — when joints move to unusual positions,
   normal vectors flip sign, path crosses over itself.
2. Cap direction bug — wrist-wrist = (0,0), degenerate bone.
3. No topological awareness — hardcoded 22-entry list assumes canonical pose.
4. Confidence gate does not validate that joints form a human shape.

## Lesson

We asked the wrong question: "How do we smooth a polygon?"
Industry asks: "How do we REPRESENT the human body mathematically?"

## Benchmark Score

| Metric                       | Engine A |
|------------------------------|----------|
| Offline correctness (63 fr.) | PASS     |
| Live real-time (30 fps)      | FAIL     |
| Standing front               | PARTIAL  |
| Non-canonical pose           | FAIL     |
| Partial detection robustness | FAIL     |
| Code lines                   | ~600     |

## Decision

FROZEN. Do not modify. Serves as baseline in 3-way benchmark.
Next: Engine B — Capsule + Implicit Body Field.
