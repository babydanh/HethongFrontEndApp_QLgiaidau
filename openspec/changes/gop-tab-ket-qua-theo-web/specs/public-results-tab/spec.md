## ADDED Requirements

### Requirement: One results tab, last in the tab bar

The public tournament screen SHALL show a single "Kết quả" tab as the last tab and MUST NOT show a separate "Đang diễn ra" tab.

#### Scenario: Tab order

- **WHEN** a tournament in progress has sponsors
- **THEN** the tab bar ends with "Nhà tài trợ" followed by "Kết quả"

#### Scenario: Live badge

- **WHEN** two matches are in play
- **THEN** the "Kết quả" tab shows a live dot and the count 2

### Requirement: Finished division shows the podium and the final only

A division with official results SHALL show its podium above the board, and the board SHALL list only the final match(es) when the bracket is knockout.

#### Scenario: Finished knockout division

- **WHEN** a single-elimination division has official results
- **THEN** the podium is shown and the board lists only the last round
- **AND** tapping the podium opens the share sheet

#### Scenario: Division not finished

- **WHEN** a division has no official results
- **THEN** no podium and no empty-result card are shown
- **AND** the board lists all rounds

#### Scenario: Round robin division with results

- **WHEN** a division without a knockout final has official results
- **THEN** the podium is shown and the board lists all rounds
