## 1. Nhập điểm mượt, bỏ toast thành công

- [x] 1.1 Guard chống bản chụp cũ đè điểm chưa gửi trong `ScorePanelNotifier`. Tiêu chí: `flutter test --no-pub test/match/score_panel_snapshot_race_test.dart` → exit 0 (đỏ trước khi sửa: Expected 2, Actual 1)
  - Files: sửa `lib/features/match/notifiers/score_panel_notifier.dart` (`_updateStateFromMatch`, thêm `applyMatchSnapshot`); tạo `test/match/score_panel_snapshot_race_test.dart`
  - Giao: `applyMatchSnapshot(MatchModel)` (`@visibleForTesting`) · Nhận: (không)
  - Chủ file chung: 1.1 giữ `score_panel_notifier.dart`
  - Phụ thuộc: (không)
- [x] 1.2 Bỏ toast thành công/thông tin ở màn chấm điểm và sửa test theo. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_panel_actions_test.dart` → exit 0
  - Files: sửa `lib/features/match/widgets/pickleball_court_panel.dart`, `lib/features/match/screens/live_score_screen.dart`, `test/match/pickleball_court_panel_actions_test.dart`, `integration_test/xem_bam_diem_pickleball_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 1.2 giữ bốn file trên
  - Phụ thuộc: (không)
- [x] 1.3 Giảm rebuild: chỉ theo dõi tên đội và số người mỗi đội ở panel rally và tennis. Tiêu chí: `flutter test --no-pub test/match/rally_score_panel_serve_test.dart` và `test/match/tennis_score_panel_test.dart` → exit 0
  - Files: sửa `lib/features/match/widgets/rally_score_panel.dart`, `lib/features/match/widgets/tennis_score_panel.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 1.3 giữ hai file trên
  - Phụ thuộc: (không)

## 2. Kiểm tra cuối

- [x] 2.1 `flutter analyze --no-pub lib/features/match` → exit 0 (đã chạy), CI nhánh xanh và E2E cloud pickleball xanh. Tiêu chí: `cloud-test-runner.py run --target app-e2e --app-ref app-nhap-diem-muot --specs integration_test/xem_bam_diem_pickleball_test.dart` → exit 0
  - Files: (không sửa file)
  - Giao: (không) · Nhận: 1.1–1.3
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.3
