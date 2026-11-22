## 1. Luật thuần

- [ ] 1.1 Viết test đỏ rồi tạo `tennis_serve_state.dart` port từ `C:/Users/GIGABYTE/.lavish/tennis-doi/tennis-rules.js` (người nhận mặc định, không bắt buộc chọn). Tiêu chí: `flutter test --no-pub test/domain/tennis_serve_state_test.dart` → exit 0
  - Files: tạo `lib/domain/services/tennis_serve_state.dart`; test `test/domain/tennis_serve_state_test.dart` (TC-TENNIS-SERVE-01..)
  - Giao: `class TennisCourtState { fromJson, toJson, copyWith }`, `class TennisScoreInput`, `TennisServe tennisServeOf(TennisScoreInput, TennisCourtState)` (`team`, `playerIndex`, `serveRight`), `TennisReceiver tennisReceiverOf(...)`, `bool tennisIsLocked(score, court, int team, TennisRole role)`, `TennisCourtState? tennisPickServer/tennisPickReceiveRight/tennisCorrectServer/tennisFixReceiver/tennisChooseDecidingReceiver(score, court, int team, int playerIndex)`, `TennisCourtState tennisToggleEnds(TennisCourtState)` cho 2.1 · Nhận: (không)
  - Phụ thuộc: (không)

## 2. Notifier dùng luật mới và lưu server

- [ ] 2.1 Tennis đôi trong notifier lấy người giao/nhận/khoá từ `TennisCourtState` (cầu lông, tennis đơn giữ nguyên); thêm `tennisCourt` vào state và undo; khôi phục ở `_hydrateState`; lưu tuần tự qua `updateCourtState`. Tiêu chí: `flutter test --no-pub test/match/score_panel_notifier_racket_test.dart test/match/score_panel_notifier_tennis_test.dart test/match/racket_court_drag_test.dart` → exit 0
  - Files: sửa `lib/features/match/notifiers/score_panel_state.dart:89-146,302`, `score_panel_racket.dart:31-110`, `score_panel_notifier.dart:325-437,551-653,989-1160`, `lib/features/match/utils/racket_court_drag.dart`; test `test/match/score_panel_notifier_racket_test.dart`
  - Giao: notifier `List<TennisCellAction> racketTennisActions(int team, int playerIndex)`, `bool racketApplyTennisAction(TennisCellAction)`, getter `RacketHint? racketHint` cho 3.1 · Nhận: các hàm của 1.1
  - Chủ file chung: 2.1 giữ `score_panel_notifier.dart`
  - Phụ thuộc: sau 1.1

## 3. Giao diện và chuỗi vi/en

- [ ] 3.1 `RacketCourtPanel`/`RacketCourtView`: chạm ô mở menu theo `racketTennisActions`, dòng nhắc theo `racketHint`; thêm key vào `app_vi.arb` và `app_en.arb`, chạy `flutter gen-l10n`. Tiêu chí: `flutter test --no-pub test/match/racket_court_panel_test.dart test/match/racket_court_view_test.dart` → exit 0 (có ca 320 px và 768 px không tràn)
  - Files: sửa `lib/features/match/widgets/racket_court_panel.dart`, `racket_court_view.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (+ file sinh `app_localizations*.dart`); test `test/match/racket_court_panel_test.dart`
  - Giao: (không) · Nhận: `racketTennisActions`, `racketApplyTennisAction`, `racketHint` từ 2.1
  - Chủ file chung: 3.1 giữ hai file `.arb`
  - Phụ thuộc: sau 2.1

## 4. Kiểm tra cuối

- [ ] 4.1 Phân tích và test liên quan. Tiêu chí: `flutter analyze --no-pub lib/domain/services lib/features/match` → không lỗi mới; `flutter test --no-pub test/domain/tennis_serve_state_test.dart test/domain/tennis_rules_test.dart test/match/score_panel_notifier_racket_test.dart test/match/score_panel_notifier_tennis_test.dart test/match/racket_court_drag_test.dart test/match/racket_court_panel_test.dart test/match/racket_court_view_test.dart` → exit 0
  - Files: (không sửa)
  - Phụ thuộc: sau 3.1
