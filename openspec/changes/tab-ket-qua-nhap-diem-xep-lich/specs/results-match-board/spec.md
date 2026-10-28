## ADDED Requirements

### Requirement: Bảng trận theo vòng trong tab Kết quả
Tab Kết quả SHALL hiển thị bộ chọn vòng và hai nhóm trận **Đã xong** và **Sắp tới** của hạng mục đang chọn, phía trên danh sách trao thưởng hiện có. Nhãn vòng SHALL kèm số trận còn chờ nhập điểm. Trận BYE SHALL không xuất hiện trong bảng.

#### Scenario: Chia trận thành Đã xong và Sắp tới
- **WHEN** một vòng có trận đã hoàn tất và trận chưa đấu
- **THEN** trận hoàn tất nằm ở nhóm Đã xong (mới hoàn tất trước), các trận còn lại nằm ở nhóm Sắp tới (giờ sớm trước, trận không có giờ xuống cuối)

#### Scenario: Vòng mặc định
- **WHEN** tab Kết quả mở lần đầu
- **THEN** vòng được chọn là vòng đầu tiên còn trận chờ nhập điểm; nếu mọi vòng đã xong thì là vòng cuối; nếu không có trận nào thì không hiện bộ chọn vòng

#### Scenario: Vòng đang chọn biến mất sau khi làm mới
- **WHEN** dữ liệu trận tải lại và vòng đang chọn không còn tồn tại
- **THEN** bộ chọn rơi về vòng mặc định thay vì để trống

#### Scenario: Hạng mục có nhiều division
- **WHEN** giải có nhiều hạng mục và người dùng đổi hạng mục
- **THEN** bảng chỉ chứa trận có `divisionId` của hạng mục đó

#### Scenario: Giờ không hợp lệ
- **WHEN** một trận có giờ thi đấu không đọc được
- **THEN** hàng trận hiện "—" ở cột giờ và không làm hỏng việc sắp xếp

### Requirement: Quyền nhập điểm từ tab Kết quả
Chỉ người quản lý giải (chủ giải hoặc đồng tổ chức) SHALL thao tác được trên hàng trận chờ nhập điểm. Một trận chờ nhập điểm là trận có đủ hai đội, không phải BYE và trạng thái không thuộc COMPLETED, FINISHED, DISPUTED, CANCELLED. Người khác SHALL chỉ xem.

#### Scenario: Ban tổ chức bấm trận chờ nhập điểm
- **WHEN** người quản lý bấm một hàng trận chờ nhập điểm
- **THEN** hộp chọn Huỷ / Xem live / Nhập điểm của trận đó được mở

#### Scenario: Trận chưa đủ đội
- **WHEN** một trận Sắp tới chưa có đủ hai đội
- **THEN** hàng hiện trạng thái đang chờ và bấm vào không mở nhập điểm

#### Scenario: Người xem thường
- **WHEN** người dùng không quản lý giải mở tab Kết quả
- **THEN** hàng trận không bấm được và không có nút nhập điểm hay xếp lịch

#### Scenario: ADMIN không phải BTC của giải
- **WHEN** tài khoản ADMIN xem giải của người khác
- **THEN** không hiện thao tác nhập điểm, phù hợp yêu cầu `live-score-access`

### Requirement: Tab Kết quả hiện cho Ban tổ chức
Tab Kết quả SHALL luôn hiện cho người quản lý giải, kể cả khi giải chưa có trận hoàn tất. Với người xem thường, tab SHALL chỉ hiện khi giải đã có kết quả như hiện nay.

#### Scenario: Giải mới chưa có trận xong
- **WHEN** người quản lý mở giải chưa có trận hoàn tất
- **THEN** tab Kết quả vẫn hiện và bảng trận hiển thị các trận Sắp tới

#### Scenario: Người xem và giải chưa có kết quả
- **WHEN** người xem thường mở giải chưa có trận hoàn tất
- **THEN** tab Kết quả không hiện

### Requirement: Trạng thái tải và lỗi của bảng trận
Bảng trận SHALL có trạng thái rỗng khi không có trận phù hợp và SHALL giữ dữ liệu đang hiển thị khi lần làm mới thất bại. Danh sách trao thưởng SHALL tiếp tục hiển thị độc lập với bảng trận.

#### Scenario: Không có trận nào
- **WHEN** hạng mục chưa có trận nào ngoài BYE
- **THEN** hiện thông báo rỗng, danh sách trao thưởng vẫn hiện nếu đã có

#### Scenario: Lỗi mạng thoáng qua
- **WHEN** lần tải lại danh sách trận thất bại sau khi đã có dữ liệu
- **THEN** bảng giữ dữ liệu cũ, không chuyển sang trạng thái lỗi trống

### Requirement: Khối Đang diễn ra ở đầu tab Kết quả
Tab Kết quả SHALL hiển thị ở đầu, phía trên bộ chọn vòng, một khối "Đang diễn ra" gồm card các trận đang diễn ra của hạng mục đang chọn, không phụ thuộc vòng đang chọn. Khối SHALL ẩn hoàn toàn khi hạng mục không có trận đang diễn ra. Card SHALL theo capability `live-match-summary-card`.

#### Scenario: Có trận đang diễn ra ở vòng khác
- **WHEN** vòng đang chọn là Vòng 2 nhưng có một trận đang diễn ra ở Vòng 1
- **THEN** khối "Đang diễn ra" vẫn hiện trận đó phía trên bộ chọn vòng

#### Scenario: Không có trận đang diễn ra
- **WHEN** hạng mục không có trận đang diễn ra
- **THEN** không hiện khối và không chừa khoảng trống
