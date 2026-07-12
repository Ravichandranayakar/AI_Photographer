# frozen_ai

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# To run the app 
C:\src\flutter\bin\flutter.bat run


--------------------------------------------------------------------------------

# Task: Research Phase — Frozen Intelligence Engine

---

## Topic 4: Landmark Smoothing & Score Stabilization
**Status: Validation Complete ✅ | LOCKED 🔒**
- `[x]` Create `filter_config.dart` (FilterProfile, FilterConfig, JointProfileRegistry)
- `[x]` Create `frozen_euro_filter.dart` (1 Euro Filter, independent per-joint state)
- `[x]` Create `score_smoother.dart` (EmaScoreSmoother γ=0.2)
- `[x]` Integrate into main pipeline (ML Kit → Euro → Normalizer → Matcher → EMA)
- `[x]` Benchmark Suite 1 completed (8 physical tests, all passed)
- `[x]` research/04_smoothing/benchmark.md — real measured data, LOCKED
- `[x]` research/04_smoothing/tuning.md — Configuration Attempt 1 validated
- `[x]` research/04_smoothing/decision.md — Engineering Decision Record
- `[x]` research/Frozen_AI_Algorithms.md — Algorithm constitution created
- `[x]` filter_config.dart comments updated from "hypothesis" → "Production v1.0"

---

## Topic 5A: Engine A — Topology + Kinematic Hull + Chaikin
**Status: FROZEN AS BASELINE 🧊 (2026-07-09)**

### Engineering Decision
- `[x]` Engine built — 6 files, ~600 lines, all passing offline evaluator
- `[x]` Live device test — FAILED (self-intersecting polygon, infinity loops, 10s freeze)
- `[x]` Root cause documented — explicit topology is wrong mathematical representation
- `[x]` research/05_body_silhouette/engine_a_topology/decision.md written
- `[x]` Engine A disabled in main.dart (returns SilhouetteResult.empty())
- `[x]` All Engine A files preserved in lib/engine/silhouette/ (do not delete)

---

## Topic 5B: Engine B — Capsule + Implicit Body Field
**Status: RESEARCH PHASE 🔬 — Active**

### Research Question
> "How do we represent the human body mathematically?"
> Not: "How do we smooth a polygon?"

### Mathematical Model
- `[x]` research/05_body_silhouette/engine_b_capsule/research_plan.md written
- `[x]` 17-capsule bone registry defined
- `[x]` Gaussian field equation: F_i(P) = w_i * exp(-d_i(P)^2 / 2σ_i^2)
- `[x]` Adaptive sigma: σ_i = r_i * S * C_i (confidence-gated)
- `[x]` Grid resolution decided: 64x96 (6144 samples, ~1-2ms/frame)

### Prototype Implementation
- `[ ]` research/05_body_silhouette/engine_b_capsule/capsule.dart
        (Capsule struct + closestPoint() + distance() math)
- `[ ]` research/05_body_silhouette/engine_b_capsule/body_field.dart
        (BodyField: build 17 capsules, evaluate F(P) on grid)
- `[ ]` research/05_body_silhouette/engine_b_capsule/marching_squares.dart
        (Extract iso-contour at threshold T from grid)
- `[ ]` research/05_body_silhouette/engine_b_capsule/engine_b.dart
        (Top-level: landmarks → capsules → field → contour → Chaikin → path)
- `[ ]` research/05_body_silhouette/engine_b_capsule/engine_b_evaluator.dart
        (Offline benchmark: same 63-frame JSONL, measure ms/frame + contour quality)

### Offline Evaluator Validation
- `[x]` Run engine_b_evaluator.dart on real JSONL logs
        Result: 63 frames loaded, 62/63 valid polygons
- `[x]` Verify no NaN/Infinity in output — ZERO NaN ✅
- `[x]` Measure avg ms/frame — **0.196 ms** (81× FPS headroom) ✅
- `[x]` Capsule range: 17/17 every frame ✅
- `[x]` Outer surface points: 160 from 578 candidates (72% filtered interior)
- `[x]` Final vertices: 104 (Chaikin ×2, hull 26 bins)

### Flutter Integration (only after evaluator passes)
- `[x]` Wire engine_b.dart into main.dart (replace SilhouetteResult.empty())
- `[ ]` Visual sanity check on device — does it look like a human body?
- `[ ]` Check: does the outline follow motion in real time?

### Benchmark Suite (same 8 tests as Engine A)
- `[ ]` Test 1: Arms Crossed
- `[ ]` Test 2: Hands in Pockets
- `[ ]` Test 3: Sitting
- `[ ]` Test 4: Squat
- `[ ]` Test 5: Side Pose
- `[ ]` Test 6: One Arm Raised
- `[ ]` Test 7: Wide Stance
- `[ ]` Test 8: Walking

