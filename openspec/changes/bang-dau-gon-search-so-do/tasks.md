## 1. Bố cục gọn khi nhúng
- [x] 1.1 Bỏ banner và để sơ đồ cuộn ngang, cao theo nội dung khi `isEmbedded`. Tiêu chí: `flutter test --no-pub test/features/bracket_view_embedded_test.dart test/features/organizer_bracket_inline_test.dart test/features/tournament_management_hub_screen_test.dart test/features/public_bracket_view_test.dart` → exit 0
  - Files: sửa `lib/features/bracket/screens/bracket_view_screen.dart:1020,1438`; tạo test `test/features/bracket_view_embedded_test.dart`
  - Giao: (không) · Nhận: `SingleElimDiagram/DoubleElimDiagram(scrollOnly: true)` có sẵn
  - Chủ file chung: 1.1 giữ `bracket_view_screen.dart`
  - Phụ thuộc: (không)
