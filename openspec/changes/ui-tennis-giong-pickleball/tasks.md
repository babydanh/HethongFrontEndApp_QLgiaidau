## 1. Bảng Pickleball nhận điểm chữ

- [x] 1.1 `CourtScoreboard` nhận điểm chữ và các tham số tuỳ chọn; Pickleball không đổi. Tiêu chí: `flutter test --no-pub test/match` → exit 0
  - Files: sửa `lib/features/match/widgets/pickleball_court_scoreboard.dart`, `lib/features/match/widgets/pickleball_court_controls.dart`
  - Giao: `CourtScoreboard({..., String Function(int team)? scoreTextOf, bool Function(int team)? canRemovePoint, void Function(int team, int playerIndex)? onPlayerTap, String? setText, String sportIcon = 'pickleball'})`, `CourtMenuActions({..., VoidCallback? onPickServer})` · Nhận: (không)
  - Chủ file chung: 1.1 giữ hai file này
  - Phụ thuộc: (không)

## 2. Màn Tennis dùng bảng Pickleball

- [x] 2.1 `RacketCourtView` vẽ bằng `CourtScoreboard`, giữ chữ ký công khai; panel dùng menu ⋯ để chọn người giao. Tiêu chí: `flutter test --no-pub test/match/racket_court_view_test.dart test/match/racket_court_panel_test.dart` → exit 0
  - Files: sửa `lib/features/match/widgets/racket_court_view.dart`, `lib/features/match/widgets/racket_court_panel.dart`; xoá `lib/features/match/widgets/racket_court_bar.dart`; sửa hai test trên
  - Giao: `RacketCourtView` giữ đủ tham số hiện có, thêm `sportIcon = 'tennis'` · Nhận: `scoreTextOf`, `onPickServer` từ 1.1
  - Chủ file chung: 2.1 giữ `racket_court_view.dart`
  - Phụ thuộc: sau 1.1

## 3. Kiểm tra cuối

- [x] 3.1 Test liên quan ở máy xanh; `flutter analyze` thư mục đã sửa. Tiêu chí: `flutter test --no-pub test/match test/domain/racket_court_layout_test.dart test/domain/tennis_rules_test.dart test/domain/tennis_serve_state_test.dart` → exit 0 (698 test); `flutter analyze --no-pub lib/features/match` → exit 0 (cloud runner đang bị GitHub khoá nên không chạy analyze cả repo)
  - Files: (không sửa)
  - Giao: (không) · Nhận: kết quả 1.1, 2.1
  - Chủ file chung: (không)
  - Phụ thuộc: sau 2.1
