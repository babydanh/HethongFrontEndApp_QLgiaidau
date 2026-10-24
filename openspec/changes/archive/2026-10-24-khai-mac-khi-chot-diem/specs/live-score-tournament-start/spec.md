## ADDED Requirements

### Requirement: Distinguish tournament-not-started score errors
The App MUST preserve the API error code `TOURNAMENT_NOT_STARTED` as a typed domain error for tournament match score updates. The score notifier MUST display a localized tournament-not-started message before generic HTTP 409 revision-conflict handling. The App MUST NOT provide a tournament-launch action.

#### Scenario: Tournament has not started
- **WHEN** a tournament match score update returns HTTP 409 with code `TOURNAMENT_NOT_STARTED`
- **THEN** the notifier displays the localized tournament-not-started message, not the revision-conflict message.

#### Scenario: Revision conflict
- **WHEN** a score update returns another HTTP 409 error
- **THEN** the notifier retains the existing revision-conflict behavior.