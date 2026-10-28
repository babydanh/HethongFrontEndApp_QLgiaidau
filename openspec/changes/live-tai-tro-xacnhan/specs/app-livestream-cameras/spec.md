## ADDED Requirements

### Requirement: Mở QR khoá phát cần xác nhận
The camera panel SHALL NOT show any publish URL, stream key or QR on the screen, and SHALL open the stream-key QR sheet only after the organizer confirms in a dialog.

#### Scenario: Chạm nút QR rồi huỷ
- **WHEN** the organizer taps the QR button of a PUSH camera and cancels the confirmation dialog
- **THEN** the QR sheet is not opened and no stream-key request is sent

### Requirement: Gán camera cho sân bằng chip chọn
Each court block SHALL show its assigned camera or a "no camera" label and a button that opens a chip picker of the tournament cameras; choosing a chip SHALL assign that camera to the court.

#### Scenario: Gán camera cho sân trống
- **WHEN** the organizer opens the picker of a court without camera and chooses a camera
- **THEN** the app assigns that camera to that court and refreshes the list

### Requirement: Dừng phát luôn hỏi lại
Stopping a live session SHALL always ask for confirmation first.

#### Scenario: Huỷ dừng phát
- **WHEN** the organizer taps stop and cancels the confirmation
- **THEN** the stop request is not sent
