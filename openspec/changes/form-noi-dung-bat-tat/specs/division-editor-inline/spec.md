## ADDED Requirements

### Requirement: Round rules are a switch on the row
The division editor SHALL show "Luật vòng" as a row with a switch; turning it on SHALL reveal the sport rule fields in place and turning it off SHALL hide them. A locked division SHALL keep the switch disabled.

#### Scenario: Turn the switch on and off
- **WHEN** the user turns the "Luật vòng" switch on
- **THEN** the points and sets fields appear under the row
- **WHEN** the user turns it off again
- **THEN** the fields disappear

### Requirement: ELO limits are always visible
The division editor SHALL show the participant limit, ELO range and entry fee controls without opening any section.

#### Scenario: Editor opens
- **WHEN** the editor opens
- **THEN** the participant limit and ELO switches are visible

### Requirement: No lock notice box
The division editor SHALL NOT show a text box at the top explaining why a division is locked.

#### Scenario: Division already has a bracket
- **WHEN** the editor opens for a division that already has a bracket
- **THEN** no lock notice text is shown at the top

### Requirement: Format illustration is animated
The format illustration dialog SHALL play a looping animation for the chosen format with replay and pause controls, and SHALL show only the final frame when the system asks for reduced motion.

#### Scenario: Open the illustration
- **WHEN** the user opens the illustration of a format
- **THEN** an animated stage plays and the replay and pause buttons are shown

#### Scenario: Reduced motion
- **WHEN** the system asks for reduced motion
- **THEN** the stage shows the final frame and no playback buttons
