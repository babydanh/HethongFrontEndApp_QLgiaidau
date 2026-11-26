## ADDED Requirements

### Requirement: New camera name is prefilled
The camera editor SHALL prefill the name field with "Cam N" (N = existing cameras + 1) when creating a camera, and MUST leave the name untouched when editing.

#### Scenario: Create with two existing cameras
- **WHEN** the organizer opens the create-camera form and the tournament has 2 cameras
- **THEN** the name field shows "Cam 3" and can be edited before saving

### Requirement: Court count stepper
The create-venue dialog SHALL show the initial court count as a stepper (minus, number, plus) defaulting to 1, clamped to 1..50, whose number can be typed.

#### Scenario: Default and bounds
- **WHEN** the dialog opens and the organizer taps minus
- **THEN** the count stays 1; typing 99 is clamped to 50

### Requirement: Create-camera button with no court
The Camera tab SHALL keep the create-camera button visible unless read-only; when the venues have loaded and there is no court, tapping it MUST show "Thêm sân trước khi tạo camera" and MUST NOT open the form. While venues load the button is disabled.

#### Scenario: No courts
- **WHEN** the tournament has no court and the organizer taps "+"
- **THEN** a snackbar asks to add a court first and no sheet opens

### Requirement: Camera block above courts, court label prefix
The Camera tab SHALL render the camera list right after the header, courts and matches below it. A court whose name is only digits SHALL display as "Sân <number>"; other names display unchanged and the stored name sent to the API is never changed.

#### Scenario: Numeric court name
- **WHEN** a court is named "3"
- **THEN** the court card, chips and camera rows show "Sân 3"
