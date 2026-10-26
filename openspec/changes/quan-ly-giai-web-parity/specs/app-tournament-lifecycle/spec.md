## MODIFIED Requirements

### Requirement: Điều khiển vòng đời giải từ màn quản lý
App SHALL hiển thị đúng một nút vòng đời theo việc tiếp theo: DRAFT "Công bố"; UPCOMING "Mở đăng ký ngay"; REGISTRATION_OPEN "Chốt đăng ký" (`/close-registration`), kể cả khi đã có sơ đồ; REGISTRATION_CLOSED "Khai mạc giải" với cảnh báo khóa đăng ký mọi nội dung; IN_PROGRESS "Kết thúc giải". Mỗi thao tác SHALL hỏi xác nhận, chống gửi lặp và hiện nguyên lỗi máy chủ. Khai mạc SHALL chỉ gọi POST `/tournaments/:id/start`; Backend khóa mọi division cùng transaction đổi trạng thái sang IN_PROGRESS.

Khai mạc khi còn hạng mục đang mở đăng ký SHALL hiện sheet liệt kê từng hạng mục đang mở kèm lựa chọn "đóng đăng ký hạng mục này" (mặc định đóng hết) và cảnh báo (hạng mục chưa có sơ đồ, VĐV đang chờ duyệt); App gửi `POST /tournaments/:id/close-registration` với `divisionIds` của các hạng mục chọn đóng (nếu có) rồi mới `POST /tournaments/:id/start`. Kết thúc giải SHALL hiện checklist: tỉ lệ trận đã xong, danh sách trận đang LIVE (nút kết thúc bị chặn khi còn trận LIVE), hạng mục còn trận chưa xong; thao tác kết thúc SHALL khả dụng cho cả organizer lẫn admin (Backend chốt quyền).

#### Scenario: Khai mạc giải đã chốt đăng ký
- WHEN BTC xác nhận khai mạc giải REGISTRATION_CLOSED
- THEN App cảnh báo rằng khai mạc khóa đăng ký tất cả nội dung, chỉ gửi POST `/tournaments/:id/start`, và sau thành công không division nào còn nhận đăng ký

#### Scenario: Khai mạc khi còn hạng mục mở
- WHEN giải đã chốt đăng ký cấp giải nhưng vẫn còn hạng mục được mở lại và BTC bấm "Khai mạc giải"
- THEN sheet liệt kê từng hạng mục đang mở với lựa chọn đóng kèm cảnh báo; App chỉ gửi POST `/start` sau khi đã đóng các hạng mục được chọn (hoặc BTC tắt chọn đóng và tự chịu cảnh báo)

#### Scenario: Đăng ký còn mở dù đã có sơ đồ
- WHEN giải REGISTRATION_OPEN và có ít nhất một division đang mở đăng ký
- THEN App chỉ hiển thị "Chốt đăng ký", không hiển thị "Khai mạc giải", kể cả khi đã có sơ đồ

#### Scenario: Mở lại một nội dung sau khai mạc
- WHEN giải IN_PROGRESS và BTC mở lại một division
- THEN App tiếp tục dùng `registrationOpen` do Backend trả về cho nội dung đó; quy tắc đăng ký không tự đổi theo trạng thái giải

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

#### Scenario: Kết thúc giải còn trận LIVE
- WHEN giải IN_PROGRESS còn trận ONGOING và BTC mở sheet kết thúc
- THEN App liệt kê các trận đang LIVE, chặn nút "Kết thúc giải" cho tới khi không còn trận LIVE, và hiển thị "trận đã xong X/Y"

#### Scenario: Organizer kết thúc giải
- WHEN người dùng là organizer (không phải admin) của giải IN_PROGRESS không còn trận LIVE
- THEN App cho xác nhận và gửi POST `/tournaments/:id/complete`; nếu Backend từ chối thì hiển thị nguyên văn lỗi

