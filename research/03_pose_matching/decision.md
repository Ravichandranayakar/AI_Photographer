# Decision Record: 03 — Pose Similarity / Matching

**Status:** LOCKED
**Date:** 2026-07-08
**Implementation:** `lib/engine/matcher/pose_matcher.dart`

---

## Problem Statement

After normalization (Decision 02), we have two skeletons in the same geometric
space: the live user's skeleton and the stored target pose. We need a single
`score ∈ [0.0, 1.0]` that represents how closely the user's body matches the target.

A naive approach (comparing joint positions directly) fails because:
- It punishes the user for occluded joints the camera cannot see.
- It treats a wrist misalignment as equally serious as a spine misalignment.

## Candidates Evaluated

| Algorithm | Pros | Cons | Decision |
|---|---|---|---|
| Euclidean Distance | Simple to compute | Sensitive to residual scale differences; penalizes distal joints too heavily | ❌ Rejected |
| Cosine Similarity (raw) | Scale-immune; measures bone direction | Cannot detect translation errors; no structural hierarchy | ❌ Alone insufficient |
| Joint Angle Similarity | Anatomically accurate | Computationally expensive; singularity at 180° joints | ❌ Too fragile for MVP |
| **Hybrid (Cosine + Weights + Gating)** | Combines advantages; enforces structure; robust to occlusion | More complex implementation | ✅ **LOCKED** |

## Two Core Innovations

### 1. Confidence Gating (τ = 0.5)

ML Kit returns a `likelihood` score for every landmark.
When a joint is occluded (e.g., left foot behind right leg), ML Kit guesses
its position but reports a low confidence (e.g., 0.15).

Including that guessed coordinate in the score calculation would penalize
the user for something they are not doing wrong.

**Fix:** Define a threshold τ = 0.5. Any bone where the mean joint confidence
falls below τ is excluded from both the numerator AND the denominator of the
score equation. The denominator shrinks dynamically, so the score is always
calculated as a percentage of what the camera can actually see.

### 2. Kinematic Hierarchical Weighting

Not all joints are equally important. A user cannot reach a high score by
having perfect wrist positions while their spine is misaligned.

The skeleton is divided into three tiers:

| Tier | Bones | Weight |
|---|---|---|
| **Core** | Clavicle, Pelvis, Left Torso, Right Torso | 0.5 |
| **Primary** | Humerus (×2), Femur (×2) | 0.3 |
| **Secondary** | Forearm (×2), Calf (×2) | 0.2 |

This enforces structural integrity from the skeleton outward.

## Locked Mathematics

For each bone `i` tracked in [BoneRegistry]:

**Bone vectors (in normalized FrozenLandmark space):**
```
u_i = (user_end.x - user_start.x,  user_end.y - user_start.y)
t_i = (target_end.x - target_start.x, target_end.y - target_start.y)
```

**Cosine Similarity:**
```
S_i = (u_i · t_i) / (‖u_i‖ * ‖t_i‖)    ∈ [-1, 1]
```

**Mapped to [0, 1]:**
```
S'_i = (S_i + 1) / 2
```

**Bone confidence:**
```
c_i = (likelihood(start_joint) + likelihood(end_joint)) / 2
```

**Confidence gate:**
```
if c_i < 0.5 → bone i is excised (set weight to 0, excluded from denominator)
```

**Final weighted score:**
```
TotalScore = Σ(w_i * c_i * S'_i) / Σ(w_i * c_i)
```

Where the sums are taken only over bones that passed the confidence gate.

## Why This Is Defensible IP

Standard pose-comparison systems treat all 33 landmarks with equal weight.
Frozen AI's Pose Matcher is the only component that knows **which bones matter more**
for a given coaching context. In a future version, the weight matrix itself can be
made pose-specific (e.g., for a yoga pose, the core weight could increase to 0.7),
making the scoring engine fully adaptive per collection.

## Next Step

Decision 03 feeds directly into the **Pose Score Engine** (Research Topic not yet started),
which applies temporal smoothing to prevent the raw score from jumping between frames.
