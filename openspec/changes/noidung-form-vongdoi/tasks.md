## 1. Màn 8 - Nội dung thi đấu

- [x] 1.1 Accordion + tóm tắt + minh hoạ thể thức + thông báo khoá cho `DivisionEditorSheet`
  - Files: lib/features/tournament/widgets/division_editor_sheet.dart, lib/features/tournament/widgets/division_editor_accordion.dart, lib/features/tournament/widgets/format_illustration_dialog.dart, lib/l10n/app_vi.arb, lib/l10n/app_en.arb, test/features/division_editor_sheet_test.dart
  - Tiêu chí: `flutter test --no-pub test/features/division_editor_sheet_test.dart` exit 0

## 2. Màn 9 - Form đăng ký

- [x] 2.1 Model + màn soạn form + lối vào từ mục Người tham gia
  - Files: lib/features/tournament/widgets/registration_form_editor.dart, lib/features/tournament/screens/tournament_management_people_section.dart, lib/l10n/app_vi.arb, lib/l10n/app_en.arb, test/features/registration_form_editor_test.dart
  - Tiêu chí: `flutter test --no-pub test/features/registration_form_editor_test.dart` exit 0

## 3. Màn 10 - Vòng đời

- [ ] 3.1 Thanh bước, cảnh báo đủ đội, khoá Xuất bản, xoá giải gõ tên
  - Files: lib/features/tournament/widgets/lifecycle_stepper.dart, lib/features/tournament/screens/tournament_management_section_screen.dart, lib/features/tournament/screens/tournament_management_hub_screen.dart, lib/l10n/app_vi.arb, lib/l10n/app_en.arb, test/features/lifecycle_stepper_test.dart
  - Tiêu chí: `flutter test --no-pub test/features/lifecycle_stepper_test.dart` exit 0

## 4. Kiểm tra chung

- [ ] 4.1 Phân tích tĩnh và validate OpenSpec
  - Files: openspec/changes/noidung-form-vongdoi/
  - Tiêu chí: `flutter analyze --no-pub lib/features/tournament` không lỗi/cảnh báo mới; `openspec validate noidung-form-vongdoi --strict` exit 0