#### Scenario: Trạng thái không đủ điều kiện
- WHEN giải ở trạng thái DRAFT, UPCOMING, COMPLETED hoặc CANCELLED
- THEN App không hiển thị nút khai mạc; khi giải không IN_PROGRESS App không hiển thị nút kết thúc

### Requirement: Khoá/mở đăng ký từng nội dung mọi lúc trước khi kết thúc
Menu của mỗi nội dung ở mục Nội dung SHALL cho khoá hoặc mở lại đăng ký (PATCH `/tournaments/:id/divisions/:divisionId/config` với `isRegistrationLocked`) ở mọi trạng thái giải trừ COMPLETED và CANCELLED. Nội dung đã quá hạn SHALL mở lại kèm hạn mới ở tương lai. Thẻ nội dung SHALL ghi "Đang nhận đăng ký" hoặc "Đã đóng đăng ký" theo `registrationOpen`, và thêm "Không có hạn đăng ký" khi còn mở mà không có hạn.

Ngoài thao tác từng nội dung, màn quản lý SHALL có sheet đóng/mở đăng ký HÀNG LOẠT: checkbox chọn nhiều hạng mục cùng lúc kèm chọn hết; chế độ đóng gửi một lần `POST /tournaments/:id/close-registration` với `divisionIds`; chế độ mở gửi `POST /tournaments/:id/reopen-registration` với `divisionIds`, và khi có hạng mục đã quá hạn thì bắt chọn hạn mới trong chính sheet trước khi gửi.

#### Scenario: Khoá khi giải đang diễn ra
- WHEN giải IN_PROGRESS và BTC chọn "Khoá đăng ký" ở một nội dung
- THEN App gửi PATCH config với `isRegistrationLocked: true`

#### Scenario: Giải đã kết thúc
- WHEN giải COMPLETED
- THEN mục khoá/mở đăng ký trong menu nội dung bị tắt

#### Scenario: Đóng hàng loạt nhiều hạng mục
- WHEN BTC chọn 3 hạng mục đang mở trong sheet đóng đăng ký và bấm xác nhận
- THEN App gửi một lần close-registration với đúng 3 `divisionIds` đó và tải lại trạng thái hạng mục

#### Scenario: Mở lại hàng loạt có hạng mục quá hạn
- WHEN BTC chọn mở lại 2 hạng mục trong đó 1 hạng mục đã quá hạn đăng ký
- THEN sheet bắt chọn hạn mới ở tương lai (áp cho cả hai) rồi mới gửi reopen-registration kèm `registrationEndDate` và `divisionIds`

## ADDED Requirements

### Requirement: Đề nghị đóng đăng ký khi hạng mục đủ chỗ
Khi danh sách hạng mục vừa tải cho thấy hạng mục đang mở đã đủ `registered` so với sức chứa và chưa từng hỏi trong phiên màn đó, App SHALL hiện sheet đề nghị per hạng mục: "Đóng đăng ký" (gửi close-registration với `divisionIds` tương ứng) hoặc "Giữ mở" (không gửi gì, không hỏi lại hạng mục đó trong phiên màn).

#### Scenario: Hạng mục vừa đủ chỗ
- WHEN BTC mở màn quản lý và hạng mục "Đơn Nam" có 32/32 VĐV, đang mở
- THEN sheet tự hiện "Đơn Nam đã đủ chỗ" với 2 nút Đóng đăng ký / Giữ mở

#### Scenario: Chọn giữ mở
- WHEN BTC bấm "Giữ mở"
- THEN App không gửi gì và không hỏi lại hạng mục này tới khi rời màn

#### Scenario: Đóng từng hạng mục trong prompt
- WHEN prompt liệt kê 2 hạng mục đủ chỗ và BTC bấm "Đóng đăng ký" ở hạng mục thứ nhất, "Giữ mở" ở hạng mục thứ hai
- THEN App chỉ gửi close-registration với `divisionIds` của hạng mục thứ nhất, hiển thị kết quả từng hạng mục
