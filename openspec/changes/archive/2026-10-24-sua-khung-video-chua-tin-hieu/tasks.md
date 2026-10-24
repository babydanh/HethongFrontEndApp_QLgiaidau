# Tasks

## 1. Khung video

- [x] 1.1 `_NoSignalBox` bọc `AspectRatio(16 / 9)`. Xong khi: `flutter test --no-pub test/match/live_score_video_panel_test.dart` PASS ca "khung chưa có tín hiệu giữ tỉ lệ 16:9" (trước sửa: cao 63 px, kỳ vọng 230,6 px).

## 2. Kiểm chứng

- [x] 2.1 `flutter analyze --no-pub` hai file sửa không lỗi; cả file `live_score_video_panel_test.dart` PASS.

## Workflow follow-up

- Smoke trên máy: mở chi tiết một trận chưa có camera, khung đen đủ cao, bảng điểm không đè chữ.
