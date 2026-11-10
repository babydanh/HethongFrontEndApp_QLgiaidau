## ADDED Requirements

### Requirement: Create-match dialog offers singles or doubles, default doubles

The create-match dialog SHALL offer only Singles and Doubles, SHALL open with Doubles selected, and SHALL send the `matchType` that the user chose.

#### Scenario: Dialog opens
- **WHEN** the host opens "Tạo trận đấu"
- **THEN** "Đôi" is selected, each team needs 2 players and no mixed-doubles option is shown

#### Scenario: Host switches to singles
- **WHEN** the host selects "Đơn" and picks 1 player per team
- **THEN** the submit button is enabled and the request carries `matchType` `SINGLES`

#### Scenario: Switching clears the selection
- **WHEN** the host changes between Đơn and Đôi after picking players
- **THEN** both teams are emptied and the submit button is disabled

#### Scenario: Incomplete teams
- **WHEN** a team has fewer players than the chosen type needs
- **THEN** the submit button stays disabled

### Requirement: Host chooses the format in a club-less session

The dialog SHALL show a "Thể thức" selector with "Một trận" and "Bracket" only when `allowBracket` is true, which is passed only for the host of a club-less social session. "Một trận" keeps the current flow.

#### Scenario: Club-less session host
- **WHEN** the host of a personal session opens the dialog
- **THEN** the selector is visible with "Một trận" selected

#### Scenario: Club flow
- **WHEN** the dialog is opened from a club without `allowBracket`
- **THEN** the selector is not rendered and the dialog behaves as before

### Requirement: Host creates a bracket from the dialog

In "Bracket" mode the host SHALL choose one of the four bracket types and the players, and submitting SHALL call `POST /api/v1/social-sessions/:id/bracket` and then open the created tournament.

#### Scenario: Successful creation
- **WHEN** the host picks a type, keeps at least the minimum players and taps "Tạo bracket"
- **THEN** exactly one request is sent, the button is disabled while it runs, and on 201 the dialog closes and the app opens `/tournaments/{tournamentId}`

#### Scenario: Too few or odd players
- **WHEN** the selection has fewer than 2 players for singles, or fewer than 4 or an odd number for doubles
- **THEN** the submit button is disabled and a hint shows the minimum

#### Scenario: Bracket already exists (409)
- **WHEN** the server answers 409 `SOCIAL_BRACKET_EXISTS` with a `tournamentId`
- **THEN** the app opens that tournament instead of showing an error

#### Scenario: Server rejects the request
- **WHEN** the server answers 400 or 403 (for example email not verified)
- **THEN** the server message is shown in a SnackBar, the dialog stays open and the button is enabled again

#### Scenario: Network failure
- **WHEN** the request times out or the network drops
- **THEN** a generic error SnackBar is shown and nothing navigates

### Requirement: Match tab links to the existing bracket

The social match tab SHALL show a "Xem bracket" button when the session has `bracketTournamentId`.

#### Scenario: Session has a bracket
- **WHEN** `bracketTournamentId` is non-null
- **THEN** the button is shown and opens `/tournaments/{bracketTournamentId}`

#### Scenario: Session has no bracket
- **WHEN** `bracketTournamentId` is null or absent from the response
- **THEN** no "Xem bracket" button is rendered
