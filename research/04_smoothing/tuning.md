# Tuning Log: 04 — Landmark Smoothing

This log tracks the experimental modifications to the `FilterConfig` variables for the 1 Euro filter during physical benchmarking.

## The Trade-Off Laws
- **Increase $f_{min}$** $\rightarrow$ Less static smoothing, more responsive resting state (but higher jitter).
- **Decrease $f_{min}$** $\rightarrow$ Heavier static smoothing (solid stone), but might feel sluggish when first moving.
- **Increase $\beta$** $\rightarrow$ Filter deactivates faster on movement (Zero Lag). Too high = overshoots on sudden stops.
- **Decrease $\beta$** $\rightarrow$ Retains more filtering during movement (Lag/Trailing).

---

### Configuration Attempt 1 — Benchmark Suite 1 (VALIDATED ✅)
- **Date**: 2026-07-09
- **Core Profile**: $f_{min}=0.1, \beta=0.005$
- **Primary Profile**: $f_{min}=0.5, \beta=0.01$
- **Extremity Profile**: $f_{min}=1.0, \beta=0.05$
- **Score EMA ($\gamma$)**: 0.2
- **Outcome**: Met all target stability and responsiveness criteria under Benchmark Suite 1 conditions.
- **Key findings**:
  - Core (Hip) variance: `0.000003` — met the stability threshold.
  - Extremity (Wrist) dynamic range: `1.6003` — confirmed filter releases drag correctly on fast movement. No perceptible lag under test conditions.
  - EMA score smoother successfully prevented score from reaching `0.0` during partial occlusion (bottomed at `0.3161`).
- **Status**: LOCKED as Production v1.0. Do not change these values without re-running Benchmark Suite 1 and logging the comparative results here.
