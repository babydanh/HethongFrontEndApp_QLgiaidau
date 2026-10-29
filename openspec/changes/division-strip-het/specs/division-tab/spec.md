## ADDED Requirements

### Requirement: Hub has a divisions tab
The tournament management hub SHALL show a "Nội dung" tab right after the overview tab, and that tab SHALL host the divisions management screen.

#### Scenario: Open the divisions tab
- **WHEN** an organizer taps the "Nội dung" tab
- **THEN** the divisions management screen is shown inside the tab

#### Scenario: Manage chip jumps to the tab
- **WHEN** an organizer taps "Quản lý" on the bracket tab strip
- **THEN** the hub switches to the "Nội dung" tab

### Requirement: Draw screen picks a division with the shared strip
The draw screen SHALL let the organizer choose a division through `DivisionStrip` when the tournament has more than one division.

#### Scenario: Pick a division before saving the draw
- **WHEN** the organizer taps a division chip and saves the draw
- **THEN** the draw is generated for that division
