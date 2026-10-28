## Why

Web hiện khối "THÔNG TIN LIÊN HỆ" (tên khi nhập tay, Điện thoại, Email) ở trang giải; App đã tải `contactInfo` về (`tournament.dart:62`) nhưng không màn nào hiển thị, nên người xem App không có cách liên hệ ban tổ chức. Người dùng đã duyệt giao diện Tổng quan hiện tại và không muốn đổi.

## What Changes

- Thêm một khối **Liên hệ** (Điện thoại, Email; thêm tên người liên hệ khi chế độ nhập tay) ngay dưới khối "Ban tổ chức" ở tab Tổng quan (`overview_tab.dart`).
- Thêm hàm thuần `visibleContact` quyết định ai thấy gì theo `contactInfo`, để test không cần dựng widget.
- Chuỗi hiển thị mới ở cả hai ARB.
- Không đổi banner, icon bút, chỉ số, lộ trình, khối Ban tổ chức, con mắt.

## Out of scope

- Trang chi tiết người dùng (`user_profile_screen.dart`, `user_profile_bottom_sheet.dart`): chưa kiểm Backend/Web có cho lộ liên hệ của người khác không; làm change riêng sau khi kiểm.
- Backend: `GET /tournaments/:id` trả `contactInfo` thô cho mọi người nên "ẩn" mới chỉ ở giao diện; lọc theo quyền là change Backend riêng (OpenSpec + `/security-review`).
- Các khoá liên hệ phụ Web hiện ở chế độ hồ sơ (Zalo, Instagram…), nút Gọi/Chép, tab Giới thiệu/Intro.
- Sửa nội dung liên hệ từ App (Web có ở `BasicInfoTab.tsx`).

## Capabilities

### New Capabilities

- `app-tournament-contact`: App hiện liên hệ ban tổ chức ở tab Tổng quan, tôn trọng cờ ẩn.

### Modified Capabilities

(không)

## Impact

`lib/features/tournament/widgets/overview_tab.dart`, `lib/features/tournament/utils/tournament_contact.dart` (mới), `lib/l10n/app_{vi,en}.arb` (+ sinh lại), test tương ứng.
