## ADDED Requirements

### Requirement: Điều khiển vòng đời giải từ màn quản lý
App SHALL hiển thị đúng một nút vòng đời theo việc tiếp theo như Web: DRAFT "Công bố"; UPCOMING "Mở đăng ký ngay"; REGISTRATION_OPEN chưa có trận "Chốt đăng ký" (`/close-registration`, không gọi `/lock`); đã có trận hoặc REGISTRATION_CLOSED "Khai mạc giải"; IN_PROGRESS "Kết thúc giải". Mỗi thao tác SHALL hỏi xác nhận, chống gửi lặp và hiện nguyên lỗi máy chủ.

#### Scenario: Khai mạc giải đã đóng đăng ký
- WHEN BTC xác nhận khai mạc giải REGISTRATION_CLOSED
- THEN App chỉ gửi POST `/tournaments/:id/start` và không hỏi "chốt luôn"

#### Scenario: Khai mạc khi còn mở đăng ký
- WHEN giải REGISTRATION_OPEN đã có trận, BTC tick "Chốt đăng ký các nội dung còn mở luôn" rồi xác nhận
- THEN App gửi POST `/tournaments/:id/close-registration` rồi POST `/tournaments/:id/start`

#### Scenario: Chốt đăng ký khi chưa có sơ đồ
- WHEN giải REGISTRATION_OPEN chưa có trận và BTC xác nhận "Chốt đăng ký"
- THEN App gửi POST `/tournaments/:id/close-registration` và không hiện nút khai mạc

#### Scenario: Mở lại khi hạn giải đã qua
- WHEN BTC bấm "Mở đăng ký ngay" hoặc "Mở lại đăng ký" mà hạn đăng ký cấp giải đã qua
- THEN App hỏi hạn mới (phải ở tương lai) rồi mới gửi POST `/tournaments/:id/reopen-registration` kèm `registrationEndDate`; huỷ chọn hạn thì không gửi gì

#### Scenario: Cảnh báo sơ đồ chưa có
- WHEN khai mạc giải còn nội dung chưa có sơ đồ
- THEN hộp xác nhận cảnh báo về nội dung đó nhưng vẫn cho phép BTC khai mạc

#### Scenario: Hoàn tất giải có trận đang chạy
- WHEN BTC xác nhận kết thúc giải IN_PROGRESS và Backend từ chối vì còn trận ONGOING
- THEN App gửi POST `/tournaments/:id/complete` và hiển thị đúng nguyên văn message lỗi do Backend trả

#### Scenario: Trạng thái không đủ điều kiện
- WHEN giải ở trạng thái DRAFT, UPCOMING, COMPLETED hoặc CANCELLED
- THEN App không hiển thị nút khai mạc; khi giải không IN_PROGRESS App không hiển thị nút kết thúc

### Requirement: Khoá/mở đăng ký từng nội dung mọi lúc trước khi kết thúc
Menu của mỗi nội dung ở mục Nội dung SHALL cho khoá hoặc mở lại đăng ký (PATCH `/tournaments/:id/divisions/:divisionId/config` với `isRegistrationLocked`) ở mọi trạng thái giải trừ COMPLETED và CANCELLED. Nội dung đã quá hạn SHALL mở lại kèm hạn mới ở tương lai. Thẻ nội dung SHALL ghi "Đang nhận đăng ký" hoặc "Đã đóng đăng ký" theo `registrationOpen`, và thêm "Không có hạn đăng ký" khi còn mở mà không có hạn.

#### Scenario: Khoá khi giải đang diễn ra
- WHEN giải IN_PROGRESS và BTC chọn "Khoá đăng ký" ở một nội dung
- THEN App gửi PATCH config với `isRegistrationLocked: true`

#### Scenario: Giải đã kết thúc
- WHEN giải COMPLETED
- THEN mục khoá/mở đăng ký trong menu nội dung bị tắt

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
