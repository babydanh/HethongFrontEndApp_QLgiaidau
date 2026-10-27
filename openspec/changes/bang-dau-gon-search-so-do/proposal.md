## Why
Tab "Bảng đấu" trong hub quản lý giải (App) lộn xộn: có banner mô tả + nút "Sơ đồ Knockout" thừa, và sơ đồ bị nhốt trong khung cao 420 với kéo-zoom chéo nên tranh cử chỉ với cuộn dọc của trang, không cuộn ngang/dọc mượt được như Web.

## What Changes
- Khi `BracketViewScreen` nhúng trong hub (`isEmbedded` và không `isLite`): bỏ banner mô tả/nút mở sơ đồ riêng, chỉ còn ô tìm kiếm và sơ đồ.
- Sơ đồ nhúng dùng `scrollOnly` (chỉ cuộn ngang), cao theo nội dung, không còn `SizedBox(height: 420)`; cuộn dọc thuộc trang hub.
- Màn sơ đồ không nhúng và màn Lite (nhúng trong khung cao cố định, không có cuộn dọc bọc ngoài) giữ nguyên.
- Nút "Sơ đồ Knockout" (mở `BracketDiagramScreen`) ẩn trong hub là chủ đích theo yêu cầu "gọn lại, xoá bớt text"; màn `BracketDiagramScreen` vẫn còn ở lối vào khác ngoài hub, không bị gỡ.

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
