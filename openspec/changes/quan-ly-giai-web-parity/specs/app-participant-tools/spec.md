## ADDED Requirements

### Requirement: Lọc VĐV theo trạng thái trong màn quản lý
Tab VĐV của màn quản lý SHALL có bộ lọc trạng thái (Tất cả / Chờ duyệt / Chờ đối tác / Đã đủ / Chưa thanh toán / Từ chối) hiển thị kèm số lượng từng trạng thái như Web; chọn trạng thái lọc danh sách hiện tại không gọi lại API.

#### Scenario: Lọc chờ duyệt
- WHEN BTC chọn trạng thái "Chờ duyệt"
- THEN danh sách chỉ hiện người/participant đang PENDING và chip số lượng đúng số đếm

### Requirement: Sheet hồ sơ VĐV chi tiết của BTC
Từ mỗi dòng VĐV, App SHALL mở sheet hồ sơ chứa: trạng thái + thanh toán, sửa liên hệ từng thành viên (tên/email/phone), ghi chú nội bộ BTC lưu qua `PATCH /participants/:id/note`, câu trả lời form đăng ký tùy chỉnh (kể cả tên file đính kèm), gán seed nhanh, khoá/mở roster đội bóng, xoá VĐV ảo (confirm), duyệt/từ chối. Mọi thao tác ghi SHALL chống gửi lặp và giữ nguyên văn lỗi máy chủ.

#### Scenario: Sửa ghi chú nội bộ
- WHEN BTC nhập ghi chú và bấm lưu
- THEN App gửi PATCH `/participants/:id/note` với nội dung mới và sheet vẫn mở, ghi chú được làm mới

#### Scenario: VĐV ảo
- WHEN hồ sơ là VĐV ảo (mock)
- THEN sheet hiện nút "Xoá VĐV ảo" có confirm trước khi gọi route xoá mà Web dùng

### Requirement: Tách cặp trong màn quản lý
Menu dòng của participant thuộc cặp đôi SHALL có "Tách cặp" với confirm; xác nhận gọi `POST /tournaments/:id/pairing/:participantId/unpair` và làm mới danh sách.

#### Scenario: Tách một cặp
- WHEN BTC chọn "Tách cặp" trên một participant và xác nhận
- THEN hai người trở về trạng thái chờ cặp, danh sách cập nhật

### Requirement: Sinh và xoá VĐV ảo
Màn quản lý SHALL có sheet sinh VĐV ảo: chọn hạng mục, chế độ (đôi tự ghép / đơn BTC tự ghép), nhập tên mỗi dòng (hoặc dán từ vùng nhớ); xác nhận gọi `POST /tournaments/:id/mock-participants`; kèm nút "Xoá hết VĐV ảo" (confirm) gọi `DELETE /tournaments/:id/mock-participants`.

#### Scenario: Sinh 8 VĐV ảo hạng mục đơn
- WHEN BTC nhập 8 dòng tên và xác nhận
- THEN App gửi mock-participants với đúng danh sách và danh sách VĐV xuất hiện 8 người

#### Scenario: Xoá sạch VĐV ảo
- WHEN BTC bấm "Xoá hết VĐV ảo" và xác nhận
- THEN mọi participant ảo của giải bị xoá, người thật giữ nguyên

### Requirement: Wildcard giữ chỗ
Màn quản lý SHALL có sheet wildcard: chọn hạng mục, email hoặc số điện thoại VĐV (và đồng đội nếu hạng mục đôi), tên đội; validate bắt buộc email + tên đội; xác nhận gọi `POST /tournaments/:id/reserve-slots` như Web.

#### Scenario: Gán wildcard cho cặp đôi
- WHEN BTC nhập email hai VĐV và tên đội "Đội khách mời"
- THEN App gửi reserve-slots và hạng mục xuất hiện cặp ở trạng thái giữ chỗ

### Requirement: Xuất Excel danh sách VĐV
Menu xuất dữ liệu của hub SHALL thêm lựa chọn xuất danh sách VĐV (sheet: họ tên, liên hệ, hạng mục, trạng thái, seed, thanh toán) bằng cùng thư viện Excel hiện có, không thêm package.

#### Scenario: Xuất khi có 2 hạng mục
- WHEN giải có 2 hạng mục với VĐV đã đăng ký và BTC chọn "Xuất danh sách VĐV"
- THEN file Excel sinh ra chứa đủ VĐV của cả hai hạng mục, chia cột hạng mục
