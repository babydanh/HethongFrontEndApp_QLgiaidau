## 1. Hub

- [x] 1.1 Thêm tab "Nội dung" vào hub, nối chip "Quản lý", bỏ dòng nội dung khỏi Cài đặt. Tiêu chí: `flutter test --no-pub test/features/tournament_management_hub_screen_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_hub_screen.dart`, `lib/l10n/app_vi.arb`, `app_en.arb`; test `test/features/tournament_management_hub_screen_test.dart`
  - Phụ thuộc: không

## 2. Bốc thăm

- [x] 2.1 Đổi dropdown chọn nội dung của Bốc thăm sang `DivisionStrip`. Tiêu chí: `flutter test --no-pub test/features/auto_draw_save_bracket_test.dart` → exit 0
  - Files: sửa `lib/features/bracket/screens/auto_draw_screen.dart`; test `test/features/auto_draw_save_bracket_test.dart` · Phụ thuộc: không

## 3. Kiểm tra cuối

- [x] 3.1 Analyze file đã sửa và chạy các test liên quan. Tiêu chí: `flutter analyze --no-pub` file đã sửa → không lỗi
