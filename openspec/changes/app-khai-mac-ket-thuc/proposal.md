## Why

BTC cần điều khiển vòng đời giải trên App đúng với Backend và Web, trong khi đăng ký được tính riêng theo từng nội dung. Khi khai mạc, Backend khóa đăng ký tất cả nội dung nguyên tử; sau đó BTC vẫn có thể mở lại riêng từng nội dung.

## What Changes

- Khai mạc chỉ khả dụng khi giải đã chốt đăng ký hoặc không còn nội dung mở; khi REGISTRATION_OPEN, luôn yêu cầu chốt đăng ký trước.
- Hộp xác nhận khai mạc luôn cảnh báo rằng thao tác khóa đăng ký mọi nội dung; App chỉ gửi POST `/tournaments/:id/start`.
- Backend khóa mọi division cùng giao dịch đổi trạng thái sang IN_PROGRESS; sau đó có thể mở lại riêng division qua cấu hình hiện có.
- `registrationOpen` vẫn quyết định khả năng đăng ký từng division trong IN_PROGRESS; trạng thái giải không tự đóng division mới được mở lại.

## Capabilities

### New Capabilities
- `app-tournament-lifecycle`: Thao tác khai mạc/kết thúc giải và quyết định khả năng đăng ký theo nội dung.

### Modified Capabilities
- None.

## Impact

- App Flutter: màn quản lý giải, repository quản lý giải, tiện ích/model đăng ký, chuỗi `lib/l10n/app_vi.arb` và `app_en.arb`, test tương ứng.
- Backend API: không đổi route; `POST /tournaments/:id/start` khóa mọi division nguyên tử với chuyển trạng thái.
- Web: cùng quy tắc hiển thị nút khai mạc sau khi đăng ký đã chốt và cảnh báo khóa toàn bộ.

## Out of Scope

- Không đổi cách tính `registrationOpen` trong trạng thái `IN_PROGRESS`; thao tác mở lại riêng division vẫn khả dụng.