### Lock
- `[ ]` research/05_body_silhouette/engine_b_capsule/decision.md written
- `[ ]` Benchmark table filled (FPS, CPU, visual quality per test)

---

## Topic 5C: Engine C — Pure Implicit Field (Queued)
**Status: QUEUED — Do not start until Engine B benchmark is complete**

- `[ ]` research/05_body_silhouette/engine_c_field/ (folder created ✅)
- `[ ]` Begin only if Engine B visual quality is insufficient

---

## Final Decision (All Engines)
- `[ ]` 3-way benchmark table complete
- `[ ]` Winner selected based on: FPS, visual quality, robustness
- `[ ]` Winner refactored into production-quality lib/engine/silhouette_v2/
- `[ ]` research/05_body_silhouette/decision.md written
- `[ ]` research/Frozen_AI_Algorithms.md updated



------------------------------------------------------------------------------------

ok bro now big question appearing so we reached where engine now ready next is what bro ya i know work on engine C but let think if one egine is ready means after what we move on preogress according to our planr erd  we done with only 2 according to this , 1. The Three Products Architecture
Product	Priority	Description
Frozen Vision Engine	⭐⭐⭐⭐⭐	Raw detection only. Replaceable. (MediaPipe/ML Kit)
Frozen Intelligence Engine	⭐⭐⭐⭐⭐	Our proprietary geometry & AI pipeline. The actual IP.
Frozen Mobile	⭐⭐⭐⭐	Flutter app layer. UI, Camera, RevenueCat, Gallery.
Frozen Content	⭐⭐⭐⭐	Pose Collections, Download Manager, Metadata.
, Engineering Decision Record (EDR) v3.2 - FINAL LOCK
Project: Frozen AI — The Real-Time Geometry Engine Core Value Proposition: "The app that shows you exactly how to stand." Core IP Definition: MediaPipe's job ends at raw landmarks. Everything after that is Frozen AI.

1. The Three Products Architecture
Product	Priority	Description
Frozen Vision Engine	⭐⭐⭐⭐⭐	Raw detection only. Replaceable. (MediaPipe/ML Kit)
Frozen Intelligence Engine	⭐⭐⭐⭐⭐	Our proprietary geometry & AI pipeline. The actual IP.
Frozen Mobile	⭐⭐⭐⭐	Flutter app layer. UI, Camera, RevenueCat, Gallery.
Frozen Content	⭐⭐⭐⭐	Pose Collections, Download Manager, Metadata.
2. The Complete Pipeline (Production Architecture)

Camera (30 FPS)
        │
        ▼
[ FROZEN VISION ENGINE ]
MediaPipe Pose Detector
  └─ Output: 33 Raw Landmarks
        │
        ▼
[ FROZEN INTELLIGENCE ENGINE ]
1. Landmark Validator
   └─ Exactly 1 person detected? Confidence > threshold?
        │
        ▼
2. Landmark Filter (Jitter Removal)
   └─ Apply smoothing filter to stabilize skeleton.
      Algorithm: TBD via research (One Euro / Kalman / EMA benchmarks)
        │
        ▼
3. Landmark Normalizer
   └─ Remove body size, distance, and perspective distortions.
      Output: A standardized, comparable skeleton.
        │
        ▼
4. Target Pose Loader
   └─ Load the selected TargetPose from Frozen Content layer.
        │
        ▼
5. Pose Transformer
   └─ Scale, Translate, Rotate, Perspective Correction, and Alignment.
      Alignment: As the user moves, the outline continuously re-centers
      to maintain spatial coherence between the live body and the target.
      Output: Transformed target landmarks in screen coordinates.
        │
        ▼
6. Adaptive Body Silhouette Generator
   └─ Generate a smooth, closed body silhouette path by connecting
      body segments with an outward offset. Output is a single
      continuous path — NOT disconnected lines or stick figures.
      Curve algorithm: TBD via research (Catmull-Rom / Chaikin / B-Spline / Cubic Bezier benchmarks)
        │
        ▼
7. Pose Matcher
   └─ Compare normalized user skeleton vs transformed target.
      Algorithm: Hybrid (Cosine Similarity + Kinematic Hierarchical Weights). EDR Locked.
        │
        ▼
8. Pose Confidence Engine
   └─ Applies Confidence Gating (τ = 0.5). Joints where ML Kit confidence
      is below threshold are mathematically excised from the score denominator.
      Prevents penalizing the user for occluded joints the camera cannot see.
        │
        ▼
9. Pose Score Engine
   └─ Output: Smoothed match score (0–100%). Prevents wild jumping.
        │
        ▼
