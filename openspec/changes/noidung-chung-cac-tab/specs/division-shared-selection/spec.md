## ADDED Requirements

### Requirement: Lựa chọn nội dung dùng chung giữa các tab quản lý
Hub quản lý giải SHALL giữ một lựa chọn nội dung thi đấu duy nhất cho tab Bảng đấu, Lịch và Vận động viên, và mỗi tab SHALL chọn nội dung bằng `DivisionStrip`.

#### Scenario: Đổi nội dung ở Bảng đấu rồi sang Lịch
- **WHEN** BTC chọn "Đôi Nam" ở tab Bảng đấu rồi mở tab Lịch
- **THEN** chip "Đôi Nam" đang được chọn ở tab Lịch và lưới chỉ có trận của nội dung đó

#### Scenario: Đổi ở Vận động viên
- **WHEN** BTC chọn "Đơn Nữ" ở tab Vận động viên rồi mở tab Bảng đấu
- **THEN** chip "Đơn Nữ" đang được chọn ở Bảng đấu

#### Scenario: Nội dung đang chọn đã bị xoá
- **WHEN** nội dung đang chọn không còn trong giải
- **THEN** các tab lùi về nội dung đầu tiên

### Requirement: Lưới sân không còn bộ chọn riêng
Lưới sân của tab Lịch SHALL không hiện dropdown chọn nội dung; việc chọn do `DivisionStrip` đảm nhận.

#### Scenario: Giải nhiều nội dung
- **WHEN** giải có nhiều hơn một nội dung và mở lưới sân
- **THEN** có dải chip chọn nội dung và không có dropdown `schedule-division-dropdown`

### Requirement: Tab Vận động viên hiện theo nội dung đang chọn
Tab Vận động viên SHALL hiện danh sách VĐV và các nút thao tác của nội dung đang chọn trên `DivisionStrip`, không dùng danh sách thu gọn theo nội dung.

#### Scenario: Chọn nội dung
- **WHEN** BTC bấm chip một nội dung ở tab Vận động viên
- **THEN** hiện VĐV và nút thêm/nhập/ghép của nội dung đó

### Requirement: Màn Kết quả công khai dùng dải chung
Màn Kết quả công khai SHALL chọn nội dung bằng `DivisionStrip`.

#### Scenario: Chọn nội dung ở Kết quả
- **WHEN** người xem bấm chip một nội dung
- **THEN** danh sách kết quả lọc theo nội dung đó
