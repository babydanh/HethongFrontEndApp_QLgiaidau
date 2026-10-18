## ADDED Requirements

### Requirement: A recording day plays back as one continuous sequence

From the recording catalog sheet, the user SHALL be able to play the selected day. The app SHALL read `GET /livestream/matches/{matchId}/recordings/playlist?period=YYYY-MM-DD` and play its segments in order, starting the next segment when the current one ends.

#### Scenario: Day with three segments

- **WHEN** the playlist for `2026-10-18` returns segments `a.mp4`, `b.mp4`, `c.mp4`
- **THEN** playback starts at `a.mp4` and moves to `b.mp4` then `c.mp4` when each ends

#### Scenario: A segment fails

- **WHEN** `b.mp4` fails to load
- **THEN** it is marked as failed and playback continues with `c.mp4`

#### Scenario: Every segment fails

- **WHEN** all segments fail to load
- **THEN** the player shows `Không phát được bản ghi nào`

### Requirement: Only safe playlist segments are used

The repository SHALL keep only segments whose `url` is an absolute `https` URL and whose `name` is a plain file name, and SHALL keep the server's order.

#### Scenario: Unsafe segment

- **WHEN** the playlist contains a segment with `url` `http://x/a.mp4` or a `name` containing `/`
- **THEN** that segment is dropped and the others keep their order
