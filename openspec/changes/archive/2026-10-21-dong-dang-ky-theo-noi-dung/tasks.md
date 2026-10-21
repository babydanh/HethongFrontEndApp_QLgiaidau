## 1. Code

- [x] 1.1 Entity đọc `registrationOpen`, `registrationClosedReason`, fallback khi thiếu + unit test parser
- [x] 1.2 Màn đăng ký chọn/khoá nội dung theo `registrationOpen`, hiện lý do
- [x] 1.3 Màn giới thiệu: nút Đăng ký khi còn nội dung mở, kể cả giải đang diễn ra
- [x] 1.4 l10n vi/en

## 2. Kiểm

- [x] 2.1 `flutter test --no-pub` các file liên quan (25 pass) + `flutter analyze` file sửa sạch; bộ đầy đủ trên cloud run 39541636632 pass (checkout `ref: dong-dang-ky-theo-noi-dung`); run 39536478151 không tính vì đã checkout `main`
