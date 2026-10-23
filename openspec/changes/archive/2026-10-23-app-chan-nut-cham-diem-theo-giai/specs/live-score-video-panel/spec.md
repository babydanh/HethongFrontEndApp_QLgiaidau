## ADDED Requirements

### Requirement: Khung chưa có tín hiệu giữ tỉ lệ 16:9

The no-signal state of the video frame SHALL be laid out at a 16:9 aspect ratio, the same as `LiveVideoPlayer`, so the score overlay, camera label and overlay chips never stack on a frame shorter than their own content.

#### Scenario: Trận chưa có luồng phát
- **WHEN** the match playback provider resolves with no playback URL and the frame is 360dp wide
- **THEN** the no-signal frame is 202.5dp high and the no-signal label is fully visible
