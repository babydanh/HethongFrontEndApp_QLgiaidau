## Why
Tab "Bảng đấu" trong hub quản lý giải (App) lộn xộn: có banner mô tả + nút "Sơ đồ Knockout" thừa, và sơ đồ bị nhốt trong khung cao 420 với kéo-zoom chéo nên tranh cử chỉ với cuộn dọc của trang, không cuộn ngang/dọc mượt được như Web.

## What Changes
- Khi `BracketViewScreen` nhúng trong hub (`isEmbedded` và không `isLite`): bỏ banner mô tả (tiêu đề + chữ giải thích), chỉ còn ô tìm kiếm, sơ đồ và một nút gọn "mở sơ đồ toàn màn hình" căn phải.
- Sơ đồ nhúng dùng `scrollOnly` (chỉ cuộn ngang), cao theo nội dung, không còn `SizedBox(height: 420)`; cuộn dọc thuộc trang hub.
- Màn sơ đồ không nhúng và màn Lite (nhúng trong khung cao cố định, không có cuộn dọc bọc ngoài) giữ nguyên.
- Nút mở `BracketDiagramScreen` (key `bracket-open-full-diagram`) GIỮ trong hub cho cả người xem lẫn quản lý: đó là lối vào duy nhất tới thao tác giữ (long-press) và kéo thả đổi chỗ của quản lý, nên không được gỡ.

## Out of scope
- Màn `BracketDiagramScreen` riêng, sơ đồ công khai (`PublicBracketView`), logic dựng sơ đồ.

## Capabilities
### New Capabilities
- `app-bracket-embedded-compact`: bố cục gọn của tab Bảng đấu khi nhúng trong hub quản lý.

### Modified Capabilities
(không)

## Impact
- `lib/features/bracket/screens/bracket_view_screen.dart`
- `test/features/bracket_view_embedded_test.dart` (mới)
