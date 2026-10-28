## ADDED Requirements

### Requirement: Card trận đang diễn ra gọn
Card trận đang diễn ra SHALL hiển thị: chấm đỏ nhấp nháy (không kèm chữ "TRỰC TIẾP"), nhãn lượt/vòng, mã trận (chỉ khi nơi gọi cung cấp mã), hai đội mỗi bên có avatar và tên rút gọn, tỉ số ván to ở giữa kèm điểm từng ván, và dòng giờ · sân. Card SHALL NOT hiển thị nhãn tên nhánh (như "Main Bracket"), chữ "Đang thi đấu" hay chữ "Vào phòng Live". Chạm vào card SHALL mở phòng xem live của trận.

#### Scenario: Card của người xem
- **WHEN** người xem thường mở một trận đang diễn ra có giờ và sân
- **THEN** card hiện chấm đỏ, nhãn lượt, mã trận, hai đội, tỉ số ván và "giờ · sân", không có nút nào khác ngoài vùng chạm cả card

#### Scenario: Chưa có mã trận
- **WHEN** nơi gọi không truyền mã trận
- **THEN** góc phải đầu card để trống, không hiện "#null" hay khoảng trắng thừa

#### Scenario: Thiếu giờ hoặc sân
- **WHEN** trận đang diễn ra chưa có giờ hoặc chưa có sân
- **THEN** dòng chân card chỉ hiện phần có dữ liệu, không hiện "null" hay dấu phân cách thừa

#### Scenario: Tên đội dài
- **WHEN** tên đội dài hơn chỗ chứa
- **THEN** tên bị cắt bằng dấu "…" trên một dòng, không tràn ngang, không đẩy tỉ số lệch

### Requirement: Nút nhập điểm chỉ cho Ban tổ chức
Card trận đang diễn ra SHALL có thêm đúng một nút nhập điểm (biểu tượng bút) ở chân card khi và chỉ khi người dùng quản lý giải và trận thỏa `canEnterScore`. Bấm nút SHALL mở hộp chọn Huỷ / Xem live / Nhập điểm; chạm phần còn lại của card vẫn mở phòng xem live.

#### Scenario: Ban tổ chức
- **WHEN** chủ giải hoặc đồng tổ chức xem card trận đang diễn ra
- **THEN** chân card có nút bút, bấm vào mở hộp chọn Huỷ / Xem live / Nhập điểm

#### Scenario: Không phải Ban tổ chức
- **WHEN** người xem thường hoặc ADMIN không quản lý giải này xem card
- **THEN** không có nút bút

### Requirement: Một trận chỉ hiện một chỗ và số đếm khớp danh sách
Trận đang diễn ra là trận đang LIVE/ONGOING/IN_PROGRESS, không phải BYE, chưa hoàn tất và chưa có đội thắng. Trong tab Kết quả, mỗi trận đang diễn ra SHALL chỉ xuất hiện ở khối "Đang diễn ra", không xuất hiện lại ở nhóm "Sắp tới". Số đếm trên tiêu đề khối SHALL bằng số card đang hiển thị, lấy từ cùng một danh sách.

#### Scenario: Trận live không lặp
- **WHEN** hạng mục có 2 trận đang diễn ra và 3 trận chưa đấu
- **THEN** khối "Đang diễn ra" có 2 card, nhóm "Sắp tới" có 3 hàng, và 2 trận live không xuất hiện trong "Sắp tới"

#### Scenario: Trận đã có đội thắng nhưng trạng thái chưa đổi
- **WHEN** một trận còn trạng thái ONGOING nhưng đã có `completedAt` hoặc `winnerId`
- **THEN** trận không được tính là đang diễn ra và không có card
