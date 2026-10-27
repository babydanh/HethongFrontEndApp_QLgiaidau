## ADDED Requirements

### Requirement: Founder block follows the contact-info hidden flag
The app SHALL render the tournament founder (creator avatar and name) in the intro, overview and about tabs only when `contactInfo.hidden` is exactly `false` and `contactInfo.displayMode` is not `MANUAL`, matching the Web detail page.

#### Scenario: Default is hidden
- **WHEN** a tournament has no `contactInfo` or no `hidden` flag
- **THEN** no founder name, avatar or "BAN TỔ CHỨC GIẢI ĐẤU" section is shown

#### Scenario: Explicitly shown
- **WHEN** `contactInfo.hidden` is `false` and `displayMode` is not `MANUAL`
- **THEN** the founder block is shown

### Requirement: Managers can toggle founder visibility from the management hub
The tournament management overview SHALL show the founder row to managers even while hidden, with an eye button that writes `contactInfo.hidden` (preserving the other `contactInfo` keys), as on the Web.

#### Scenario: Manager shows a hidden founder
- **WHEN** a manager taps the eye button while the founder is hidden
- **THEN** `contactInfo.hidden` is saved as `false` and the public pages show the founder

#### Scenario: Double tap while saving
- **WHEN** the manager taps the eye button again before the save finishes
- **THEN** only one save request is sent

#### Scenario: Public viewer
- **WHEN** a non-manager opens the overview
- **THEN** no eye button is rendered
