## ADDED Requirements

### Requirement: Flat division list with icon meta
The divisions tab SHALL show one primary add button, no repeated title, and each division row SHALL show its name plus icons (bracket type, max participants with number, registration state) instead of sentences.

#### Scenario: Row shows icons not sentences
- **WHEN** a division has a bracket type and a max participants value
- **THEN** the row shows the bracket icon and the groups icon with the number
- **AND** the row does not show the bracket or match type as text

#### Scenario: Header is minimal
- **WHEN** the tab opens
- **THEN** exactly one FilledButton "Thêm nội dung" is shown and the bulk action lives in the header menu

### Requirement: Group by match type and search
Division rows SHALL be grouped by match type with a label showing the group count when at least two groups exist, SHALL show registered over max participants, and SHALL offer a name search when there are more than 8 divisions.

#### Scenario: Two match types
- **WHEN** the tournament has singles and doubles divisions
- **THEN** a label per group with its count is shown above its rows

#### Scenario: Long list search
- **WHEN** there are 9 divisions and the user types part of a name
- **THEN** only matching rows remain, or an empty message if none match

