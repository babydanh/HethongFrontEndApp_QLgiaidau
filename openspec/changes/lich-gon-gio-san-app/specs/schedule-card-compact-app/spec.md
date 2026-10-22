## ADDED Requirements

### Requirement: Compact time and court label on schedule cards
The schedule grid SHALL show the match time and a short court label together in the card header, SHALL strip a leading "Sân" word from the displayed court label, and SHALL keep the full court name available as tooltip or semantics label.

#### Scenario: Court named "Sân 3"
- **WHEN** a match at 09:30 on a court named "Sân 3" is rendered in the schedule grid
- **THEN** the card header shows "09:30" with a chip labelled "3" and the column header shows "3" with tooltip "Sân 3"

#### Scenario: Court name without the prefix or empty name
- **WHEN** a court is named "Trung tâm", or the name is blank or only "Sân"
- **THEN** the label is "Trung tâm" unchanged, and a blank or "Sân"-only name falls back to the trimmed original instead of an empty string

### Requirement: Stable court colour
Each court SHALL get a stable chip colour from an 8-tint palette by its column index (wrapping around), and the palette SHALL NOT use red, pink or violet tints.

#### Scenario: More courts than tints
- **WHEN** the tournament has 9 courts
- **THEN** court 9 uses the same tint as court 1

#### Scenario: Invalid index
- **WHEN** the court index is negative (court not in the column list)
- **THEN** the helper still returns a valid tint without throwing

### Requirement: Compact hour scale
The schedule grid SHALL default to a 112dp 15-minute slot, SHALL keep a doubles card of 15 minutes inside one slot, and SHALL clamp user resizing to 80..224dp.

#### Scenario: Default scale
- **WHEN** `ScheduleGrid` is built without `slotHeight`
- **THEN** consecutive 15-minute time labels are 112dp apart

#### Scenario: Resize beyond limits
- **WHEN** the user drags the scale handle far past either limit
- **THEN** the reported slot height stays within 80 and 224
