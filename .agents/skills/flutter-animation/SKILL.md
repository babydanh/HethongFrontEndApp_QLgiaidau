---
name: flutter-animation
description: Design, implement, review, or test animations and transitions in the Sporto Flutter app using its conventions and the workspace UI/UX Pro Max guidance when available.
---

# Flutter Animation Skill

## Use and source of truth

Use this skill for any animation, transition, loading motion, animated state, or motion/accessibility review in `HethongFrontEndApp_QLgiaidau`.

- The workspace UI/UX Pro Max skill is at [`../../../../.agents/skills/ui-ux-pro-max/SKILL.md`](../../../../.agents/skills/ui-ux-pro-max/SKILL.md) when this solution workspace is open. The rules below remain usable if that shared folder is not available; do not copy its dataset into the app.
- Before a change, inspect the target widget, its tests, `pubspec.yaml`, `lib/core/config/app_theme.dart`, and existing motion/accessibility patterns. Read only relevant source ranges.
- The app declares Dart `^3.10.3`, Flutter `>=3.41.0`, and already has `flutter_animate`. Do not add a dependency merely to animate.
- The shared Flutter stack dataset is labeled Flutter 3.44.x. Treat its suggestions as advisory for this app's lower declared minimum; confirm any version-specific API against the installed SDK and current project source.
- When the shared skill is available, search one UX query (`--domain ux`) and one Flutter stack query (`--stack flutter`). Verify returned categories and top result identity. Retry once with a narrower query if off-topic; never persist unverified output.

## Motion rules

- Start from the user action/state change; motion is feedback, not a substitute for clear hierarchy or state.
- Keep motion restrained: animate only the elements needed to explain a transition. Avoid decorative infinite motion, repeated bounce, scroll-jacking, and stacked effects.
- Prefer Flutter implicit animation widgets for a simple property transition. Use an `AnimationController` only when sequencing or fine-grained control justifies it; dispose controllers and associated listeners/tickers.
- Choose duration, curve, and distance for the specific component and platform. The shared skill's 150–300 ms range is a reference, not a universal token or requirement. Reuse an existing motion token if the app has one; do not invent a global timing system for a one-off animation.
- Read `MediaQuery.of(context).disableAnimations`. When true, present the same final content/state immediately or use a minimal alternative. Preserve actions, semantics, focus, navigation/back behavior, and cancellation safety.
- Set semantic/business state independently of animation completion. A cancelled or reversed animation must not leave a control disabled, a route stuck, or the semantic state stale.
- Keep long-running/loading motion tied to a real loading state and provide an accessible status where needed. Profile before adding performance workarounds.

## Verification

For runtime UI changes, add or update a focused widget test only when it protects observable behavior. Cover relevant initial/intermediate/final states, reverse/dismissal, interruption, and `disableAnimations`; do not assert implementation details or only that a widget exists. Inspect the real app surface when available and do not equate a widget test with device-level visual proof.

Run the narrowest applicable commands from the Flutter app root:

```sh
flutter test --no-pub <focused_test.dart> --reporter expanded
flutter analyze <changed_file.dart> <focused_test.dart>
dart format --set-exit-if-changed <changed_files.dart>
```

Do not run project-wide suites for a small change unless its scope requires them. This skill setup itself changes no app runtime code and needs no Flutter build or visual-release claim.

## Verified guidance

The checked-in UI/UX Pro Max catalogs currently return: honor reduced motion; avoid excessive simultaneous motion; choose timing for context rather than using 150–300 ms as a universal rule; prefer implicit Flutter animations for simple changes; dispose explicit animation controllers. The stack results identify Flutter 3.44.x, so check compatibility against the app's actual SDK before using any API recommendation.
