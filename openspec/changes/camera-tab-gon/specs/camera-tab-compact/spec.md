## ADDED Requirements

### Requirement: Match row exposes Bật cam / Tắt cam
The Camera tab SHALL show a visible "Bật cam" button on a match row that has a camera and is not live, and a "Tắt cam" button when the match is live. The buttons MUST call the same start/stop stream command as the ⋯ menu and MUST NOT appear when the tab is read-only or the match has no camera and is not live.

#### Scenario: Start a match with a camera
- **WHEN** an organizer opens a court popup whose match has a camera and taps "Bật cam"
- **THEN** the start-stream command is sent for that match

#### Scenario: Stop a live match
- **WHEN** the match is LIVE and the organizer taps "Tắt cam"
- **THEN** the stop-stream command is sent for that match

#### Scenario: Read-only tab
- **WHEN** the tournament is finished (read-only)
- **THEN** no Bật cam / Tắt cam button is shown and a "Chỉ xem" note explains that cameras cannot be added

### Requirement: Compact Camera tab layout
The court filter chips SHALL share one horizontal scroll row, and matches without a court SHALL NOT repeat the "Chưa có sân" chip on each row.

#### Scenario: Many courts
- **WHEN** a tournament has several courts
- **THEN** all court chips sit in a single horizontally scrollable row
