## ADDED Requirements

### Requirement: Điều khiển vòng đời giải từ màn quản lý
App SHALL hiển thị thao tác khai mạc chỉ khi giải ở trạng thái UPCOMING, REGISTRATION_OPEN hoặc REGISTRATION_CLOSED; SHALL hiển thị thao tác kết thúc khi giải IN_PROGRESS. Mỗi thao tác SHALL yêu cầu xác nhận, chống gửi lặp trong lúc xử lý, gọi đúng endpoint vòng đời và tải lại chi tiết sau thành công. Nếu khai mạc còn division chưa có sơ đồ, hộp xác nhận SHALL cảnh báo nhưng vẫn cho xác nhận. Khi máy chủ từ chối, App SHALL hiển thị nguyên thông điệp máy chủ.

#### Scenario: Khai mạc giải đã công bố
- WHEN BTC xác nhận khai mạc giải UPCOMING, REGISTRATION_OPEN hoặc REGISTRATION_CLOSED
- THEN App gửi POST `/tournaments/:id/start`, tải lại chi tiết khi thành công và không cho gửi lặp khi request đang chạy

#### Scenario: Cảnh báo sơ đồ chưa có
- WHEN khai mạc giải còn nội dung chưa có sơ đồ
- THEN hộp xác nhận cảnh báo về nội dung đó nhưng vẫn cho phép BTC khai mạc

#### Scenario: Hoàn tất giải có trận đang chạy
- WHEN BTC xác nhận kết thúc giải IN_PROGRESS và Backend từ chối vì còn trận ONGOING
- THEN App gửi POST `/tournaments/:id/complete` và hiển thị đúng nguyên văn message lỗi do Backend trả

#### Scenario: Trạng thái không đủ điều kiện
- WHEN giải ở trạng thái DRAFT, COMPLETED hoặc CANCELLED
- THEN App không hiển thị nút khai mạc; khi giải không IN_PROGRESS App không hiển thị nút kết thúc

### Requirement: Đăng ký theo trạng thái division
App SHALL dùng `registrationOpen` do Backend trả về cho từng division khi trường này có mặt; SHALL không bao giờ coi division CANCELLED là mở. Trạng thái IN_PROGRESS của giải không SHALL tự đóng đăng ký ở division vẫn mở. Khi server cũ không trả `registrationOpen`, App SHALL giữ luật dự phòng hiện có.

#### Scenario: Giải đang diễn ra còn division mở
- WHEN giải IN_PROGRESS có ít nhất một division không CANCELLED với `registrationOpen == true`
- THEN nút đăng ký của giải hiện và division đó được chọn đăng ký

#### Scenario: Division bị huỷ
- WHEN một division có status CANCELLED dù `registrationOpen == true`
- THEN App không cho đăng ký vào division đó

#### Scenario: Server cũ không có trạng thái division
- WHEN division không có trường `registrationOpen`
- THEN App áp dụng luật dự phòng theo hạn đăng ký hiện có
