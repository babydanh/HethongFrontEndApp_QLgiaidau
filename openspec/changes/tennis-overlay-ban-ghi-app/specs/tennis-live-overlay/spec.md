## ADDED Requirements

### Requirement: Every tennis point reaches the Backend
The score panel SHALL send each live point to `PATCH /matches/:id/score` and, when a live write fails transiently (timeout, dropped connection, unknown network error or 5xx), SHALL resend the newest local score with backoff (0.5 s doubling to 8 s) without waiting for another tap. A refused write (4xx, including 403 and 409) MUST NOT be resent and the sync warning MUST stay. Writes MUST stay one at a time and the last write MUST carry the newest score.

#### Scenario: Write fails, referee stops tapping
- **WHEN** the write of 30-0 → 40-0 times out twice and the referee taps nothing more
- **THEN** the panel resends and the Backend receives 40-0, and the sync warning clears

#### Scenario: Refused write
- **WHEN** the write is refused with 403 or 409
- **THEN** it is sent once only and the sync warning stays

#### Scenario: Taps during a write
- **WHEN** three points are taken while a write is in flight
- **THEN** they are sent after it and the last write carries 40-40

### Requirement: App plays the recording like the Web
The match video SHALL ask the Backend for the live stream and the recording again when the screen is opened again and when the match status changes, and a failed recording lookup MUST be retried instead of being kept as "no recording".

#### Scenario: Reopen after the match ended
- **WHEN** a viewer opened the match before the recording existed, left, and opens it again
- **THEN** the recording is looked up again and plays

#### Scenario: Status changes on screen
- **WHEN** the match goes from ONGOING to COMPLETED while the screen is open
- **THEN** the recording is looked up again

### Requirement: Tennis overlay follows tennis rules
For tennis only, the scoreboard over the live video and the replay SHALL show the games of every started set (set 1 always; a later set once it has a game, or a point while it is the set in play) and the point of the game as 0/15/30/40/AD (40-40 at deuce, numbers in a tie-break), reading App int indexes and Web strings. Other sports MUST keep the existing scoreboard.

#### Scenario: Live point
- **WHEN** scoreDetails has set 1 at 0-1 and tennisPointState 2-0
- **THEN** the board shows S1 0/1 and the point 30 / 0

#### Scenario: Set 2 not started
- **WHEN** set 1 closed 6-3 and set 2 is 0-0 with no point played
- **THEN** only S1 shows

#### Scenario: Advantage
- **WHEN** tennisPointState is 4-3
- **THEN** the point shows AD / 40
