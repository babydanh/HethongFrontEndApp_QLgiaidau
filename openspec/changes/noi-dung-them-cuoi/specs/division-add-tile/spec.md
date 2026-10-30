## ADDED Requirements

### Requirement: Add tile at the end of the list
The divisions tab SHALL show an "+ Thêm nội dung" tile as the last item of the division list, directly under the last card, and SHALL NOT use a floating button.

#### Scenario: Tab opens with divisions
- **WHEN** the tab opens and the tournament has divisions
- **THEN** the add tile is shown right under the last card
- **AND** no floating action button is shown

#### Scenario: Tap the tile
- **WHEN** the user taps the add tile
- **THEN** the division editor opens
