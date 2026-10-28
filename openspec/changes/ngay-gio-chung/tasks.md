## 1. Popup cuộn dùng chung

- [x] 1.1 Thêm `subtitle`, `minDate`, `maxDate`, `showEndOfDayChip` (tuỳ chọn) cho `SocialDateTimePickerSheet`. Tiêu chí: `flutter test --no-pub test/features/social_date_time_picker_sheet_test.dart` exit 0
  - Files: sửa `lib/features/social/widgets/create_edit_screen/social_date_time_picker_sheet.dart`; test `test/features/social_date_time_picker_sheet_test.dart`
  - Giao: `SocialDateTimePickerSheet.show(context, initial, {subtitle, minDate, maxDate, showEndOfDayChip})`
  - Phụ thuộc: không

## 2. Ô ngày giờ dùng chung

- [x] 2.1 Tạo `DateTimeField` (nhãn trên, đủ năm, lỗi dưới ô) và chuỗi l10n giới hạn ngày. Tiêu chí: `flutter test --no-pub test/shared/widgets/date_time_field_test.dart` exit 0
  - Files: tạo `lib/shared/widgets/date_time_field.dart`; sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/shared/widgets/date_time_field_test.dart`
  - Giao: `DateTimeField({buttonKey, label, value, placeholder, onTap, errorText})`
  - Phụ thuộc: không

## 3. Trang Đăng ký

- [x] 3.1 Dùng `DateTimeField` + popup cuộn cho 4 mốc, lỗi thứ tự hiện tại ô, khoá Lưu khi còn lỗi. Tiêu chí: `flutter test --no-pub test/features/tournament_management_settings_section_test.dart` exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_section_screen.dart`; test `test/features/tournament_management_settings_section_test.dart`
  - Phụ thuộc: 1.1, 2.1

## 4. Tạo giải nhanh và vòng đấu

- [x] 4.1 Tạo giải nhanh: 4 mốc dùng ô chung và một hàm chọn thay 4 đoạn chép. Tiêu chí: `flutter analyze --no-pub lib/features/tournament` không có error/warning mới
  - Files: sửa `lib/features/tournament/screens/create_public_quick_tournament_screen.dart`
  - Phụ thuộc: 1.1, 2.1
- [x] 4.2 Cấu hình vòng đấu dùng ô chung và popup cuộn. Tiêu chí: `flutter test --no-pub test/features/stage_round_config_sheet_test.dart` exit 0
  - Files: sửa `lib/features/tournament/widgets/stage_round_config_sheet.dart`; test `test/features/stage_round_config_sheet_test.dart`
  - Phụ thuộc: 1.1, 2.1

## 5. Kiểm tra cuối

- [x] 5.1 Validate OpenSpec và phân tích tĩnh. Tiêu chí: `openspec validate ngay-gio-chung --strict` exit 0; `flutter analyze --no-pub lib/features/tournament lib/features/social lib/shared` không có error/warning
  - Files: không sửa
  - Phụ thuộc: 1.1-4.2
