## ADDED Requirements

### Requirement: Viewer scoreboard hugs the top-left of the video picture
In portrait the viewer header bar SHALL sit above the video picture (not over it), and the scoreboard overlay SHALL be drawn at the top-left corner of the picture. In fullscreen landscape, where the header floats over the video, the scoreboard SHALL start below it.

#### Scenario: Viewer opens a live match in portrait
- **WHEN** a viewer opens a live match whose scoreboard is visible
- **THEN** the scoreboard top edge is at or below the header bar bottom, within 12 px of the top of the video picture, near its left edge

### Requirement: Other videos come from the suggestions API like the Web
The "Video khác" tab SHALL list the videos returned by `GET /livestream/matches/{matchId}/suggestions` (live now and replays), keeping the server order and loading the next page by cursor when the list is scrolled near its end. A replay SHALL be listed only when its duration is at least 180 seconds; a live match is always listed.

#### Scenario: Short replay is not suggested
- **WHEN** the API returns a replay of 120 seconds and a live match
- **THEN** only the live match is listed

#### Scenario: Next page
- **WHEN** the first page has a next cursor and the list is not full enough to scroll
- **THEN** the next page is requested with that cursor and its videos are appended without duplicates

### Requirement: Other videos list is uniform and filterable
Every suggestion SHALL use the same row layout (16:9 thumbnail with score and LIVE dot or duration, both side names, tournament and round, a "Replay" label for replays) and the tab SHALL provide pill filters All, Live, Replay and Same tournament.

#### Scenario: Filter by live
- **WHEN** the viewer selects the live filter while live and replay videos are offered
- **THEN** only the live videos remain listed

#### Scenario: Filter with no result
- **WHEN** the selected filter matches nothing
- **THEN** an empty-filter message is shown and the filter pills stay visible
