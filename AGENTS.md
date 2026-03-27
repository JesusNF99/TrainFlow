# AGENTS.MD - Fitness Routine Architect & Senior Flutter Developer

## 1. Project Profile
- **Name:** TrainFlow Offline
- **Focus:** High-Performance Mobile Workout Tracker (Timer-centric).
- **Core Principle:** Offline-First, Zero Latency, 100% User Privacy.

## 2. Mandatory Tech Stack
- **Language:** Dart 3.x+ (Strongly typed, strict null-safety).
- **Framework:** Flutter (Stable Channel).
- **Database:** Isar Database (Local NoSQL). No Firebase or Cloud Sync allowed.
- **State Management:** Riverpod (Reactive architecture).
- **Audio Engine:** `audio_session` (for Audio Ducking) & `flutter_tts` (Text-to-Speech).
- **Background Persistence:** Android Foreground Services & iOS Live Activities.

## 3. Architecture & Coding Standards
- **Pattern:** Simplified Clean Architecture (Data Layer, Logic/Providers, UI).
- **Naming Conventions:**
  - Classes: `PascalCase`
  - Variables/Methods: `camelCase`
  - Files: `snake_case`
- **UI Language:** Labels and user-facing strings in **Spanish**.
- **Code Language:** Documentation, variables, and logic in **English**.
- **Modularity:** One file per screen. Reusable components in `lib/ui/widgets/`.

## 4. Agent Behavior & Constraints
- **Offline Constraint:** Never suggest external API calls or cloud-based solutions.
- **Battery Optimization:** Optimize Timer logic to prevent CPU spikes. Use controlled `Streams` instead of multiple `Timer.periodic` instances.
- **Audio Etiquette:** Always check `AudioSession` before triggering sounds to implement "Audio Ducking" (lowering music volume instead of stopping it).
- **Verification Flow:** For complex logic (Background Services/Isar Schemas), the agent MUST generate an **Antigravity Artifact** explaining the logic flow before writing code.

## 5. Data Model Definition (Isar Schema)
- `Routine`: {int id, String title, String description, List<String> tags, List<Exercise> exercises}
- `Exercise`: {int id, String name, ExerciseType type (reps/time), int value, int restTime, bool soundAlert}

## 6. Error & Conflict Protocol
- If a dependency conflict is detected in `pubspec.yaml`, stop immediately and alert the Antigravity Manager View.