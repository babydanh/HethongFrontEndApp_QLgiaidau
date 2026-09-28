# Flutter app instructions

For work in this Flutter app, follow the workspace-level `../.github/copilot-instructions.md` and the required workflow artifacts. For any animation, transition, loading motion, or motion-accessibility task:

1. Read `.agents/skills/flutter-animation/SKILL.md` before editing.
2. When the shared workspace UI/UX Pro Max skill is available, load `../.agents/skills/ui-ux-pro-max/SKILL.md`; otherwise use the verified project-local guidance and do not claim a catalog result.
3. Respect `MediaQuery.of(context).disableAnimations`, preserve final state and navigation semantics, and test observable motion behavior when runtime UI changes.
4. Use existing Flutter dependencies and theme conventions. Do not add packages, edit APIs, or redesign unrelated screens just to implement motion.
5. Run focused Flutter tests, targeted `flutter analyze`, and Dart formatting for changed source; a widget test is not device-level visual proof.

This instruction file and the local skill are authoring guidance only; they do not change app runtime behavior.
