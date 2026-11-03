## ADDED Requirements

### Requirement: Viewer scoreboard hugs the top-left of the video picture
In portrait the viewer header bar SHALL sit above the video picture (not over it), and the scoreboard overlay SHALL be drawn at the top-left corner of the picture. In fullscreen landscape, where the header floats over the video, the scoreboard SHALL start below it.

#### Scenario: Viewer opens a live match in portrait
- **WHEN** a viewer opens a live match whose scoreboard is visible
- **THEN** the scoreboard top edge is at or below the header bar bottom, within 12 px of the top of the video picture, near its left edge

### Requirement: Other videos list is uniform and filterable
The "Video khác" tab SHALL show every offered match as the same row layout (thumbnail, both side names, round and court) and SHALL provide All, Live and Upcoming filter chips.

#### Scenario: Filter by live
- **WHEN** the viewer selects the live filter while both live and upcoming matches are offered
- **THEN** only the live matches remain listed

#### Scenario: Filter with no result
- **WHEN** the selected filter matches nothing
- **THEN** the empty message is shown and the filter chips stay visible
