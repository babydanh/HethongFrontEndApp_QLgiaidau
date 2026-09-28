---
name: pub-dev-verifier
description: >
  Defensive dependency and Flutter package verifier. Automatically triggers whenever
  adding, importing, or upgrading third-party Dart/Flutter packages or dependencies.
  Prevents hallucinated packages and outdated API calls.
---

# Pub.dev Defensive Verifier

Whenever a task requires adding a new dependency, upgrading a package, or using an external library API:

## 1. No Hallucinated Packages
- **Never guess or assume package names, versions, or APIs.**
- Delegate package inspection to the **FREE Task subagent**:
  - Run `pub.dev` search or check `pubspec.yaml` via MCP or search tool.
  - Verify that the package is currently active, null-safe, and compatible with Flutter 3.x / Dart 3.x.

## 2. Minimal Dependencies (Ponytail Rule)
- Before adding ANY external package, ask:
  - Can this be solved with native Flutter/Dart SDK widgets and stdlib?
  - Does an existing package in `pubspec.yaml` already cover this?
- Only add new packages if strictly necessary and verified.

## 3. Delegation Workflow
- Let the `TASK` subagent (DeepSeek Flash - FREE) verify `pubspec.yaml` and test resolution with `flutter pub get`.
- Primary coder (Luna) only receives the confirmed package name and version string.
