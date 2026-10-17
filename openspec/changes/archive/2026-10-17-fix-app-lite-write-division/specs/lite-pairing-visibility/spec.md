## MODIFIED Requirements

### Requirement: Màn quản lý ghi sơ đồ và VĐV ảo theo nội dung đang chọn
Màn quản lý Lite MUST hỏi BTC chọn nội dung khi giải có từ hai nội dung dùng được và chưa có nội dung đang chọn, trước mọi thao tác GHI cấu hình theo nội dung: tạo sơ đồ, ghép ngẫu nhiên, reset, thêm hoặc xoá VĐV ảo, đổi thể thức và đổi sức chứa. App MUST NOT ghi vào nội dung đầu tiên.

#### Scenario: Giải nhiều nội dung chưa chọn
- **WHEN** BTC bấm tạo sơ đồ, reset, ghép ngẫu nhiên, thêm hoặc xoá VĐV ảo, đổi thể thức hoặc nhập sức chứa khi chưa chọn nội dung
- **THEN** màn hiện hộp chọn nội dung và chưa gọi API nào

#### Scenario: BTC chọn nội dung
- **WHEN** BTC chọn một nội dung và xác nhận
- **THEN** màn tải lại sơ đồ và trận của nội dung đó, và thao tác tiếp tục với nội dung đó

#### Scenario: BTC huỷ chọn
- **WHEN** BTC huỷ hộp chọn nội dung
- **THEN** thao tác dừng, không gọi API và không hiện thông báo lỗi

#### Scenario: Đã chọn nội dung trước đó
- **WHEN** màn đã có nội dung đang chọn
- **THEN** không hỏi lại và thao tác ghi dùng nội dung đó

#### Scenario: Giải một nội dung
- **WHEN** giải có đúng một nội dung dùng được
- **THEN** không hỏi và dùng nội dung đó như trước

#### Scenario: Chưa chọn thì hiển thị nội dung đầu tiên
- **WHEN** giải có nhiều nội dung và màn chưa có nội dung đang chọn
- **THEN** sơ đồ, trận và định dạng hiển thị nội dung đầu tiên, chỉ để đọc, không dùng để ghi

#### Scenario: Notifier nhận thao tác ghi khi chưa chọn
- **WHEN** notifier nhận thao tác ghi khi giải có nhiều nội dung và chưa chọn nội dung
- **THEN** ném lỗi trước khi gửi request, không gửi `divisionId` và không để cờ đang xử lý bị kẹt

#### Scenario: Đổi thể thức ghi đúng nội dung đã chọn
- **WHEN** BTC đã chọn nội dung d2 của giải có hai nội dung và đổi đơn/đôi
- **THEN** App chỉ PATCH cấu hình của d2, không PATCH cấu hình nội dung đầu tiên

#### Scenario: Đổi sức chứa ghi đúng nội dung đã chọn
- **WHEN** BTC đã chọn nội dung d2 của giải có hai nội dung và nhập sức chứa
- **THEN** App PATCH sức chứa vào cấu hình của d2, không PATCH cấu hình nội dung đầu tiên
