## 1. Giao diện và lối đi 409

- [x] 1.1 Dải báo 409 `EMAIL_BELONGS_TO_ACCOUNT` + nút "Tìm tài khoản này" (test đỏ trước). Tiêu chí: `flutter test --no-pub test/organizer_ops/add_athlete_entry_test.dart` → exit 0
  - Files: sửa `lib/features/organizer_ops/screens/add_athlete_sheet.dart` (`_submitGuest` :1128, `_buildDirectEntry` :694), `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (+ `flutter gen-l10n`); test `test/organizer_ops/add_athlete_entry_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 1.1 giữ `add_athlete_sheet.dart` và hai file `.arb`
  - Phụ thuộc: (không)
- [x] 1.2 Vẽ lại hai tab theo Lavish, giữ key. Tiêu chí: `flutter analyze --no-pub lib/features/organizer_ops/screens/add_athlete_sheet.dart` → exit 0; `flutter test --no-pub test/organizer_ops/add_athlete_entry_test.dart test/features/tournament_management_hub_screen_test.dart` → exit 0
  - Files: sửa `lib/features/organizer_ops/screens/add_athlete_sheet.dart` (`_buildTabs` :300, `_buildAccountContent` :352, `_buildCandidateRow` :483, `_buildCandidateFooter` :619, `_buildDirectEntry` :694)
  - Chủ file chung: 1.2 giữ `add_athlete_sheet.dart` sau 1.1
  - Phụ thuộc: 1.1

## 2. Kiểm tra cuối

- [x] 2.1 Ảnh máy thật (chỉ xem popup, không bấm Thêm). Tiêu chí: chụp tab "Bạn bè & CLB" và "Nhập tên" trên máy thật
  - Phụ thuộc: 1.2
