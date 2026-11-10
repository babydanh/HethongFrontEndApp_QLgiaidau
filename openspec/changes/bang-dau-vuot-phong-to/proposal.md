## Why
Sơ đồ Bảng đấu chỉ đổi vòng bằng mũi tên ‹ ›, và không có đường vào sơ đồ toàn màn hình đủ chức năng từ chính dải này.

## What Changes
- Thêm nút phóng to (icon `open_in_full`) cùng hàng với ‹ Tứ kết · 1/3 ›, bấm mở `BracketDiagramScreen` (toàn màn hình, đủ chức năng theo quyền).
- Vuốt ngang trên dải ‹ Tứ kết · 1/3 › đổi vòng như bấm mũi tên.
- `PublicBracketView` nhận thêm `canEditBracket` để người quản lý có đủ chức năng sửa trong sơ đồ toàn màn hình.
- Không thêm khóa l10n (dùng lại `imageViewerZoomIn` = "Phóng to").

## Impact
- `lib/features/bracket/widgets/playoff_double_elim_view.dart`, `public_bracket_view.dart`, `lib/features/bracket/screens/bracket_view_screen.dart`
- Test: `playoff_double_elim_view_test.dart` (TC-PLF-EXPAND-01/02, TC-PLF-SWIPE-01), `public_bracket_view_test.dart` (TC-PLF-EXPAND-03)
