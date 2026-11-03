## ADDED Requirements

### Requirement: Viewer scoreboard sits below the header inside the video
The viewer scoreboard overlay SHALL be drawn at the top-left of the video area, starting below the viewer header bar, and SHALL NOT occupy the lower half of the video.

#### Scenario: Viewer opens a live match
- **WHEN** a viewer opens a live match whose scoreboard is visible
- **THEN** the scoreboard top edge is at or below the header bar bottom, near the video's left edge, and above the video's vertical center

### Requirement: Other videos list is uniform and filterable
The "Video khác" tab SHALL show every offered match as the same row layout (thumbnail, both side names, round and court) and SHALL provide All, Live and Upcoming filter chips.

#### Scenario: Filter by live
- **WHEN** the viewer selects the live filter while both live and upcoming matches are offered
- **THEN** only the live matches remain listed

#### Scenario: Filter with no result
- **WHEN** the selected filter matches nothing
- **THEN** the empty message is shown and the filter chips stay visible
