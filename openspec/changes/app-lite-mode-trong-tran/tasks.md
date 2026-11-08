## 1. Đọc cờ theo trận và ghi qua API

- [x] 1.1 Gộp `matchConfig` lên `sportRules` (repo + `MatchModel.fromJson`), giữ cờ khi socket thiếu field; thêm `IMatchRepository.setPickleballScoring` + `ApiMatchRepository`. Tiêu chí: `flutter test --no-pub test/lite/lite_pickleball_scoring_test.dart` → exit 0 (TC-LMT-APP-01, 02)
  - Files: sửa `lib/domain/services/sport_rule_service.dart`, `lib/data/repositories/api/api_match_repository.dart`, `lib/domain/entities/match.dart`, `lib/domain/repositories/match_repository.dart`; test `test/lite/lite_pickleball_scoring_test.dart`
  - Giao: `withMatchConfigScoring`, `carryMatchConfigScoring`, `setPickleballScoring` · Nhận: (không)
  - Chủ file chung: 1.1 giữ các file trên
  - Phụ thuộc: (không)

## 2. Menu đổi cách tính điểm

- [x] 2.1 `ScorePanelNotifier.setPickleballScoring` + mục menu "Cách tính điểm" + nhãn ở hộp thông tin Lite + l10n. Tiêu chí: `flutter test --no-pub test/match/pickleball_scoring_menu_test.dart` → exit 0 (TC-LMT-APP-03, 04, 05)
  - Files: sửa `lib/features/match/notifiers/score_panel_state.dart`, `lib/features/match/notifiers/score_panel_notifier.dart`, `lib/features/match/widgets/pickleball_court_controls.dart`, `lib/features/match/widgets/pickleball_court_view.dart`, `lib/features/match/widgets/pickleball_court_panel.dart`, `lib/features/match/widgets/official_score_modal.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (+ file sinh); test `test/match/pickleball_scoring_menu_test.dart`
  - Giao: mục menu, `ScorePanelNotifier.setPickleballScoring` · Nhận: `setPickleballScoring` của 1.1
  - Chủ file chung: 2.1 giữ các file trên
  - Phụ thuộc: sau 1.1

## 3. Gỡ ô chọn ở màn tạo giải

- [x] 3.1 Bỏ ô chọn và payload ở hai màn tạo giải; xoá `lite_pickleball_scoring.dart`, `lite_pickleball_scoring_picker.dart`. Tiêu chí: `flutter test --no-pub test/lite/lite_create_no_scoring_choice_test.dart` → exit 0 (TC-LMT-APP-06); grep không còn `LitePickleballScoring`
  - Files: sửa `lib/features/community/screens/create_club_tournament_screen.dart`, `lib/features/tournament/screens/create_public_quick_tournament_screen.dart`; xoá hai file trên; test `test/lite/lite_create_no_scoring_choice_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 3.1 giữ các file trên
  - Phụ thuộc: (không)

## 4. Kiểm tra cuối

- [x] 4.1 `flutter analyze --no-pub` trên thư mục đã sửa + các test `test/match/pickleball_*`, `test/match/official_score_modal_pickleball_court_test.dart` → exit 0
  - Files: (không sửa file)
  - Giao: (không) · Nhận: 1.1, 2.1, 3.1
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.1, 2.1, 3.1
