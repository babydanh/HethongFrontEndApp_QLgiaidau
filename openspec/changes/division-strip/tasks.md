## 1. Thành phần dùng chung

- [x] 1.1 Tạo `DivisionStrip` + khoá l10n "Quản lý" (vi/en) + test widget. Tiêu chí: `flutter test --no-pub test/features/division_strip_test.dart` → exit 0
  - Files: tạo `lib/features/tournament/widgets/division_strip.dart`, `test/features/division_strip_test.dart`; sửa `lib/l10n/app_vi.arb`, `app_en.arb` (+ sinh lại)
  - Giao: `DivisionStrip({items, selectedId, onChanged(String?), showAll, onManage, keyPrefix})`, `DivisionStripItem({id, name, count, capacity})`
  - Phụ thuộc: không

## 2. Thay các chỗ dùng

- [x] 2.1 Bảng đấu + Trực tiếp dùng `DivisionStrip`, xoá `DivisionFilterSegment`. Tiêu chí: `flutter test --no-pub test/features/public_bracket_view_test.dart test/features/organizer_bracket_inline_test.dart` → exit 0
  - Files: sửa `bracket_view_screen.dart`, `live_match_screen.dart`; xoá `division_filter_segment.dart`
  - Nhận: `DivisionStrip` từ 1.1 · Phụ thuộc: sau 1.1
- [x] 2.2 Vận hành giải dùng `DivisionStrip`. Tiêu chí: các test ops (`test/features/ops_*_test.dart`) → exit 0
  - Files: sửa `organizer_ops_screen.dart` (`_OpsDivisionSelector`) · Phụ thuộc: sau 1.1
- [x] 2.3 Chip "Quản lý" ở tab Bảng đấu của hub mở màn nội dung. Tiêu chí: `flutter test --no-pub test/features/tournament_management_hub_screen_test.dart` → exit 0
  - Files: sửa `bracket_view_screen.dart` (tham số `onManageDivisions`), `tournament_management_hub_screen.dart` · Phụ thuộc: sau 2.1

## 3. Kiểm tra cuối

- [x] 3.1 Analyze thư mục đã sửa và chạy các test liên quan. Tiêu chí: `flutter analyze --no-pub` các file đã sửa → không lỗi mới
