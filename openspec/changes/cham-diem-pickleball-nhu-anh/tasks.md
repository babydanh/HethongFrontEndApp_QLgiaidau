## 1. Màu đội và tách widget dùng chung
- [x] 1.1 Đổi màu đội (Đội 1 cam, Đội 2 xanh) và tách `CourtDraggable`/`CourtDropOutline` ra file riêng để bố cục mới dùng chung. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_view_layout_test.dart` → exit 0
  - Files: sửa `lib/features/match/widgets/pickleball_court_palette.dart`, `lib/features/match/widgets/pickleball_court_dialogs.dart:11-12`, `lib/features/match/widgets/pickleball_court_view.dart`; tạo `lib/features/match/widgets/pickleball_court_drag_widgets.dart`; test `test/match/pickleball_court_view_layout_test.dart`
  - Giao: `CourtDraggable({source, feedback, feedbackSize, child})`, `CourtDropOutline({active, radius, thick, child})` · Nhận: (không)
  - Chủ file chung: 1.1 giữ `pickleball_court_view.dart`
  - Phụ thuộc: (không)

## 2. Bố cục ngang kiểu bảng điểm
- [x] 2.1 Vẽ `CourtScoreboard` (hàng trên, sân 3 cột, thanh dưới, hộp thoại KẾT THÚC, đồng hồ) và gọi nó từ `PickleballCourtView` khi trục ngang. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_scoreboard_test.dart` → exit 0
  - Files: tạo `lib/features/match/widgets/pickleball_court_scoreboard.dart`; sửa `lib/features/match/widgets/pickleball_court_view.dart`, `lib/features/match/widgets/pickleball_court_controls.dart` (công khai nút ⋯), `lib/features/match/widgets/pickleball_court_panel.dart` (truyền giờ bắt đầu), `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/match/pickleball_court_scoreboard_test.dart`
  - Giao: `CourtScoreboard(...)` cùng tham số với `PickleballCourtView` + `startedAt: DateTime?` · Nhận: `CourtDraggable`, `CourtDropOutline` từ 1.1
  - Chủ file chung: 2.1 giữ `pickleball_court_view.dart`, `app_vi.arb`, `app_en.arb`
  - Phụ thuộc: sau 1.1

## 3. Cập nhật test cũ và kiểm tra cuối
- [x] 3.1 Sửa test ngang cũ cho khớp bố cục mới, giữ test dọc và test luật. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_view_layout_test.dart test/match/pickleball_court_widget_test.dart test/match/pickleball_court_panel_actions_test.dart test/match/official_score_modal_pickleball_court_test.dart test/match/pickleball_court_scoreboard_test.dart` → exit 0; `flutter analyze --no-pub lib/features/match` → exit 0
  - Files: sửa `test/match/pickleball_court_view_layout_test.dart`, `test/match/pickleball_court_widget_test.dart`, `test/match/pickleball_court_panel_actions_test.dart`, `test/match/official_score_modal_pickleball_court_test.dart` (chỉ chỗ vỡ)
  - Giao: (không) · Nhận: 2.1
  - Chủ file chung: 3.1 giữ bốn file test
  - Phụ thuộc: sau 2.1
