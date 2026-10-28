## ADDED Requirements

### Requirement: Shared drop-down search and filter bar
The app SHALL provide one search icon that toggles an animated bar (search box, filter chips, result count with clear action) under the toolbar of each list tab, with the query and filters remembered per tab.

#### Scenario: Toggle the bar
- **WHEN** the user taps the search icon
- **THEN** the bar opens with the search box focused, and tapping the icon again hides it while keeping the query and filters

#### Scenario: Badge shows active filters
- **WHEN** the bar is hidden while a query or a filter is active
- **THEN** the search icon shows a badge with the number of active conditions

#### Scenario: Clear filters
- **WHEN** the user taps "Xoá lọc"
- **THEN** the query and all filters of that tab reset, other tabs are untouched

#### Scenario: No match
- **WHEN** nothing matches
- **THEN** the bar shows "0 kết quả" and the clear action

### Requirement: Schedule grid fades non-matching cards
The Lịch grid SHALL keep every card in place, fading cards that do not match to opacity 0.22 and outlining matching ones.

#### Scenario: Query typed on the schedule tab
- **WHEN** the query matches two cards
- **THEN** those two are outlined and all others are dimmed but not moved

### Requirement: Athlete tab search
The VĐV tab SHALL filter participants by name and by approval and payment status using the shared bar.

#### Scenario: Unpaid filter
- **WHEN** the user selects the unpaid fee filter
- **THEN** only unpaid participants are listed and divisions with none are hidden
