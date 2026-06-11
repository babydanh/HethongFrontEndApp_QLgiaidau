# Refactoring Roadmap

## 1. Executive Summary

A brief, high-level overview of the codebase's health. Mention the main areas for improvement (e.g., "The codebase has a solid foundation but lacks enforcement of SOLID principles, especially in the bracket generation logic. State management needs an upgrade to the latest Riverpod APIs.").

## 2. Key Findings & Violations

Group findings by the principle they violate. For each finding, list the file path, line numbers (if applicable), and a code snippet.

### 2.1. SOLID Principles Violations

- **Single Responsibility Principle (SRP):**
  - **File:** `lib/features/bracket/providers/bracket_logic_provider.dart`
  - **Issue:** Class `BracketLogicProvider` mixes state management with complex bracket generation business logic.
  - **Impact:** Hard to test, reuse, and maintain. The business logic is not separated and cannot be used independently of the provider.
- **Open/Closed Principle (OCP):**
  - **File:** `lib/features/bracket/providers/bracket_logic_provider.dart`
  - **Issue:** Bracket generation logic is hardcoded inside the provider using a specific algorithm for single-elimination, instead of using a strategy pattern.
  - **Snippet:**
    ```dart
    // Logic is tightly coupled to single-elimination
    int rounds = (log(teams.length) / log(2)).ceil();
    ...
    for (var round = 1; round <= rounds; round++) {
      // Pairing logic is here
    }
    ```
  - **Impact:** Adding a new bracket type (e.g., Round Robin, Double Elimination) requires modifying this large provider, increasing the risk of bugs.

### 2.2. State Management Issues

- **File:** `lib/providers/match_control_notifier.dart`, `lib/providers/team_notifier.dart`, `lib/features/bracket/providers/bracket_logic_provider.dart` (and others)
- **Issue:** Still uses the deprecated `StateNotifier`.
- **Snippet:**
  ```dart
  class BracketLogicProvider extends StateNotifier<BracketState> {
    BracketLogicProvider(this.ref) : super(const BracketState.initial());
  ```
- **Impact:** Not aligned with modern Riverpod practices, might miss out on new features and improvements. The migration is mandated by the project rules.

### 2.3. Database Abstraction Leaks

- **File:** `lib/features/auth/screens/phone_auth_screen.dart`
- **Issue:** UI layer directly calls `FirebaseAuth.instance`.
- **Snippet:**
  ```dart
  await FirebaseAuth.instance.verifyPhoneNumber(...);
  ```
- **Impact:** Tightly couples the UI to Firebase, making it impossible to switch databases or test the UI independently.

- **File:** `lib/features/teams/views/add_team_screen.dart`
- **Issue:** UI layer directly calls `FirebaseFirestore.instance`.
- **Snippet:**
  ```dart
  await FirebaseFirestore.instance.collection('tournaments')...
  ```
- **Impact:** Same as above. Breaks the clean architecture principles.

### 2.4. Hardcoded Values & Other Issues

- **Issue:** Hardcoded collection names.
- **File:** `lib/data/repositories/impl/tournament_repository_impl.dart`
- **Snippet:**
  ```dart
  _firestore.collection('tournaments')
  ```
- **Impact:** Makes the database schema brittle. A change in collection name requires a risky code search-and-replace.

- **Issue:** Widespread use of `print()` instead of `AppLogger`.
- **Files:** Multiple, including `lib/main.dart`, `lib/features/tournament/views/tournament_detail_screen.dart`, etc.
- **Impact:** Inconsistent and unstructured logging. Makes debugging in production difficult.

## 3. Step-by-Step Refactoring Plan

A prioritized list of actions.

### Phase 1: Foundational Cleanup (Critical)

1.  **Upgrade Riverpod Notifiers:**
    - **Task:** Convert all `StateNotifier` instances to `Notifier` or `AsyncNotifier`.
    - **Files to change:** `lib/providers/match_control_notifier.dart`, `lib/providers/team_notifier.dart`, `lib/providers/tournament_action_notifier.dart`, `lib/features/tournament/providers/tournament_provider.dart`, `lib/features/live/providers/live_matches_provider.dart`, `lib/features/bracket/providers/bracket_logic_provider.dart`.
2.  **Isolate Database Logic:**
    - **Task:** Move all direct Firebase calls from UI/Notifiers into a new or existing repository implementation. Introduce repository interfaces in the `domain` layer if they don't exist.
    - **Files to change:** `lib/features/auth/screens/phone_auth_screen.dart`, `lib/features/teams/views/add_team_screen.dart`, `lib/main.dart`, `lib/data/services/notification_service.dart`.
    - **Action:** Create `AuthRepository` and `TeamRepository` interfaces in `domain/` and implementations in `data/`. Refactor the UI to call providers that use these repositories.

### Phase 2: Refactor Bracket Generation Logic

1.  **Introduce `IBracketGenerator` Strategy:**
    - **Task:** Define an abstract class `IBracketGenerator` in `lib/domain/services/`. Create a concrete implementation `SingleEliminationGenerator`.
    - **Files to create:** `lib/domain/services/bracket_generator.dart`, `lib/data/services/single_elimination_generator.dart`.
2.  **Create `BracketService`:**
    - **Task:** Create a service that takes the generator strategy and team list to produce the match list. This service will contain the logic currently in `BracketLogicProvider`.
    - **Files to create:** `lib/domain/services/bracket_service.dart` (interface), `lib/data/services/bracket_service_impl.dart` (implementation).
3.  **Refactor Bracket Provider & UI:**
    - **Task:** The new `BracketProvider` (using `AsyncNotifier`) should now call the `BracketService`. The UI should not change, but it will be fed by a more robust and modular system.
    - **Files to change:** `lib/features/bracket/providers/bracket_logic_provider.dart`.

### Phase 3: General Code Quality Improvements

1.  **Centralize Constants:**
    - **Task:** Find all hardcoded strings ("tournaments", roles like "admin") and colors, and move them to `AppConstants` and `AppTheme`.
    - **Files to change:** `lib/data/repositories/impl/tournament_repository_impl.dart`, `lib/data/services/notification_service.dart`, etc.
2.  **Implement Logging:**
    - **Task:** Replace all `print()` and `debugPrint()` calls with the `AppLogger`.
    - **Files to change:** Search and replace across the entire `lib/` directory.
