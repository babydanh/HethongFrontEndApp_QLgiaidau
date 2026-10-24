# Tasks

## 1. Bảng điểm

- [x] 1.1 `_liveScoreOverlay`: `ConstrainedBox(maxWidth: 150)` + `IntrinsicWidth`, hàng dùng `Expanded` cho cột tên, chữ 11 px, ô điểm 26 px / 12 px. Xong khi: `flutter test --no-pub test/match/live_score_video_panel_test.dart` PASS hai ca "co theo tên ngắn" (trước: rộng 168 px) và "thẳng cột" (trước: lệch 67 px).

## 2. Kiểm chứng

- [x] 2.1 `flutter analyze --no-pub` file sửa không lỗi; `live_score_video_panel_test.dart`, `live_score_header_scoring_test.dart` PASS.
- [x] 2.2 Smoke trên máy (hot reload): trận "N. DANH – H. LINH" bảng gọn, hai ô điểm thẳng cột.
