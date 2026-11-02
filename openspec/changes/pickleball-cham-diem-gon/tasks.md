## 1. Chuỗi hiển thị

- [x] 1.1 Thêm key i18n cho popup, menu và tooltip mới vào `app_vi.arb` và `app_en.arb`, rồi sinh code. Tiêu chí: `flutter gen-l10n` → exit 0 và `grep -c pickleballCourtLoseServe lib/l10n/app_localizations.dart` ≥ 1
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (chèn cạnh nhóm `pickleballCourt*`); code sinh `lib/l10n/app_localizations*.dart` không sửa tay
  - Giao: key mới `pickleballCourtMenu`, `pickleballCourtFinishSet`, `pickleballCourtPickWinner`, `pickleballCourtLoseServe`. Dùng lại key có sẵn: `pickleballCourtActionSwitchEnds`, `pickleballCourtUndo`, `pickleballCourtRestoreAutomatic`, `pickleballCourtAutoSwitch`, `matchOverrideLabel`, `matchForceWin`, `matchFinishSet`, `scorePanel_matchNotReady`, `officialScore_overrideReasonHint`, `matchCancel`, `matchConfirm`
  - Chủ file chung: 1.1 giữ hai file `.arb`; các task sau chỉ đọc key
  - Phụ thuộc: (không)

## 2. Sân: điểm trong sân, hai hướng, icon ở lưới, menu

- [x] 2.1 Viết test đỏ cho `PickleballCourtView` mới: điểm trong bếp, sân dọc/ngang, icon ở lưới, menu ⋯. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_view_layout_test.dart` → đỏ đúng lý do (thiếu tham số `axis`/icon) rồi xanh sau 2.2
  - Files: tạo `test/match/pickleball_court_view_layout_test.dart`
  - Nhận: chữ ký của 2.2
  - Phụ thuộc: sau 1.1
- [x] 2.2 Sửa `PickleballCourtView`: thêm `axis`, bỏ `_ScoreBar`/`_CourtTools`, đặt `−`/số/`+` trong bếp, thêm `_NetControls` và menu ⋯. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_view_layout_test.dart` → exit 0
  - Files: sửa `lib/features/match/widgets/pickleball_court_view.dart` (viết lại khung, sân, nửa sân); tạo `pickleball_court_controls.dart` (điểm trong bếp, icon lưới, menu ⋯), `pickleball_court_palette.dart` (màu, màu theo đội)
  - Giao: `PickleballCourtView({ required CourtLayout layout, required List<String> team1Players, required List<String> team2Players, required int team1Score, required int team2Score, Axis axis = Axis.horizontal, bool isSideOut, bool isDoubles, bool receiverCanScore, bool autoSwitchEnds, bool overrideEnabled = false, bool finishSetEnabled = true, void Function(int team, bool increment)? onScoreChange, void Function(int team)? onSetServingTeam, void Function(CourtDropAction)? onDrop, VoidCallback? onUndo, VoidCallback? onRestoreAutomatic, VoidCallback? onToggleAutoSwitch, VoidCallback? onSwitchEnds, VoidCallback? onFinishSet, VoidCallback? onPickWinner, VoidCallback? onLoseServe, VoidCallback? onToggleOverride, VoidCallback? onForceWin })`; key `courtNetControlsKey`, `courtMenuKey`
  - Chủ file chung: 2.2 giữ `pickleball_court_view.dart`
  - Phụ thuộc: sau 2.1

## 3. Panel: hành động chốt set, chọn đội thắng, Lite

- [x] 3.1 Viết test đỏ cho `PickleballCourtPanel`: popup chọn đội thắng, chốt set, mất giao hợp một nút, Lite chạy rally, Ngoại lệ. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_panel_actions_test.dart` → đỏ rồi xanh sau 3.2
  - Files: tạo `test/match/pickleball_court_panel_actions_test.dart`
  - Phụ thuộc: sau 2.2
- [x] 3.2 Sửa `PickleballCourtPanel` và `pickleballCourtContextProvider`. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_panel_actions_test.dart test/match/pickleball_court_notifier_test.dart` → exit 0
  - Files: sửa `lib/features/match/widgets/pickleball_court_panel.dart` (callback mới), `lib/features/match/notifiers/pickleball_court_notifier.dart` (Lite = rally); tạo `lib/features/match/widgets/pickleball_court_dialogs.dart` (hộp thoại chốt set, chọn đội thắng)
  - Giao: `PickleballCourtPanel({ required MatchControlParams params, required bool canScore, VoidCallback? onForceWin, Axis? axis })`; Lite lấy từ `ScorePanelState.isOpenScoring` (không thêm tham số)
  - Chủ file chung: 3.2 giữ hai file trên
  - Phụ thuộc: sau 3.1

## 4. Modal: bỏ khối số lớn và thanh nút dưới cho pickleball có sân

- [x] 4.1 Viết test đỏ cho `OfficialScorePage` pickleball: không còn `PickleballPanel`/thanh nút chữ, Lite hiển thị sân, môn khác giữ thanh nút. Tiêu chí: `flutter test --no-pub test/match/official_score_modal_pickleball_court_test.dart` → đỏ rồi xanh sau 4.2
  - Files: tạo `test/match/official_score_modal_pickleball_court_test.dart`
  - Phụ thuộc: sau 3.2
- [x] 4.2 Sửa `OfficialScorePage` và xoá `CourtScoreLayout`. Tiêu chí: `flutter test --no-pub test/match/official_score_modal_pickleball_court_test.dart test/match/official_score_modal_slice_b_test.dart` → exit 0
  - Files: sửa `lib/features/match/widgets/official_score_modal.dart` (`build` 148-165, thanh dưới 349-735, `_buildScoreTab` 742-804); xoá `lib/features/match/widgets/court_score_layout.dart` và `pickleball_panel.dart` (không còn nơi dùng)
  - Chủ file chung: 4.2 giữ `official_score_modal.dart`
  - Phụ thuộc: sau 4.1

## 5. Cập nhật test cũ

- [x] 5.1 Chuyển các ca của `pickleball_court_widget_test.dart` sang bố cục mới (thanh điểm → dải bếp, hàng công cụ → menu ⋯, bỏ nhóm `layout` của `CourtScoreLayout`). Tiêu chí: `flutter test --no-pub test/match/pickleball_court_widget_test.dart` → exit 0, không ca nào bị xoá mà không có ca thay thế cùng hành vi
  - Files: sửa `test/match/pickleball_court_widget_test.dart`
  - Phụ thuộc: sau 4.2

## 6. Kiểm cuối

- [x] 6.1 Phân tích tĩnh và chạy test liên quan. Tiêu chí: `flutter analyze --no-pub lib/features/match lib/l10n` → không lỗi mới; `flutter test --no-pub test/match` → exit 0; `openspec validate pickleball-cham-diem-gon --strict` → valid
  - Files: (không sửa)
  - Phụ thuộc: sau 5.1
- [x] 6.2 Chụp ảnh sân dọc và ngang (widget test chụp bằng `matchesGoldenFile` tạm hoặc `RenderRepaintBoundary`) và đính vào báo cáo cuối. Tiêu chí: hai ảnh `portrait` và `landscape` được tạo, không overflow
  - Files: ảnh ở thư mục scratchpad, không commit
  - Phụ thuộc: sau 6.1
