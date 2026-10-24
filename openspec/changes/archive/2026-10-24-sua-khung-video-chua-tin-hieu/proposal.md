# Proposal

## Why

Màn "Chi Tiết Trận Đấu": trận chưa có luồng phát thì khung video chỉ cao vừa icon và một dòng chữ (63 px trên màn 412 px), nên bảng điểm, nhãn camera và chữ "Chưa có tín hiệu phát trực tiếp" đè lên nhau. `_NoSignalBox` (`lib/features/match/widgets/live_video_box.dart`) không có khung tỉ lệ, còn `LiveVideoPlayer` thì giữ 16:9 khi luồng chưa có metadata.

## What Changes

- `_NoSignalBox` bọc `AspectRatio(16 / 9)`, cùng tỉ lệ dự phòng với `LiveVideoPlayer`.

## Capabilities

### New Capabilities

- `match-video-frame`: kích thước khung video ở màn chi tiết trận.

### Modified Capabilities

(không có)

## Out of scope

- Không đổi `LiveVideoPlayer` (vẫn theo tỉ lệ thật của luồng).
- Không đổi vị trí bảng điểm, nhãn camera.
- Không đổi Backend/Web.

## Impact

- App: `lib/features/match/widgets/live_video_box.dart`, test `test/match/live_score_video_panel_test.dart`.
