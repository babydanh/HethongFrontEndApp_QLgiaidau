# Proposal

## Why

Bảng điểm đè video ở màn trận trực tiếp (`_liveScoreOverlay`, `lib/features/match/screens/live_score_screen.dart`) có cột tên cố định 132 px + ô điểm 36 px (tổng 168 px) dù tên viết tắt chỉ vài ký tự ("S. B"), che nhiều khung hình. Người dùng yêu cầu tối ưu kích thước 2026-10-19. Change đã archive `2026-10-17-live-no-signal-play-button` chốt giữ 132 px cho giống Web; change này thay quyết định đó cho App.

## What Changes

- Bảng rộng theo tên dài nhất, tối đa 150 px; mỗi hàng giãn hết bề rộng bảng (`Expanded`) để hai ô điểm luôn thẳng cột ở mép phải.
- Chữ tên 11 px (trước 12), ô điểm rộng 26 px (trước 36), số điểm 12 px (trước 14), padding gọn hơn.

## Capabilities

### New Capabilities

- `live-scoreboard-overlay`: kích thước và căn chỉnh bảng điểm đè video ở màn trận.

### Modified Capabilities

(không có)

## Out of scope

- Web giữ bảng điểm như cũ (App và Web sẽ khác kích thước); muốn đồng bộ thì làm change Web riêng.
- Không đổi nội dung bảng điểm, vị trí góc trên trái, cờ `scoreboardVisible`.

## Impact

- App: `lib/features/match/screens/live_score_screen.dart`, test `test/match/live_score_video_panel_test.dart`.
