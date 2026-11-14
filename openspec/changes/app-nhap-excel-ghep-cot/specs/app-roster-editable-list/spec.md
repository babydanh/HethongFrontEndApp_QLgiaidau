## ADDED Requirements

### Requirement: Danh sách VĐV dạng thẻ theo cặp
Danh sách sau khi đọc file MUST hiển thị mỗi cặp (hoặc VĐV đơn) một thẻ gồm chữ cái đầu, tên và SĐT mờ của từng VĐV, vạch ngăn giữa hai VĐV và một tròn trạng thái. Thẻ MUST NOT thêm câu chữ dài. Chân trang MUST giữ `đủ điều kiện/tổng` và nút `Nhập N VĐV`.

#### Scenario: Thẻ cặp đủ điều kiện
- **WHEN** preview trả `isEligible: true` cho dòng hai VĐV
- **THEN** thẻ hiện hai VĐV và tròn ✓ xanh

#### Scenario: Không có dòng nào
- **WHEN** file đọc xong mà không có dòng VĐV
- **THEN** danh sách giữ thông báo "File không có dòng VĐV nào" và nút `Ghép cột` được nhấn mạnh

### Requirement: Tròn trạng thái và icon tài khoản của thẻ
Tròn trạng thái MUST là ✕ đỏ khi dòng bị chặn (mã chặn cục bộ hoặc server, lỗi ghi chú, hoặc server báo không đủ điều kiện), ! vàng khi đủ điều kiện nhưng còn cảnh báo (thiếu email, nội dung đôi chưa có VĐV 2), ✓ xanh khi đủ điều kiện, và vòng tải khi preview đang chạy mà chưa có kết quả cho dòng. Trạng thái tài khoản MUST hiển thị bằng icon: liên kết xanh khi tài khoản sẽ được dùng, icon người mờ khi không có tài khoản trùng email.

#### Scenario: Thẻ bị chặn
- **WHEN** dòng có mã `DUPLICATE_IN_FILE`
- **THEN** thẻ hiện tròn ✕ đỏ và nền nhạt đỏ

#### Scenario: Chưa có tài khoản không phải cảnh báo
- **WHEN** server trả `NOT_FOUND` cho email và dòng vẫn đủ điều kiện
- **THEN** tròn là ✓ xanh và VĐV đó có icon người mờ, không có chữ

#### Scenario: Preview chưa trả về
- **WHEN** preview đang chạy hoặc chưa chạy
- **THEN** thẻ hiện vòng tải thay cho tròn trạng thái và không hiện icon tài khoản

### Requirement: Chi tiết một cặp sửa được
Chạm thẻ MUST mở bottom sheet chi tiết có dải lý do (vàng/đỏ) khi dòng có mã trạng thái, mỗi VĐV một ô tên, ô SĐT, ô email và nút tài khoản (`Tự liên kết`, `Không liên kết`, hoặc tài khoản đã chọn trong danh sách ứng viên của preview), ô tích `Đã đóng phí`, ô Ghi chú nhiều dòng chứa nguyên chuỗi ghi chú, nút `Xóa cặp` và `Xong`. Chi tiết MUST NOT có ô Nội dung hay ELO theo dòng. VĐV 2 MUST chỉ hiện khi dòng thuộc nội dung đôi hoặc đã có dữ liệu VĐV 2. Sửa MUST chỉ có hiệu lực khi bấm `Xong`.

#### Scenario: Đóng chi tiết không bấm Xong
- **WHEN** người dùng sửa tên rồi đóng sheet bằng nút đóng
- **THEN** dữ liệu dòng giữ nguyên và preview không chạy lại

#### Scenario: Singles không hiện VĐV 2
- **WHEN** dòng thuộc nội dung đơn và không có dữ liệu VĐV 2
- **THEN** chi tiết chỉ có một khối VĐV

