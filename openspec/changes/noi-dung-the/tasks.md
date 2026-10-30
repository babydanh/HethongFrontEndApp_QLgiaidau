## 1. Thẻ nội dung tách khung

- [x] 1.1 Bỏ nhãn nhóm, thẻ tách khung mở có animation với đủ thông tin, nút "+" với lớp mờ trắng, 5 khoá l10n. Tiêu chí: `flutter test --no-pub test/features/tournament_management_divisions_section_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_divisions_section.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/features/tournament_management_divisions_section_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 1.1 giữ hai file arb
  - Phụ thuộc: (không)
- [x] 1.2 Test cấu hình vòng và hub vẫn xanh (menu nằm trong thẻ). Tiêu chí: `flutter test --no-pub test/features/stage_round_config_sheet_test.dart test/features/tournament_management_hub_screen_test.dart` → exit 0
  - Files: sửa `test/features/stage_round_config_sheet_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.1
