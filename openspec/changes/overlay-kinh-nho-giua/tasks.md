## 1. Overlay kính mờ
- [x] 1.1 Helper dùng chung (hệ số co, blur, nút đóng + khung) và H2H có logo Sporto. Tiêu chí: `flutter test --no-pub test/features/match/live_h2h_overlay_test.dart test/features/match/live_overlay_controls_test.dart` → exit 0
  - Files: `lib/features/match/widgets/live_overlay_controls.dart`, `lib/features/match/widgets/viewer/live_h2h_overlay.dart`, `test/features/match/live_h2h_overlay_test.dart`
  - Giao-Nhận: giao `liveOverlayScale`, `liveGlassBackdrop`, `LiveOverlayCloseFrame`, `LiveH2hOverlay(onClose:)`; nhận hợp đồng cũ của `LiveH2hOverlay` (tham số mới tùy chọn)
- [x] 1.2 Bảng điểm co nhỏ + kính, giữ góc trên trái. Tiêu chí: `flutter test --no-pub test/features/match/live_scoreboard_overlay_test.dart` → exit 0
  - Files: `lib/features/match/widgets/viewer/live_scoreboard_overlay.dart`, `test/features/match/live_scoreboard_overlay_test.dart`
  - Giao-Nhận: nhận `liveOverlayScale` và `liveGlassBackdrop` từ 1.1
- [x] 1.3 Màn trực tiếp: vị trí H2H/sơ đồ/bảng điểm theo bề rộng video, sơ đồ kính 80% x 72%. Tiêu chí: `flutter analyze --no-pub lib/features/match` → exit 0 và các test `test/match/live_score_*_test.dart` xanh
  - Files: `lib/features/match/screens/live_score_screen.dart` (chỉ khối Positioned overlay, `_buildH2hOverlay`, `_buildBracketOverlay`)
  - Giao-Nhận: nhận widget từ 1.1, 1.2; bỏ `_withCloseButton`

## 2. Sau khi xem trên máy thật
- [x] 2.1 Sơ đồ nằm gọn trong khung kính: `FittedBox(scaleDown)` trong `InteractiveViewer` (thu về vừa khung, véo để phóng). Tiêu chí: `flutter test --no-pub test/match/live_score_header_scoring_test.dart` (TC-LIVEOVL-12, video 400 và 360dp) → exit 0
  - Files: `lib/features/match/screens/live_score_screen.dart` (`_buildBracketOverlay`), `test/match/live_score_header_scoring_test.dart`
- [x] 2.2 H2H và sơ đồ cách đáy video 8dp; chỉ trượt lên trên thanh điều khiển (64dp) khi thanh đang hiện. Player báo qua `onControlsVisibleChanged` (LiveVideoBox -> LiveVideoPlayer / MatchReplayPlayer). Tiêu chí: cùng lệnh 2.1 → exit 0
  - Files: `live_score_screen.dart`, `live_overlay_controls.dart`, `live_video_box.dart`, `live_video_player.dart`, `match_replay_player.dart`
  - Giao-Nhận: giao callback `onControlsVisibleChanged`, nhận hằng `liveOverlayRestingInset`
- [x] 2.3 Mở lên có tiếng (volume 1) ở trang xem lại và trang live; nút tiếng vẫn bật/tắt. Tiêu chí: `flutter test --no-pub test/match/match_replay_player_controls_test.dart test/match/match_replay_live_video_box_test.dart` → exit 0
  - Files: `match_replay_player.dart`, `live_video_player.dart`, `test/match/match_replay_live_video_box_test.dart` (đổi kỳ vọng icon tiếng mặc định, hợp đồng cũ "tắt tiếng mặc định" đổi theo yêu cầu)
- [x] 2.4 Trang xem lại: chạm vào video hiện/ẩn lớp giữa (lùi 3s, phát/dừng, tiến 3s) cùng thanh dưới, tự ẩn sau 3s. Trang live không tua được nên giữ thanh dưới cũ, không thêm lớp giữa. Tiêu chí: cùng lệnh 2.3 → exit 0
  - Files: `match_replay_player.dart`, `lib/l10n/app_{vi,en}.arb` + `app_localizations*.dart` (sinh), `test/match/match_replay_player_controls_test.dart`
