# Engine B — Open Questions & Failure Log

> **Purpose:** Every benchmark failure is logged here with its geometric hypothesis,  
> the research area that addresses it, and the outcome of each fix attempt.  
> This file documents *why* design decisions were made — more valuable than the code.

---

## How to Use This File

When a test shows a visual problem:
1. Record the **symptom** exactly as you see it
2. Write your **hypothesis** (what math is failing and why)
3. Identify the **research area** to study
4. Record the **attempt** (what code change was tried)
5. Record the **result** (better / worse / same)

If result = "same" after 2+ attempts → the problem has hit a **mathematical wall**.  
Document the wall and move to the next extraction version.

---

## Open Questions

### OQ-001 — Arms at Sides Invisible
| Field | Value |
|---|---|
| **Symptom** | When standing with arms hanging at sides, the arm outline disappears entirely into the torso silhouette |
| **First observed** | Test 5.8.3 |
| **Hypothesis** | Polar Binning only works on star-shaped polygons. The arm is at the same polar angle as the torso. The torso wins the bin. No ray from any center can see the arm when it is behind the torso boundary. |
| **Research area** | Constructive Solid Geometry — Regularized Union (Requicha & Voelcker, 1977) |
| **Attempts** | `_eps` tuning (0.97→0.85): no improvement. Radius increase: no improvement. Confirmed mathematical wall. |
| **Status** | 🔴 Mathematical wall in v1. Assigned to **v2 CSG extractor**. |

---

### OQ-002 — Inner Thigh Gap
| Field | Value |
|---|---|
| **Symptom** | A visible gap appears between the two legs in normal standing pose. Outline looks like two separate sticks instead of one body. |
| **First observed** | Test 5.8.4 |
| **Hypothesis** | Math proof: knee separation = 0.45 normalized × 130px = 58.5px gap. Coverage = 2 × r_upperLeg = 38px. Uncovered gap = 20.5px. No capsule covers the inner thigh / crotch region. |
| **Research area** | Minkowski Sum of bone segments — adding a synthetic bridge primitive |
| **Attempts** | None yet. Fix is: add groin bridge capsule (midHip → midKnee, r = r_upperLeg × 0.75). |
| **Status** | 🟡 Pending — **Phase 0 fix**. |

---

### OQ-003 — Ghost Outline on Subject Exit
| Field | Value |
|---|---|
| **Symptom** | When subject walks out of camera frame, the last pose outline freezes on screen permanently. |
| **First observed** | Test 5.8.3 |
| **Hypothesis** | The state variable `_silhouetteResult` was not reset when `poses.isEmpty`. The last drawn outline was never cleared. |
| **Research area** | State management (not geometry) |
| **Attempts** | Fixed in `main.dart`: `if (poses.isEmpty) { _silhouetteResult = SilhouetteResult.empty(); }` |
| **Status** | ✅ Resolved in test 5.8.4. |

---

### OQ-004 — Head Capsule Too Large / Spiking
| Field | Value |
|---|---|
| **Symptom** | The head outline extends too far above the actual head, creating a balloon effect. |
| **First observed** | Test 5.8.3 |
| **Hypothesis** | The head capsule was anchored at `nose → synthetic_top`. The `synthetic_top` calculation was using shoulder_width × 0.35 as a height ratio, overshooting the actual crown. |
| **Research area** | Anatomical proportions — head-to-shoulder ratio |
| **Attempts** | Reduced ratio from 0.35 to 0.28. Head now sits correctly above nose. |
| **Status** | ✅ Resolved in test 5.8.4. |

---

### OQ-005 — Sitting Pose Disconnected Blobs
| Field | Value |
|---|---|
| **Symptom** | In sitting pose, the feet/ankle capsules appear as small disconnected ovals separate from the main body outline. |
| **First observed** | Test 5.8.5 |
| **Hypothesis** | Polar binning requires all surface points to be visible from the centroid. In a sitting pose, the torso centroid is far from the feet. Some angular bins have no candidates. The foot capsules become isolated blobs. |
| **Research area** | Star-shaped polygon limitation. CSG union solves this — each capsule is a self-contained path. |
| **Attempts** | None yet. |
| **Status** | 🟡 Expected fix: **v2 CSG**. |

---

### OQ-006 — Narrow Body at Far Distance
| Field | Value |
|---|---|
| **Symptom** | When subject is far from camera (small torsoPx), all capsule radii scale to near-zero, creating a thin stick figure outline. |
| **First observed** | Test 5.8.5 (27-frame far distance recording) |
| **Hypothesis** | S = torsoPx/150. At long range, torsoPx ≈ 65px → S ≈ 0.43 → r_torso ≈ 14px. Too thin. |
| **Research area** | Minimum viable radius floor |
| **Attempts** | Pending. Fix: `.clamp(8.0, double.infinity)` on all radius calculations. |
| **Status** | 🟡 Pending — **Phase 0 fix**. |

---

## Closed Investigations

| ID | Title | Resolution |
|---|---|---|
| OQ-003 | Ghost outline on exit | Fixed in main.dart |
| OQ-004 | Head capsule spiking | Fixed with ratio reduction |

---

## Mathematical Walls Confirmed

| ID | Title | Wall Type | Assigned to |
|---|---|---|---|
| OQ-001 | Arms at sides invisible | Star-shaped polygon limitation (polar binning) | v2 CSG |

---

*Document started: 2026-07-10 | Test phase: Engine B v1 (5.8.x)*
