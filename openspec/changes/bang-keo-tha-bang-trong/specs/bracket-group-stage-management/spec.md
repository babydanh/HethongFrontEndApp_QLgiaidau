## ADDED Requirements

### Requirement: Empty groups accept drops in edit mode
In edit mode the group-stage view MUST show a drop card for every configured group, including groups that currently have no team, and a team dropped on it MUST move into that group.

#### Scenario: Drop a team on an empty group
- **WHEN** a manager drags a team onto a configured group that has no team yet
- **THEN** the config reports the team in that group

#### Scenario: Read-only view
- **WHEN** the view is not in edit mode
- **THEN** no empty-group card is shown

### Requirement: Unassigned teams are listed and draggable
In edit mode the view MUST list teams that belong to no group in an "unassigned" lane, and those teams MUST be draggable onto a group card.

#### Scenario: Drag an unassigned team into a group
- **WHEN** a manager drags a team from the unassigned lane onto a group
- **THEN** the config reports the team in that group and no longer unassigned

#### Scenario: No unassigned teams
- **WHEN** every team belongs to a group
- **THEN** the unassigned lane is not shown

### Requirement: Bracket tab has no settings icon
The bracket management bar MUST NOT show a settings icon, because the divisions tab is already on the hub tab bar.

#### Scenario: Organizer opens the bracket tab
- **WHEN** an organizer opens the Bảng đấu tab
- **THEN** the bar shows only the Create or Delete bracket button
