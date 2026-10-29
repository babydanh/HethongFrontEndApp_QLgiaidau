## 1. Ô nhập tay đều chiều cao

- [x] 1.1 Nhãn luôn nổi và chiều cao tối thiểu chung cho ô nhập tay. Tiêu chí: `flutter test --no-pub test/organizer_ops/add_athlete_entry_test.dart` → exit 0 (30 pass)
  - Files: sửa `lib/features/organizer_ops/screens/add_athlete_sheet.dart` (`_directField`); test `test/organizer_ops/add_athlete_entry_test.dart`
  - Phụ thuộc: không
- [x] 1.2 Phân tích tĩnh file đã sửa. Tiêu chí: `flutter analyze --no-pub lib/features/organizer_ops/screens/add_athlete_sheet.dart` → không lỗi
