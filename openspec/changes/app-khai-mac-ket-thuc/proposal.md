## Why

BTC hiện chưa có thao tác khai mạc giải trên App; kết thúc giải còn dùng luồng cũ, trong khi trạng thái đăng ký được tính theo từng nội dung. Cần đưa vòng đời giải về đúng hợp đồng Backend và giữ khả năng đăng ký ở những nội dung còn mở.

## What Changes

- Thêm thao tác khai mạc và kết thúc trong thẻ vòng đời tại màn quản lý giải, có xác nhận, trạng thái đang gửi, tải lại chi tiết sau thành công và hiển thị thông báo lỗi do máy chủ trả.
- Khai mạc chỉ hiển thị với giải đã công bố ở UPCOMING, REGISTRATION_OPEN hoặc REGISTRATION_CLOSED; kết thúc chỉ hiển thị khi IN_PROGRESS.
- Chọn khả năng đăng ký theo `registrationOpen` của division nếu có, luôn loại division CANCELLED; tương thích server cũ bằng luật dự phòng hiện có.
- Bổ sung i18n và kiểm thử có mã TC-APP-LIFECYCLE-01.. cho logic đăng ký và thao tác vòng đời.

## Capabilities

### New Capabilities
- `app-tournament-lifecycle`: Thao tác khai mạc/kết thúc giải và quyết định khả năng đăng ký theo nội dung.

### Modified Capabilities
- None.

## Impact

- App Flutter: màn quản lý giải, repository quản lý giải, tiện ích/model đăng ký, chuỗi `lib/l10n/app_vi.arb` và `app_en.arb`, test tương ứng.
- Backend API: không sửa; sử dụng `POST /tournaments/:id/start`, `POST /tournaments/:id/complete` và projection `registrationOpen`/`status` hiện có.
- Web: không ảnh hưởng.

## Out of Scope

- Thay đổi hợp đồng API, luật nghiệp vụ phía Backend, trạng thái giải phía Web hoặc luồng khai mạc tự động.
