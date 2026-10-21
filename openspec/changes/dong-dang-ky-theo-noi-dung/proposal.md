## Why

Backend (change `dong-dang-ky-theo-noi-dung`) cho mỗi nội dung đóng đăng ký độc lập và vẫn nhận VĐV tự đăng ký cho nội dung còn hạn riêng khi giải đang diễn ra; trả `registrationOpen`, `registrationClosedReason` cho từng nội dung. App hiện tự tính hạn từ `effectiveRegistrationEndDate` và sức chứa (`lib/domain/entities/tournament_registration.dart:109-149`, `lib/features/register/screens/tournament_register_screen.dart:398-405`), không đọc khoá nội dung và chặn theo trạng thái giải ở màn giới thiệu (`lib/features/tournament/screens/tournament_intro_screen.dart:294-298`).

## What Changes

- `TournamentDivisionOption` đọc `registrationOpen`, `registrationClosedReason` (thiếu trường thì giữ cách tính cũ để chạy với Backend cũ).
- Màn đăng ký: chỉ chọn được nội dung còn mở; nội dung đóng hiện lý do (đã khoá, hết hạn, giải chưa mở).
- Màn giới thiệu giải: nút Đăng ký hiện khi còn ít nhất một nội dung mở, kể cả giải đang diễn ra.
- Chuỗi l10n vi/en mới.

## Out of scope

- Luật server, trang quản lý BTC (Web).

## Impact

- App: entity đăng ký, màn đăng ký, màn giới thiệu giải, l10n, widget test.
