# Spec Delta

## Purpose

Khung video trên màn chi tiết trận đấu không hiển thị nút play trang trí ở giữa khi trận chưa có luồng phát, để trạng thái chưa có tín hiệu không bị chồng thêm một nút play giả.

## ADDED Requirements

### Requirement: Không có nút play trang trí ở giữa khung video khi chưa có luồng

The live score screen SHALL NOT render the decorative central play button over the video frame while the match has no playback URL. The video frame SHALL show the no-signal state. The play icon in the bottom control bar is not covered by this requirement and SHALL remain unchanged.

#### Scenario: Trận chưa có luồng phát
- **WHEN** the match playback provider resolves with no playback URL
- **THEN** the video frame shows the no-signal label "Chưa có tín hiệu phát trực tiếp", exactly one `Icons.play_arrow_rounded` remains in the frame, and that icon is inside the bottom control bar (a `Positioned` widget)

#### Scenario: Tải thông tin phát lỗi hoặc rỗng
- **WHEN** the match playback provider fails or resolves with empty data
- **THEN** the video frame shows the same no-signal label, and exactly one `Icons.play_arrow_rounded` remains in the frame, inside the bottom control bar
