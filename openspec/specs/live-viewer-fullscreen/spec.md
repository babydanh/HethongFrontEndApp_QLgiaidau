# live-viewer-fullscreen Specification

## Purpose
Fullscreen and landscape viewing of a live match: overlay chat, back to live, readable chat while scrolling, and reporting a match.

## Requirements

### Requirement: Landscape fullscreen with overlay chat
The read-only live viewer page SHALL, in landscape, show no AppBar, fill the screen with the video, and draw the chat as a transparent panel on the right that can be hidden. A fullscreen button on the video SHALL toggle between portrait and landscape and SHALL restore orientation and system bars when the page is left.

#### Scenario: Viewer rotates to landscape
- **WHEN** a viewer opens the live page in landscape
- **THEN** the video fills the screen and the latest chat lines show over its right side with a comment input

#### Scenario: Chat hidden
- **WHEN** the viewer hides the overlay chat in landscape
- **THEN** only the video and the top controls remain

### Requirement: Back to live
The video player SHALL show a "Về live" button only while playback is more than a threshold behind the live edge, and tapping it SHALL seek to the live edge.

#### Scenario: Paused for a while
- **WHEN** playback is 12 seconds behind the live edge
- **THEN** the button is visible

#### Scenario: At live edge
- **WHEN** playback is within the threshold of the live edge or duration is unknown
- **THEN** the button is hidden

### Requirement: Chat stays readable
When the viewer has scrolled up in the chat, new messages SHALL NOT move the list and a "N tin mới" pill SHALL appear; tapping it SHALL scroll to the newest message. Consecutive messages from the same author within five minutes SHALL be grouped without repeating avatar and name.

#### Scenario: New message while scrolled up
- **WHEN** the viewer is scrolled up and a comment arrives
- **THEN** the pill shows the count of unseen messages

#### Scenario: Same author twice
- **WHEN** an author posts two messages one minute apart
- **THEN** the second shows only its text bubble

### Requirement: Report a match
The viewer page SHALL offer a Báo cáo chip that opens the report sheet for the match.

#### Scenario: Signed-in viewer reports
- **WHEN** a signed-in viewer taps Báo cáo
- **THEN** the report sheet opens with target type match and the match id
