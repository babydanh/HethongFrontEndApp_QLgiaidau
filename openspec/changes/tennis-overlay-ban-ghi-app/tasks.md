## 1. Điểm từng pha lên Backend
- [x] 1.1 Ghi điểm live lỗi tự gửi lại bản mới nhất có lùi thời gian. Tiêu chí: `test/match/score_panel_live_sync_retry_test.dart` (TC-TENNIS-OVL-APP-01, 02) xanh trên CI nhánh
  - Files: sửa `lib/features/match/notifiers/score_panel_notifier.dart`; test `test/match/score_panel_live_sync_retry_test.dart`
  - Giao: (không đổi API) · Nhận: (không)
  - Chủ file chung: 1.1 giữ `score_panel_notifier.dart`
  - Phụ thuộc: (không)

## 2. App phát bản ghi như Web
- [x] 2.1 Provider live/bản ghi autoDispose, hỏi lại khi đổi trạng thái, lỗi tạm thử lại. Tiêu chí: `test/match/live_video_box_replay_refresh_test.dart` (TC-TENNIS-OVL-APP-03..05) xanh trên CI nhánh
  - Files: sửa `lib/features/match/widgets/live_video_box.dart`, một dòng `matchStatus:` trong `lib/features/match/screens/live_score_screen.dart`; test `test/match/live_video_box_replay_refresh_test.dart`
  - Giao: `LiveVideoBox(matchStatus: String?)` · Nhận: (không)
  - Chủ file chung: 2.1 và 3.1 cùng sửa `live_score_screen.dart`, làm tuần tự
  - Phụ thuộc: (không)

## 3. Overlay tennis theo luật
- [x] 3.1 Cột game từng set đã bắt đầu + ô điểm 0/15/30/40/AD cho live và replay; môn khác giữ nguyên. Tiêu chí: `test/match/tennis_scoreboard_overlay_test.dart` (TC-TENNIS-OVL-APP-06..08) xanh trên CI nhánh
  - Files: mới `lib/features/match/widgets/viewer/tennis_scoreboard_columns.dart`, `lib/features/match/widgets/viewer/tennis_live_scoreboard_overlay.dart`; sửa khối `_liveScoreOverlay` trong `lib/features/match/screens/live_score_screen.dart`; test `test/match/tennis_scoreboard_overlay_test.dart`
  - Giao: `tennisScoreboardSetColumns`, `tennisScoreboardPoints`, `isTennisScoreboardMatch`, `TennisLiveScoreboardOverlay` · Nhận: `readTennisGamePointDisplay`, `activeSetIndex`, `matchReplayScoreAt`
  - Chủ file chung: xem 2.1
  - Phụ thuộc: 2.1
