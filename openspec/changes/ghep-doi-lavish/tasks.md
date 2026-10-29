## 1. Bộ chọn cách ghép dùng chung

- [x] 1.1 Tạo `PairingStrategyPicker` (3 hàng nhãn ngắn, key `<prefix>-<name>`) và đổi nhãn "Cân bằng". Tiêu chí: `flutter test --no-pub test/features/pairing_sheet_test.dart` → exit 0
  - Files: tạo `lib/features/tournament/widgets/pairing_strategy_picker.dart`; sửa `lib/l10n/app_vi.arb`, `app_en.arb`
  - Phụ thuộc: không

## 2. Popup và hộp

- [x] 2.1 Viết lại `PairingSheet` theo Lavish, chân một hàng (thêm `footer` cho `TournamentManageSheet`). Tiêu chí: `flutter test --no-pub test/features/pairing_sheet_test.dart` → exit 0
  - Files: sửa `pairing_sheet.dart`, `tournament_manage_sheet.dart`; test `test/features/pairing_sheet_test.dart`
  - Phụ thuộc: sau 1.1
- [x] 2.2 Đổi `_AutoPairDialog` dùng bộ chọn chung, bỏ mô tả. Tiêu chí: `flutter test --no-pub test/features/athletes_tab_actions_test.dart` → exit 0
  - Files: sửa `tournament_management_athletes_tab.dart`; test `test/features/athletes_tab_actions_test.dart`
  - Phụ thuộc: sau 1.1

## 3. Kiểm tra cuối

- [x] 3.1 Analyze file đã sửa và chạy các test liên quan. Tiêu chí: `flutter analyze --no-pub lib/features/tournament/widgets` → exit 0 (không lỗi mới); `flutter test --no-pub test/features/pairing_sheet_test.dart test/features/athletes_tab_actions_test.dart test/features/swiss_pairing_screen_test.dart` → exit 0