### Requirement: Kiểm tra lại dòng sau khi sửa
Bấm `Xong` ở chi tiết MUST kiểm tra lại dòng bằng cùng quy tắc cục bộ lúc đọc file (thiếu tên, thiếu email, email sai định dạng, trùng email trong file, quy tắc VĐV 2 theo nội dung), rồi chạy lại preview đúng một lần. Ô email MUST báo đỏ ngay khi sai định dạng. Ô trống MUST thành "không có dữ liệu" và MUST NOT được thay bằng chữ giả. Ghi chú MUST bị cắt ở 2000 ký tự.

#### Scenario: Sửa email sai thành đúng
- **WHEN** dòng có `INVALID_EMAIL` và người dùng nhập email đúng định dạng rồi bấm `Xong`
- **THEN** dòng hết mã `INVALID_EMAIL` và preview được gọi lại với dòng đó

#### Scenario: Xóa hết tên VĐV 1
- **WHEN** người dùng xóa trống ô tên VĐV 1 rồi bấm `Xong`
- **THEN** dòng có mã `MISSING_NAME` và bị chặn, không có chữ như "Chưa xác định" thế vào chỗ trống

#### Scenario: Nội dung đơn nhưng có VĐV 2
- **WHEN** người dùng nhập tên VĐV 2 cho dòng thuộc nội dung đơn
- **THEN** dòng có mã `PLAYER2_NOT_ALLOWED` và bị chặn

#### Scenario: Sửa thành trùng email trong file
- **WHEN** người dùng nhập email trùng với một dòng khác
- **THEN** cả hai dòng có mã `DUPLICATE_IN_FILE` và cả hai thẻ hiện ✕ đỏ

### Requirement: Email đã sửa đặt lại liên kết tài khoản
Khi email của một VĐV đổi (so sánh sau khi cắt khoảng trắng và hạ chữ thường), lựa chọn tài khoản của VĐV đó MUST được đặt về `Tự liên kết` và ứng viên tài khoản cũ của dòng MUST bị bỏ, vì Backend từ chối tài khoản đã chọn không còn khớp email. Khi chỉ tên, SĐT, ghi chú hoặc `Đã đóng phí` đổi thì lựa chọn tài khoản MUST được giữ. App MUST NOT tự tìm tài khoản ở phía client; tài khoản chỉ đến từ `accountCandidates` của preview.

#### Scenario: Đổi email của VĐV đã chọn tài khoản
- **WHEN** VĐV 1 đang liên kết một tài khoản và người dùng đổi email rồi `Xong`
- **THEN** liên kết của VĐV 1 là `Tự liên kết` và payload preview mới không có `confirmedPlayer1UserId` cũ

#### Scenario: Chỉ đổi tên
- **WHEN** người dùng chỉ đổi tên VĐV 1 đang liên kết một tài khoản
- **THEN** payload preview mới vẫn có `confirmedPlayer1UserId` đó

### Requirement: Xóa cặp có hoàn tác
`Xóa cặp` MUST bỏ dòng khỏi danh sách, bỏ nhóm nếu nhóm trống, tính lại trùng email trong file, chạy lại preview và hiện thanh thông báo có nút `Hoàn tác` trong 5 giây. `Hoàn tác` MUST đưa dòng về đúng vị trí và đúng chỉ số. Mọi chỉnh sửa khác MUST dập tắt khả năng hoàn tác.

#### Scenario: Xóa rồi hoàn tác
- **WHEN** người dùng xóa cặp thứ 3 rồi bấm `Hoàn tác` trong 5 giây
- **THEN** cặp trở lại vị trí thứ 3 với cùng `clientRowIndex` và preview chạy lại

#### Scenario: Xóa rồi sửa dòng khác
- **WHEN** người dùng xóa một cặp rồi sửa tên ở cặp khác
- **THEN** nút `Hoàn tác` của lần xóa không còn tác dụng

#### Scenario: Xóa hết
- **WHEN** người dùng xóa cặp cuối cùng
- **THEN** danh sách rỗng, nút nhập tắt, và không có lần gọi preview với payload rỗng

