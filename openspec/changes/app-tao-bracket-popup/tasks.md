## 1. Hàm gợi ý
- [x] 1.1 Port `getBracketQuickSuggestion` của Web sang Dart. Tiêu chí: `flutter test --no-pub test/bracket_quick_suggestion_test.dart` → exit 0
  - Files: tạo `lib/features/bracket/utils/bracket_quick_suggestion.dart`; test `test/bracket_quick_suggestion_test.dart`
  - Giao: `BracketQuickSuggestion? bracketQuickSuggestion({required String bracketType, required int participantCount})` · Nhận: (không)
  - Phụ thuộc: không

## 2. Popup
- [x] 2.1 `BracketCreateSheet` + payload cấu hình. Tiêu chí: `flutter test --no-pub test/bracket_create_settings_test.dart test/features/bracket_management_bar_test.dart` → exit 0
  - Files: tạo `lib/features/bracket/widgets/bracket_create_sheet.dart`; sửa `lib/l10n/app_vi.arb`, `app_en.arb`; tạo `lib/features/bracket/utils/bracket_create_settings.dart`; test `test/bracket_create_settings_test.dart`
  - Giao: `Future<BracketCreateResult?> showBracketCreateSheet(BuildContext, {division, participantCount})` · Nhận: `bracketQuickSuggestion`
  - Phụ thuộc: sau 1.1

## 3. Nối vào nút Tạo bracket
- [x] 3.1 Nút Tạo bracket mở popup cho Vòng bảng / Round Robin. Tiêu chí: `flutter test --no-pub test/features/bracket_management_bar_test.dart` → exit 0
  - Files: sửa `lib/features/bracket/widgets/bracket_management_bar.dart`, `lib/features/bracket/screens/bracket_view_screen.dart:689-697`
  - Phụ thuộc: sau 2.1

## 4. Kiểm tra cuối
- [ ] 4.1 `flutter analyze` + test liên quan trên cloud `--target app`. Tiêu chí: run xanh
