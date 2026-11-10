## ADDED Requirements

### Requirement: Management group-stage uses the shared public layout
The management Bảng đấu tab of a group-stage division MUST render the same group-stage view as the public tournament detail page, and MUST NOT show the legacy group tab bar or the separate "Quản lý bảng" button when the user can edit the bracket.

#### Scenario: Organizer opens a group-stage division
- **WHEN** an organizer with edit rights opens the Bảng đấu tab of a division that has a group stage
- **THEN** the group cards (Bảng chéo / Xếp hạng / Theo lượt) are shown through the shared view and the legacy group tab bar is absent

#### Scenario: Division has no groups yet
- **WHEN** the division has a group stage but no group has any team
- **THEN** the screen shows the existing empty state and does not throw

### Requirement: Managers can drag a team to another group
In edit mode a manager MUST be able to long-press a team cell and drop it onto another group card to move the team, and the change MUST be persisted through the existing division config update, then the bracket MUST be regenerated when no group match has started.

#### Scenario: Move a team between groups before matches start
- **WHEN** a manager drags team X from Bảng A onto Bảng B and no group match has started
- **THEN** the config is saved, the bracket is regenerated, the data reloads and X appears in Bảng B

#### Scenario: Matches already started
- **WHEN** at least one group match has a score or is completed
- **THEN** team cells are not draggable and no save request is sent

#### Scenario: Save fails
- **WHEN** the config update request fails (network or server error)
- **THEN** the view keeps the previously saved groups, a snackbar with the error is shown, and a second drop during the request is ignored

#### Scenario: Viewer without edit rights
- **WHEN** the user cannot edit the bracket
- **THEN** team cells are not draggable and the view is identical to the public one
