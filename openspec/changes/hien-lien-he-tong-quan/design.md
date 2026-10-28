## Context

`Tournament.contactInfo` là `Map<String, dynamic>?` với `phone`, `email`, `organizerName`, `displayMode` (`PROFILE|MANUAL`), `hidden` (`tournament.dart:62`, `showFounder` dòng 167). Web `renderContactCard` (`TournamentDetailClient.tsx:1560-1597`): MANUAL hiện tên + điện thoại; không MANUAL hiện điện thoại + email. Con mắt ở App (`overview_tab.dart:928-943`) ghi `contactInfo.hidden`.

## Decisions

- **D1 Quy tắc hiển thị** (ghi lại vì Web main không gắn khối liên hệ với `hidden`, chưa kiểm staging [SUY LUẬN]):
  - MANUAL: người tạo tự nhập để công khai → luôn hiện tên + điện thoại, không hiện email.
  - PROFILE hoặc không có `displayMode`: SĐT/email lấy từ hồ sơ cá nhân → chỉ hiện khi `hidden == false`, đúng cách `showFounder` đang xét; người quản lý (có `onToggleFounderHidden`) luôn thấy kèm dòng "Đang ẩn với người xem" khi `hidden != false`.
  - Chọn hướng an toàn riêng tư: thiếu cờ = ẩn, giống `showFounder`.
- **D2 Hàm thuần** `visibleContact(Map<String,dynamic>? info, {required bool isManager})` trả `TournamentContact?` (`null` = không vẽ khối). Giá trị không phải chuỗi hoặc chỉ khoảng trắng coi là rỗng.
- **D3 Không thêm gì ngoài văn bản**: không nút Gọi/Chép, không mở app điện thoại (YAGNI, tránh thêm quyền/package); dùng `SelectableText` để chép tay được.
- **D4 Vị trí**: khối mới nằm sau khối Ban tổ chức trong cùng `Column`, độc lập điều kiện của khối đó, dùng lại `_buildSectionHeader`.

## Rejected

- Đổi layout Tổng quan (bỏ banner/icon bút): người dùng đã bác.
- Gắn khối liên hệ vào `showFounder`: MANUAL luôn làm `showFounder` false nên sẽ không bao giờ hiện liên hệ nhập tay.
- Hiện liên hệ bất kể cờ như Web main: lộ SĐT/email hồ sơ cá nhân khi người tạo đã bấm ẩn.

## Risks

- Backend vẫn trả `contactInfo` thô nên ẩn chỉ ở giao diện (đã nêu ở Out of scope).
- Nếu Web staging gắn `hidden` khác D1, cần chỉnh D1 cho khớp trước khi merge [SUY LUẬN: chưa kiểm].
