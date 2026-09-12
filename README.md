# AI Photographer (Frozen AI)

"Your personal AI photographer that guarantees you look like a model in every shot."

## The Vision

Most individuals struggle with posing for photographs, and communicating those posing requirements to the person taking the photo often results in suboptimal images. 

AI Photographer solves this problem through augmented reality and real-time kinematic analysis. The user selects a target pose, and the application projects a mathematically precise, continuous holographic silhouette onto the camera viewfinder. The subject steps into this projection, and the Frozen Intelligence Engine provides real-time posture coaching. Once the subject's kinematics match the target pose within a highly constrained tolerance threshold for a sustained duration, the application automatically triggers the camera shutter.

This eliminates the friction of traditional photoshoots and ensures professional-grade composition and posture in every capture.

---

## A Research-Driven Architecture

The core intellectual property of this application is the Frozen Intelligence Engine. Rather than relying on simple point-to-point comparisons, the engine uses a proprietary, mathematically rigorous pipeline built from scratch to transform raw, noisy machine learning pose data into a premium augmented reality experience running at 60 frames per second.

The architecture was developed through a rigorous research-first methodology, prototyping and benchmarking multiple algorithms before finalizing the production pipeline.

### The Real-Time Processing Pipeline

#### 1. The Vision Engine
The pipeline begins with Google ML Kit, which acts as the raw vision engine. It extracts 33 2D landmarks from the camera feed. Because this layer only provides raw data, it is heavily abstracted and can be replaced with future computer vision models without affecting the rest of the application.

#### 2. Landmark Smoothing and Stabilization
Raw ML Kit landmark data exhibits significant temporal jitter. To stabilize the skeleton without introducing unacceptable latency, the application implements a custom 1 Euro Filter combined with an Exponential Moving Average (EMA). This mathematical filtering stabilizes the joints, allowing for smooth rendering even when the subject is stationary.

#### 3. Mathematical Normalization
A critical challenge in pose matching is scale and perspective variance (e.g., comparing a live user standing 10 feet away to a reference image cropped at the torso). The normalization engine uses spatial transformations, specifically translating the coordinate system to the mid-hip and applying scale anchoring. This removes perspective, distance, and Z-axis distortions, standardizing the skeleton for comparison.

#### 4. Pose Matching Engine (Kinematic Weighted Cosine)
Early research demonstrated that Euclidean distance matching fails when users lean toward or away from the camera due to perspective foreshortening. The production matching engine utilizes a Hybrid Kinematic Weighted Cosine algorithm. Instead of measuring point distances, it measures the angular vectors of human bones, placing heavy mathematical weight on the torso and spine while ignoring facial features. 

Additionally, the matcher uses Confidence Gating. If a limb is occluded (e.g., a leg hidden behind furniture), the algorithm gracefully removes that limb from the scoring denominator rather than penalizing the user for data the camera cannot see.

#### 5. Engine B: The Geometric Silhouette (Capsule Math & CSG)
Drawing a continuous, high-quality outline around the human body proved to be the most complex engineering challenge.
- Engine A (Failed Research): Attempting to trace the outer points of the skeleton resulted in self-intersecting, broken polygons that failed during complex poses.
- Engine B (Production): The human body is mathematically defined as 17 geometric capsules. The engine computes the exact bounding geometry of these capsules and utilizes Constructive Solid Geometry (CSG) boolean union operations to merge them into a single, flawless, non-intersecting path.
- Performance Optimizations: Performing CSG boolean operations on 17 shapes every frame is computationally expensive. The engine achieves 60 FPS on mobile devices through deep caching algorithms and adaptive coordinate mapping. The CSG path is generated once in a normalized coordinate space and then transformed using a Matrix4 translation and scale operation for every subsequent frame.
- Mathematical Mirroring: The engine features intelligent chiral mapping. When using the front-facing camera, the mathematical space is mirrored so that the rendered hologram moves intuitively with the user, matching the standard mirror-behavior of selfie cameras.

---

## The Three-Tier Architecture

The application is strictly separated into three architectural layers:

1. Frozen Vision Engine: Responsible solely for raw detection (currently ML Kit).
2. Frozen Intelligence Engine: The proprietary geometry, filtering, CSG rendering, and kinematic matching pipeline.
3. Frozen Mobile: The Flutter application layer, responsible for the user interface, CustomPainters, Camera lifecycle management, and gallery storage.

---

## Developer Instructions

Ensure you have the Flutter SDK installed and a physical device connected. The application relies heavily on camera access and hardware acceleration, making iOS Simulators and Android Emulators unsuitable for testing.

To run the main production application:
```bash
flutter run
```

To run the internal Pose Authoring Tool (used exclusively to generate our proprietary pose library JSON files):
```bash
flutter run -t lib/main_authoring.dart
```

---

## Current Project Status
**Phase: Core Geometry Validation Complete (Engine B Locked)**

The foundational architecture of the Frozen Intelligence Engine is complete and stable:
- The ML Kit vision integration is fully operational at 30+ FPS.
- The Mathematical Normalizer successfully eliminates distance and Z-axis perspective skew.
- The Hybrid Kinematic Weighted Cosine matching engine is active, reliably scoring human skeletal alignment with immunity to focal distortion.
- Engine B (Capsule Math + CSG Boolean geometry) is fully deployed. The app successfully renders a smooth, non-intersecting, glowing holographic body path and perfectly tracks the user's movements in real time.
- The core camera state machine correctly handles transitions between "No Person Detected," "Searching," and "Pose Matched."

## What We Are Building Next (The Roadmap)
Now that the core mathematical engine is locked and the hologram is flawlessly rendering, we are shifting focus to the product layer and hackathon deliverables:

1. **RevenueCat Integration :** Implementing a robust paywall and subscription infrastructure using RevenueCat, likely gating premium pose collections or advanced coaching metrics.
2. **Auto-Capture & Haptics:** Implementing the final stage of the state machine where sustaining a 95%+ kinematic match score for 2 seconds triggers device haptics and automatically captures the high-resolution photograph.
3. **The Pose Library & UI:** Building the Flutter frontend to allow users to browse, select, and preview a library of professional target poses.
4. **Visual Polish:** Finalizing the aesthetic layer, including transitioning from a standard material design to a premium, glassmorphism-inspired dark mode UI suitable for a professional photography tool.
