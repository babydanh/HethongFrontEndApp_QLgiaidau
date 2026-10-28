## ADDED Requirements

### Requirement: Nhập điểm từ Bracket và Lịch thi đấu
Người quản lý giải SHALL nhập điểm được một trận chờ nhập điểm từ thẻ Bracket, bảng trận và tab Lịch thi đấu, qua cùng hộp chọn Huỷ / Xem live / Nhập điểm. Điều kiện "chờ nhập điểm" SHALL giống tab Kết quả.

#### Scenario: Bấm thẻ trận ở Bracket
- **WHEN** người quản lý bấm thẻ trận chờ nhập điểm trên Bracket
- **THEN** hộp chọn mở; chọn Nhập điểm đưa tới màn chấm điểm ở chế độ không phải người xem

#### Scenario: Trận đã khoá
- **WHEN** trận đã hoàn tất, tranh chấp hoặc huỷ
- **THEN** không mở hộp nhập điểm

#### Scenario: Không có quyền
- **WHEN** người dùng không quản lý giải và không phải trọng tài của trận
- **THEN** bấm thẻ chỉ xem như hiện nay, không có hộp nhập điểm

### Requirement: Xếp lịch một trận từ thẻ Bracket
Người quản lý giải SHALL có nút **Xếp lịch** trên thẻ trận (Bracket và bảng trận) để đặt hoặc xoá sân và giờ của MỘT trận. Hộp xếp lịch SHALL cho chọn sân, ngày giờ và lưu qua API cập nhật lịch trận hiện có. Trận đang diễn ra hoặc đã xong SHALL không xếp lịch được.

#### Scenario: Đặt sân và giờ
- **WHEN** người quản lý chọn sân và giờ rồi lưu
- **THEN** lịch của trận được cập nhật ở Backend, thẻ trận hiện sân và giờ mới sau khi làm mới

#### Scenario: Xoá lịch
- **WHEN** người quản lý chọn bỏ sân và giờ rồi lưu
- **THEN** trận trở về trạng thái chưa xếp lịch

#### Scenario: Bấm lưu hai lần
- **WHEN** người dùng bấm Lưu liên tiếp khi yêu cầu đang chạy
- **THEN** chỉ gửi một yêu cầu

#### Scenario: Mạng rớt hoặc Backend từ chối
- **WHEN** yêu cầu lưu thất bại
- **THEN** hộp vẫn mở, dữ liệu người dùng nhập được giữ, hiện thông báo lỗi dễ hiểu không lộ chi tiết kỹ thuật

#### Scenario: Trận bị khoá
- **WHEN** trận đang LIVE hoặc đã hoàn tất
- **THEN** nút Xếp lịch bị ẩn hoặc vô hiệu

#### Scenario: Người không quản lý
- **WHEN** người dùng không phải người quản lý giải
- **THEN** không hiện nút Xếp lịch

### Requirement: Làm mới dữ liệu sau thao tác
Sau khi lưu lịch hoặc quay lại từ nhập điểm, các màn Kết quả, Lịch thi đấu và Bracket SHALL hiển thị dữ liệu mới mà người dùng không phải thoát màn hình.

#### Scenario: Lưu lịch xong
- **WHEN** lưu lịch thành công
- **THEN** danh sách trận ở các tab cùng giải được tải lại
