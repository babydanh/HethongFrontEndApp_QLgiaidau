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

## 3. Cửa sổ nhỏ (Picture-in-Picture, chỉ Android, không thêm package)
- [x] 3.1 Native: `supportsPictureInPicture` trong `AndroidManifest.xml`; `MainActivity.kt` có MethodChannel `vn.vnsport.quanlygiaidau/pip` (`isSupported`, `enter` 16:9 không bắt exception thành false, `pipChanged` gửi về Dart), không tự vào PiP. Tiêu chí: CHƯA build native; build qua `app-run.py`, thử bấm nút trên máy Android thật
  - Files: `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/vn/vnsport/quanlygiaidau/MainActivity.kt`
- [x] 3.2 Dart: `PipService` (ẩn nút khi không phải Android hoặc không hỗ trợ), nút PiP trên thanh trang xem lại và trang live, khoá khi chưa có khung hình; trong PiP trang chỉ còn video đang phát, ẩn thanh điều khiển, lớp giữa, overlay, bảng điểm. Tiêu chí: `flutter test --no-pub test/core/pip_service_test.dart test/match/match_replay_player_controls_test.dart` → exit 0
  - Files: `lib/core/services/pip_service.dart`, `match_replay_player.dart`, `live_video_player.dart`, `live_score_screen.dart`, `test/core/pip_service_test.dart`, `test/match/match_replay_player_controls_test.dart`

## 4. Overlay nằm trong video thật, co tỉ lệ theo bề rộng video
- [x] 4.1 Overlay nằm trong khung hình 16:9 thật (contain), không tràn ra dải đen hai bên khi fullscreen ngang: `LiveOverlayVideoFrame` bọc bảng điểm/H2H/sơ đồ; live player báo tỉ lệ thật qua `onAspectRatioChanged`; trang xem lại vẽ video kiểu contain (không kéo giãn). Tiêu chí: `flutter test --no-pub test/match/live_score_header_scoring_test.dart` (TC-LIVEOVL-13: dọc 411x231, fullscreen 890x411, 360x203) → exit 0
  - Files: `live_overlay_controls.dart`, `live_score_screen.dart`, `live_video_player.dart`, `live_video_box.dart`, `match_replay_player.dart`, `test/match/live_score_header_scoring_test.dart`, `test/match/fake_video_player_platform.dart`
- [x] 4.2 Hệ số co tỉ lệ thuận bề rộng video: `liveOverlayScale(w, share)` = `(w/400*share).clamp(0.45,1.2)`; H2H share 0.5 (rộng ~50% video, bỏ kẹp 220/420), sơ đồ và bảng điểm share 0.7. Tiêu chí: cùng lệnh 4.1 + `test/features/match/live_h2h_overlay_test.dart` → exit 0
  - Files: `live_overlay_controls.dart`, `viewer/live_h2h_overlay.dart`, `viewer/live_scoreboard_overlay.dart`, `live_score_screen.dart` (`_buildBracketOverlay`)
## 5. Fullscreen ngang: thấy trọn hình, sát tai thỏ (thay hướng cover của 2b154422)
- [x] 5.1 Trang live/xem lại ở landscape dùng contain (không BoxFit.cover, không cắt hai mép, bỏ `_wrapVideoUnderCutout`); giữ phần khác của 2b154422 (bỏ viền/shadow ở landscape). Hình 16:9 cao hết màn hình, đặt trong vùng an toàn; phần đen dư dồn về phía xa camera (padding.left > right: canh trái sát mép tai thỏ; right > left: canh phải; bằng nhau/không có tai thỏ: canh giữa). Nền hai bên đen. Tiêu chí: `flutter test --no-pub test/match/live_score_header_scoring_test.dart` (TC-LIVEOVL-14: 890x411, tai thỏ trái 44 / phải 44 / không) → exit 0
  - Files: `live_score_screen.dart` (`_buildViewerLandscape`), `live_video_player.dart` (contain), `live_video_box.dart`, `test/match/live_score_header_scoring_test.dart`
  - Giao-Nhận: overlay vẫn nhận rect video thật vì cả hộp video được bọc `AspectRatio(_videoAspect)` + `Align` rồi `LiveOverlayVideoFrame` nằm trong đó
- [x] 5.2 Test của 2b154422 `TC-FULLVID-01` (xem lại lấp kín hộp rộng) đổi theo hợp đồng mới: video thấy trọn, cao hết hộp, tỉ lệ 16:9. Tiêu chí: `flutter test --no-pub test/match/match_replay_live_video_box_test.dart` → exit 0
  - Files: `test/match/match_replay_live_video_box_test.dart`