### Requirement: Thêm cặp bằng tay
Nút `+` trên thanh tiêu đề MUST mở chi tiết rỗng; `Xong` chỉ thêm dòng khi có tên hoặc email, vào nhóm của nội dung đang mở, với chỉ số nhỏ nhất chưa dùng trong 0..499. Khi đã có 500 dòng, nút `+` MUST bị tắt. Dòng thêm tay MUST gửi lên không có `sourceRowIndex` và không có `sourceSheetName`, vì Backend yêu cầu `sourceRowIndex` ≥ 1.

#### Scenario: Thêm cặp khi đủ 500 dòng
- **WHEN** danh sách có 500 dòng
- **THEN** nút `+` bị tắt

#### Scenario: Thêm cặp rỗng
- **WHEN** người dùng mở `+` rồi bấm `Xong` mà không nhập gì
- **THEN** không có dòng mới và không có lần gọi preview

#### Scenario: Chỉ số khi đã xóa
- **WHEN** danh sách đã xóa dòng có chỉ số 7 và người dùng thêm một cặp
- **THEN** dòng mới nhận chỉ số nhỏ nhất chưa dùng, không vượt 499 và không trùng chỉ số đang dùng

#### Scenario: Payload dòng thêm tay
- **WHEN** preview được gọi sau khi thêm một cặp tay
- **THEN** item của dòng đó không có `sourceRowIndex` và không có `sourceSheetName`

### Requirement: Nút Nhập chỉ bật khi preview khớp payload hiện tại
Nút `Nhập N VĐV` MUST chỉ bật khi preview gần nhất được tính trên đúng payload hiện tại (so khóa JSON của payload). Sau mọi chỉnh sửa (tên, email, tích, ghi chú, xóa, thêm, ghép cột) nút MUST tắt cho tới khi preview của payload mới trả về. Câu trả lời preview của lần gọi cũ MUST bị bỏ khi đã có lần gọi mới.

#### Scenario: Sửa xong chưa có preview mới
- **WHEN** người dùng sửa một dòng và preview của payload mới chưa trả về
- **THEN** nút `Nhập N VĐV` bị tắt

#### Scenario: Preview cũ đến muộn
- **WHEN** người dùng sửa hai lần liên tiếp và câu trả lời của lần gọi thứ nhất đến sau lần thứ hai
- **THEN** danh sách chỉ dùng kết quả của lần gọi thứ hai

#### Scenario: Quá 500 dòng
- **WHEN** file có hơn 500 dòng
- **THEN** chân trang hiện thông báo vượt giới hạn và nút nhập bị tắt

### Requirement: Khóa chỉnh sửa khi bận và nhập chống gửi trùng
Chỉnh sửa, xóa, thêm MUST bị tắt khi đang nhập, đang tạo nội dung hoặc đang đọc file. Lần nhập MUST gửi đúng lựa chọn tài khoản như đã dùng khi preview, và `Idempotency-Key` MUST do nội dung payload quyết định: cùng payload gửi lại thì cùng key.

#### Scenario: Bấm Nhập hai lần liên tiếp
- **WHEN** người dùng bấm `Nhập` hai lần nhanh
- **THEN** chỉ có một request nhập được gửi

#### Scenario: Nhập lỗi mạng rồi thử lại
- **WHEN** nhập thất bại do mạng và người dùng bấm lại với cùng dữ liệu
- **THEN** request gửi lại có cùng `Idempotency-Key` và khi server trả `replayed` App báo "đã được ghi nhận trước đó"

#### Scenario: Đang nhập
- **WHEN** đang nhập
- **THEN** chạm thẻ không mở chi tiết và nút `+` bị tắt

### Requirement: Mọi chuỗi danh sách và chi tiết có hai ngôn ngữ
Mọi chuỗi mới MUST có key cùng tên trong `app_vi.arb` và `app_en.arb`, tiền tố `rosterList`, code sinh bằng `flutter gen-l10n`. Giao diện MUST dùng token màu `AppTheme`, vùng chạm ≥ 44 dp, icon vector, không emoji.

#### Scenario: Tiếng Anh
- **WHEN** ngôn ngữ là tiếng Anh
- **THEN** thẻ, chi tiết và thông báo xóa/hoàn tác đều hiện tiếng Anh
