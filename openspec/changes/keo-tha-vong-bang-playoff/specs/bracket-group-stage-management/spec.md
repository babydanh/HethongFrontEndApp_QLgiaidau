## ADDED Requirements

### Requirement: Dragging near the edge scrolls the page
In edit mode the group-stage view MUST scroll its enclosing scrollable while a team is dragged near its edge.

#### Scenario: Drag to the bottom edge
- **WHEN** a manager holds a dragged team near the bottom edge of a long list of groups
- **THEN** the page scrolls down

### Requirement: Teams can be reordered inside a group
In edit mode a team dropped before another team of the same group MUST move to that position and the new order MUST be reported through the config.

#### Scenario: Move a team up
- **WHEN** a manager drops the second team of a group before the first
- **THEN** the config lists the dropped team first

### Requirement: Teams return to the unassigned lane
In edit mode a team MUST be droppable on the "Chưa xếp" lane, which MUST appear while a drag is in progress even when it is empty.

#### Scenario: Drop a team on Chưa xếp
- **WHEN** a manager drags a grouped team onto the lane
- **THEN** the config reports the team as unassigned
