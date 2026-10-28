## ADDED Requirements

### Requirement: Finance page keeps bank details out of the page
The finance page SHALL show the entry fee and fee breakdown with a pinned save button, and SHALL collect bank details only inside a bottom sheet opened from a "request payout" row, after an explicit confirmation and with double-submit blocked.

#### Scenario: Bank form is not on the page
- **WHEN** an eligible organizer opens the finance page
- **THEN** no bank name, account number or account holder field is visible until the payout row is tapped

#### Scenario: Payout needs confirmation
- **WHEN** the organizer fills a valid payout form and taps send
- **THEN** a confirmation dialog is shown and no request is sent until it is confirmed

#### Scenario: Double tap while sending
- **WHEN** the organizer confirms and taps send again before the request finishes
- **THEN** only one payout request is sent

#### Scenario: Save fee button state
- **WHEN** the entry fee equals the saved value, or a save is running
- **THEN** the pinned save button is disabled

### Requirement: Team list is searchable and filterable
The team management list SHALL offer a name search, status chips (all, approved, pending) with counts, two-line names and a per-team menu for edit and delete.

#### Scenario: Filter by status
- **WHEN** the user selects the pending chip
- **THEN** only teams awaiting approval are listed

#### Scenario: Search by name
- **WHEN** the user types part of a team or member name
- **THEN** only matching teams are listed

### Requirement: Organizer can export a multi-sheet report
The management hub menu SHALL open a sheet where the organizer ticks which sheets to export, then exports them to one Excel file with the export button locked while running.

#### Scenario: Failure keeps the selection
- **WHEN** the export fails
- **THEN** an error is shown, the sheet stays open and the ticks are kept

#### Scenario: File name is sanitized
- **WHEN** the tournament name contains path separators, spaces or accents
- **THEN** the exported file name contains only letters, digits, `_`, `.` and `-`
