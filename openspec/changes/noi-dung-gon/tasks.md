## 1. Danh sách nội dung phẳng

- [x] 1.1 Header một nút, hàng phẳng, meta bằng icon, bỏ khoá l10n thừa. Tiêu chí: `flutter test --no-pub test/features/tournament_management_divisions_section_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_divisions_section.dart`; test `test/features/tournament_management_divisions_section_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 1.1 giữ file này
  - Phụ thuộc: (không)
- [x] 1.2 Test hub và cấu hình vòng vẫn xanh. Tiêu chí: `flutter test --no-pub test/features/tournament_management_hub_screen_test.dart test/features/stage_round_config_sheet_test.dart` → exit 0
  - Files: (không sửa)
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.1
- [x] 1.3 Nhóm theo thể loại, số đăng ký/tối đa, ô tìm khi > 8 nội dung. Tiêu chí: `flutter test --no-pub test/features/tournament_management_divisions_section_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_divisions_section.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test cùng file test ở 1.1
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 1.3 giữ hai file arb
  - Phụ thuộc: sau 1.1
