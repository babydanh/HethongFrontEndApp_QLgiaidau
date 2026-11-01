## ADDED Requirements

### Requirement: Viewer header under the video
The live viewer page SHALL show, under the video, a title "A vs B" and a sub line with viewer count, tournament and round, ending with a "Xem thêm" action that opens the match details sheet. Beside it SHALL be round action chips: cheer (with count), share, and open tournament.

#### Scenario: Viewer taps Xem thêm
- **WHEN** a viewer taps "Xem thêm"
- **THEN** a details sheet opens with sets, ELO, rules, location and penalties while the video stays on screen

#### Scenario: No tournament known
- **WHEN** the match has no tournament id
- **THEN** the open-tournament chip is not shown and the other chips still work

### Requirement: Chat and Video khác tabs
The live viewer page SHALL have two tabs: Chat (selected first) and Video khác. Video khác SHALL list other live or upcoming matches of the same tournament first, excluding the current match, and tapping a card SHALL open that match.

#### Scenario: Other matches exist
- **WHEN** the tournament has another live match
- **THEN** it appears first in Video khác with a LIVE badge and its viewer-facing teams

#### Scenario: Nothing to suggest
- **WHEN** no other live or upcoming match exists
- **THEN** Video khác shows an empty message instead of a blank area
