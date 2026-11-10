## Approach

Bounded change on existing screens. Reuse `GroupStageView` (public) and add optional edit params instead of building a second layout:

- `GroupStageView({..., GroupStageConfig? editableConfig, Future<void> Function(GroupStageConfig next)? onConfigChanged, bool editLocked = false})`. Null `onConfigChanged` = today's read-only behaviour.
- Team cells wrapped in `LongPressDraggable<String>(delay: bracketDragDelay)` (participant id); each `_GroupCard` is a `DragTarget<String>`. Drop computes `next = config.moveParticipant(id, targetGroup)` and calls `onConfigChanged`.
- Save logic moves from `GroupStageAssignmentScreen._save` into one reusable function (`saveGroupAssignment` in `lib/features/bracket/utils/`), used by both the old screen and the new edit mode. It keeps: PATCH config, invalidate providers, regenerate (`allowReset: true`) only when no group match started.
- `bracket_view_screen.dart`: when `canManageGroupAssignment`, the `hasGroupStage` branch renders `PublicBracketView` in edit mode; `_buildGroupStageTabBar`, `_buildManageGroupStageButton` and the now-unused helpers are removed. `BracketManagementBar` stays.

## Rejected

- Fork a management-only copy of the group UI: duplicates ~600 lines and drifts from the public page.
- Keep the old assignment screen as the only way to move teams: does not meet "kéo thả đầy đủ".
