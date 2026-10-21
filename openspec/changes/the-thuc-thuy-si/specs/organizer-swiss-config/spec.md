## ADDED Requirements

### Requirement: Cấu hình nội dung Thụy Sĩ
App SHALL cho BTC chọn thể thức Thụy Sĩ cho nội dung và đặt số vòng, thứ tự tiebreak, cách ghép vòng 1, và SHALL gửi đúng hình dạng `roundConfig.swiss` theo hợp đồng (trước khi sinh sơ đồ qua cấu hình nội dung; sau khi sinh qua `PATCH /tournaments/:id/stages/:stageId`).

#### Scenario: Chọn Thụy Sĩ
- **WHEN** BTC chọn `Thụy Sĩ` trong danh sách thể thức của nội dung
- **THEN** hiện ô Số vòng (mặc định `max(1, ceil(log2(số đội)))`), lựa chọn Ghép vòng 1 (Theo hạt giống / Ngẫu nhiên) và danh sách thứ tự tiebreak; không hiện cấu hình số bảng của vòng bảng

#### Scenario: Số vòng ngoài miền
- **WHEN** BTC nhập số vòng 0, rỗng hoặc lớn hơn mức cho phép
- **THEN** giá trị được kẹp vào miền hợp lệ (rỗng thì khôi phục giá trị trước)

#### Scenario: Giảm dưới số vòng đã ghép
- **WHEN** stage đã có vòng 3 và BTC nhập 2
- **THEN** giá trị bị kẹp lên 3 kèm dòng chữ "Không nhỏ hơn số vòng đã ghép (3)" và không gửi giá trị 2

### Requirement: Sắp thứ tự tiebreak
App SHALL cho BTC sắp lại và bật/tắt từng tiêu chí trong danh sách phẳng đánh số bằng kéo thả (`ReorderableListView`) hoặc nút Lên/Xuống, và SHALL không cho trùng hay thêm tiêu chí ngoài bảy giá trị của hợp đồng.

#### Scenario: Đổi thứ tự
- **WHEN** BTC kéo `Hiệu số điểm` lên trên `Buchholz` hoặc bấm Lên
- **THEN** `tiebreakOrder` mới được lưu

#### Scenario: Tắt tiêu chí
- **WHEN** BTC tắt `BUCHHOLZ`
- **THEN** `tiebreakOrder` không còn `BUCHHOLZ` và bảng xếp hạng không còn cột Buchholz

#### Scenario: Lưu lỗi
- **WHEN** Backend trả 400 khi lưu
- **THEN** hiện lỗi ngắn, giá trị hiển thị trở về bản đã lưu, giữ nguyên các ô khác BTC đã nhập
