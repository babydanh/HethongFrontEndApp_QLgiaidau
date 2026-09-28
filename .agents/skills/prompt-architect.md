---
name: prompt-architect
description: Automatic prompt structuring, intent analysis, and deterministic TODO checklist decomposition. Use for every coding, refactoring, or UI task to plan steps cleanly before editing files.
---

# Prompt Architect & Structured Task Decomposition (OMP Skill)

Whenever the user provides a task, feature request, bug fix, or refactoring prompt:

## 1. Intent Synthesis
- Analyze the user's intent directly.
- Identify the target files and state models.

## 2. Mandatory TODO Plan
Always initialize and maintain a structured task list:
- **I. Inspection & Audit**: Examine the relevant files.
- **II. Implementation**: Step-by-step code modifications.
- **III. Verification**: Run tests, typecheck, or linter.

Update progress with `- [x]` as each step finishes.