10. Guidance Engine
   └─ For joints where joint_score < threshold, trigger coaching.
      Priority order (LOCKED):
        Priority 1 → Visual: The outline itself shifts toward the user's body.
        Priority 2 → Icons: Small directional arrows (↑ ↓ ← →) near the mismatched joint.
        Priority 3 → Text Labels: e.g., "Lift your leg" — OPT-IN ONLY via "Coaching Mode" in Settings.
      Default experience is silent. Humans copy shapes.
        │
        ▼
[ FROZEN MOBILE ]
11. Flutter Renderer (CustomPainter ONLY)
    └─ Paint whatever the engine outputs. Nothing more.
        │
        ▼
12. Auto Capture Module
    └─ Score > 95% sustained for 2 seconds → capture.
3. The Outline Is Not UI
The Adaptive Body Silhouette Generator is part of the Frozen Intelligence Engine — NOT the Flutter UI layer.

We never store images of outlines.
We generate them mathematically from transformed landmark coordinates.
The output is one continuous closed path (like a human silhouette), not connected dots or stick lines.
Flutter's CustomPainter is a dumb renderer — it only paints what the engine tells it to.
4. Pose Creator Mode (Our Data Moat)
We will build our own Pose Library. No datasets. No copyright. No guessing.


Pose Creator Mode
└─ You stand in correct position
└─ App captures live landmarks
└─ Saves as a TargetPose package (JSON)
└─ This IS the target the silhouette is generated from
Every pose in Frozen AI belongs to us.

5. Research Folder Structure

research/
  ├── 01_pose_estimation/      ← MediaPipe, MoveNet output stability
  ├── 02_normalization/        ← Procrustes, scale, translation approaches
  ├── 03_pose_matching/        ← Euclidean, Cosine, Joint Angles, Hybrid
  ├── 04_smoothing/            ← One Euro, Kalman, EMA, Moving Average
  ├── 05_silhouette_generation/← Catmull-Rom, Chaikin, B-Spline, Cubic Bezier
  ├── 06_guidance_engine/      ← HCI research, motor learning, visual coaching
  ├── papers/
  ├── notes/
  └── benchmarks/
Research is a first-class citizen. We test, benchmark, and discard. The algorithm that survives becomes production code.

Research Outcomes
Topic 02: Normalization (VALIDATED - July 8)
Test 1 (Translation): Normalized mid-hip flawlessly maintained (0.00, 0.00) while moving across the entire screen.
Test 2 (Scale): Normalized shoulder Y stayed perfectly anchored at ±1.00 regardless of torso pixel size (tested from 985px down to 64px distance).
Test 3 (Jitter Baseline): Core joints flutter by ~0.02 while standing still, extremities by 0.20.
Status: Math Locked. Proceeding to Smoothing / Matching.
Topic 03: Pose Matching Engine (LOCKED v3.2 - July 8)
Test 3.1 (Z-Axis Lean): Baseline (Euclidean) plummeted from 44% to 8% due to focal perspective distortion. Hybrid (Weighted Cosine) held perfectly stable at 96.0%. Immunity to Z-axis distortion proven.
Test 3.2 (The Slouch): Hybrid score correctly penalized poor posture, dropping smoothly from 97% to 75% when the core spine vector was physically bent.
Test 3.3 (The Amputation / Camera Tilt): Baseline failed instantly (0.0%) due to distance scale. Hybrid started at 96% and correctly penalized missing (occluded) limbs down to 83% via Confidence Gating.
Refinements Added: Dynamic anchor-clamping (Score = max(0, (S - 0.85)/0.15) to make the UI score highly sensitive. Camera Roll handling added to Normalizer to mathematically level the skeleton if the device is tilted.
Decision: Candidate D (Kinematic Weighted Cosine Engine with Confidence Gating). Point-to-point Euclidean matching is fully deprecated due to 90%+ scale and Z-axis perspective variance. We rely 100% on bone orientation vectors weighted heavily at the torso spine, omitting face landmarks entirely.
Status: Topic 3 is completely validated, benchmarked, and LOCKED.
6. AI Principles (Locked)
Everything runs offline. No cloud latency. No privacy risk.
30 FPS minimum. The feedback loop must feel instantaneous.
No black-box decisions. Our engine is pure geometry — explainable math.
Modular by design. Replace MediaPipe with any future detector — the Intelligence Engine stays identical.
Visual coaching first. Shapes → Icons → Text (opt-in). In that order. Always.
We own the data. Every target pose is captured from real humans. Our library.
No algorithm is locked before benchmarking. We research, prototype, measure, then decide.
Status: FINAL LOCK v3.1. Proceeding to Phase 0: AI Research.

#   A I _ P h o t o g r a p h e r  
 