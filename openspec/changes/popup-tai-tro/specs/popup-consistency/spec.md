## ADDED Requirements

### Requirement: Sponsors tab shows sponsors without a logo
The public tournament page SHALL list every public sponsor that has a name, even when its logo is missing, and SHALL show the tab whenever at least one such sponsor exists. A sponsor without a logo SHALL show its initials in place of the picture.

#### Scenario: Only a logo-less sponsor
- **WHEN** the tournament has one public sponsor with a name and an empty logo
- **THEN** the sponsors tab is present
- **AND** the card shows the sponsor's initials

#### Scenario: Sponsor without a name
- **WHEN** a sponsor has an empty display name
- **THEN** it is not listed

### Requirement: Popups share one look
Bottom sheets and dialogs that do not draw their own frame SHALL take their shape and background from the app theme, and bottom sheets SHALL show a drag handle.

#### Scenario: Themed bottom sheet
- **WHEN** a themed bottom sheet opens
- **THEN** it shows a drag handle
- **AND** its top corners use the theme radius of 24

#### Scenario: Themed dialog
- **WHEN** a dialog opens without its own shape
- **THEN** it uses the theme radius of 20 with a hairline border

### Requirement: Podium labels follow the medal tone
The end-of-tournament confirmation sheet SHALL colour each podium label to match its medal: warm for gold and bronze, a neutral slate for silver, each at least 4.5:1 against its fill.

#### Scenario: Three medals
- **WHEN** the sheet shows first, second and third place
- **THEN** the gold and bronze labels are warm and the silver label is neutral
