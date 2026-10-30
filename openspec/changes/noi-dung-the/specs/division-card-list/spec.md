## ADDED Requirements

### Requirement: Division cards without group labels
The divisions tab SHALL render each division as its own bordered card separated from the next by a gap, and SHALL NOT show match-type group labels.

#### Scenario: Singles and doubles divisions
- **WHEN** the tournament has singles and doubles divisions
- **THEN** each division is a separate card with a gap of at least 6dp between cards
- **AND** no "ĐƠN" or "ĐÔI" group label is shown

### Requirement: Expandable card with full info
A division card SHALL expand on tap with an animation to show type, format, registered count, registration state, and (when set) ELO range and own fee; only one card SHALL be open at a time.

#### Scenario: Open a card
- **WHEN** the user taps a collapsed card
- **THEN** the card expands and shows the info rows

#### Scenario: Open another card
- **WHEN** a card is open and the user taps a different card
- **THEN** the first card collapses and the second expands

### Requirement: Edit and menu on the closed card
Each division card SHALL show an edit button and a ⋮ actions menu on its summary row, without opening the card.

#### Scenario: Closed card
- **WHEN** a card is collapsed
- **THEN** its row shows the edit button and the ⋮ menu

### Requirement: Add button at the bottom
The tab SHALL offer adding a division through a "+" floating button at the bottom over a white fade, and SHALL NOT show a text add button at the top.

#### Scenario: Tab opens
- **WHEN** the tab opens
- **THEN** a "+" button with the add-division tooltip is shown over a bottom fade
- **AND** no ⋮ menu is shown above the list
