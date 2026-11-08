## 1. Luật giao bóng side-out cho Lite

- [x] 1.1 Bỏ `!isOpenScoring` ở luật side-out, thêm `isPickleballSideOut`. Tiêu chí: `flutter test --no-pub test/match/pickleball_serve_number_test.dart`, `test/match/pickleball_court_panel_actions_test.dart`, `test/match/pickleball_court_widget_test.dart` → exit 0 (TC-LPK-APP-01..07, 10; đỏ trước khi sửa: Expected false/['switchServer'])
  - Files: sửa `lib/features/match/notifiers/score_panel_state.dart`, `lib/features/match/notifiers/score_panel_notifier.dart`, `lib/features/match/widgets/pickleball_court_panel.dart`, 3 file test trên
  - Giao: getter `ScorePanelState.isPickleballSideOut` · Nhận: (không)
  - Chủ file chung: 1.1 giữ các file trên
  - Phụ thuộc: (không)

## 2. Chọn cách tính điểm khi tạo giải

- [x] 2.1 Helper payload, picker và nối vào hai màn tạo giải Lite. Tiêu chí: `flutter test --no-pub test/lite/lite_pickleball_scoring_test.dart` → exit 0 (TC-LPK-APP-08, 09; đỏ trước: thiếu file/hàm)
  - Files: tạo `lib/features/tournament/utils/lite_pickleball_scoring.dart`, `lib/features/tournament/widgets/lite_pickleball_scoring_picker.dart`, `test/lite/lite_pickleball_scoring_test.dart`; sửa `lib/features/community/screens/create_club_tournament_screen.dart`, `lib/features/tournament/screens/create_public_quick_tournament_screen.dart`
  - Giao: `LitePickleballScoring`, `litePickleballScoringPayload` · Nhận: (không)
  - Chủ file chung: 2.1 giữ các file trên
  - Phụ thuộc: (không)

## 3. Kiểm tra cuối

- [x] 3.1 `flutter analyze --no-pub` trên các file đã sửa → exit 0. Tiêu chí: các test ở 1.1, 2.1 cùng `test/lite/lite_test.dart`, `test/match/official_score_modal_pickleball_court_test.dart` → exit 0
  - Files: (không sửa file)
  - Giao: (không) · Nhận: 1.1, 2.1
  - Chủ file chung: (không)
  - Phụ thuộc: sau 2.1
