# Spec Delta

## Purpose

Khung video trên màn chi tiết trận đấu không hiển thị icon play trang trí khi trận chưa có luồng phát, để trạng thái chưa có tín hiệu không bị chồng các nút điều khiển giả.

## ADDED Requirements

### Requirement: Không có nút điều khiển giả trong khung video khi chưa có luồng

The live score screen SHALL NOT render decorative playback controls over the video frame. This covers the central play button and the bottom control bar, which shows a play icon, a hard-coded time, a hard-coded quality badge, and non-functional volume and fullscreen icons. While the match has no playback URL, the video frame SHALL show only the no-signal state. Playback controls SHALL appear only through `LiveVideoPlayer` when a playback URL exists.

#### Scenario: Trận chưa có luồng phát
- **WHEN** the match playback provider resolves with no playback URL
- **THEN** the video frame shows the no-signal label "Chưa có tín hiệu phát trực tiếp" and contains no `Icons.play_arrow_rounded`

#### Scenario: Tải thông tin phát lỗi hoặc rỗng
- **WHEN** the match playback provider fails or resolves with empty data
- **THEN** the video frame shows the same no-signal label and contains no `Icons.play_arrow_rounded`
