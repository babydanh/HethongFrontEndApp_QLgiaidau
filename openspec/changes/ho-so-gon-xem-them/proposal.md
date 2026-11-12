## Why
Hồ sơ App chưa có mục "Giải tôi tổ chức"; cần cùng hành vi với Web: 4 giải đầu và "Xem thêm" bằng cursor.

## What Changes
- Tab Giải đấu của hồ sơ thêm khối "Giải tôi tổ chức" (4 giải, "Xem thêm" gọi `workspace/me?role=ORGANIZER&limit=4&cursor=`).
- `getMyWorkspace` nhận thêm `role` tuỳ chọn; mặc định không gửi nên hành vi cũ giữ nguyên.
- Kiểm lỗi kiểu `matchesWithUser`: App dùng l10n sinh code, chuỗi có `{count}` bắt buộc truyền tham số nên không có lỗi tương tự.

## Impact
- `lib/providers/organized_tournaments_provider.dart`, `lib/features/profile/widgets/organized_tournaments_section.dart`, `profile_screen.dart`, repository, `app_{vi,en}.arb`. Phụ thuộc Backend `role` (cùng nhánh).
