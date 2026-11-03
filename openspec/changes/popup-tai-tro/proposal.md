## Why
Tab "Tài trợ" của trang giải công khai biến mất ở App khi giải chỉ có nhà tài trợ chưa up logo, trong khi Web vẫn hiện (chữ cái đầu thay logo). Ngoài ra nhiều popup tự gắn `shape`/màu riêng (bo 16, 20, 24, `radiusXL`) nên lệch với theme popup chung vừa thêm (`dialogTheme`, `bottomSheetTheme`), và 26 bottom sheet không có tay kéo để đóng.

## What Changes
- Nhà tài trợ không có logo vẫn được giữ ở `getPublicSponsors` và `Tournament.fromJson`; thẻ nhà tài trợ đã có sẵn chữ cái đầu thay logo.
- 26 bottom sheet nền thường thêm `showDragHandle: true`; bỏ `shape` (bo 20) và `backgroundColor: bgCard` nhái theme ở các sheet đó để ăn bo 24 chung.
- 12 hộp thoại bỏ `shape` và `backgroundColor: bgCard` riêng để ăn `dialogTheme` (bo 20, viền mảnh).

## Out of scope
Backend, Web, các sheet nền trong suốt tự dựng khung (20 chỗ), `tournament_management_athletes_tab.dart` (màu bề mặt riêng), nội dung bên trong từng popup.

## Capabilities
### New Capabilities
- `popup-consistency`: popup App dùng chung một bộ bo góc, nền, tay kéo; tab Tài trợ hiện khi giải có nhà tài trợ dù thiếu logo.

### Modified Capabilities
(không)

## Impact
`api_tournament_repository.dart`, `tournament.dart`, 24 file chứa `showModalBottomSheet`, 12 file chứa `AlertDialog`; test `tournament_public_sponsors_test.dart`, `social_sheets_theme_test.dart`.
