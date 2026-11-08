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
