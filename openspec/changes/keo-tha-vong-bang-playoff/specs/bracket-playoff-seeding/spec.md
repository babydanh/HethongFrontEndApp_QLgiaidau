## ADDED Requirements

### Requirement: Empty round-one playoff slots show their seed
The playoff board MUST show a seed label such as "Nhất A" or "Nhì B" in every empty round-one slot of the winners bracket when the division has a group stage playoff, and MUST keep "N/A" for other empty slots.

#### Scenario: Two teams advance per group
- **WHEN** a division has 4 groups with 2 advancing and the playoff slots are empty
- **THEN** the first match shows "Nhất A" against "Nhì B" and the second shows "Nhất B" against "Nhì A"

#### Scenario: No group stage playoff
- **WHEN** the division has no stage with a group advance mapping
- **THEN** empty slots keep showing "N/A"

### Requirement: Managers swap seeds by dragging
A manager MUST be able to long-press a seed label and drop it on another to swap them, saved through the seed-order endpoint. Viewers MUST see the labels without drag handles.

#### Scenario: Manager swaps two labels
- **WHEN** a manager drags "Nhất A" onto "Nhì B"
- **THEN** the app sends the slot order with those two slots exchanged

#### Scenario: Viewer
- **WHEN** the user cannot manage the tournament
- **THEN** labels are not draggable

### Requirement: Seeds lock when the playoff starts
Seed labels MUST NOT be draggable once any playoff match is live or completed, and a failed save MUST show an error message.

#### Scenario: A playoff match is live
- **WHEN** a non-bye playoff match is live
- **THEN** labels show but cannot be dragged

#### Scenario: Save fails
- **WHEN** the seed-order request fails
- **THEN** a snackbar shows "Không thể đổi vị trí"
