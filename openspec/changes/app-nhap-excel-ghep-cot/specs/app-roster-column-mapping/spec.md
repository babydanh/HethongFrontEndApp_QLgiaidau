## ADDED Requirements

### Requirement: Popup Ghép cột mở từ màn Nhập Excel
Sau khi đọc file xong, màn Nhập Excel MUST có nút `Ghép cột` mở một bottom sheet cao gần hết màn. Nút MUST bị tắt khi App đang hỏi AI về bố cục, đang đọc file, đang nhập hoặc đang tạo nội dung. Khi không có khối nào có cột tên VĐV/đội, hoặc có sheet bị bỏ qua vì không có dòng tiêu đề, nút MUST được nhấn mạnh (nút đặc thay vì nút viền).

#### Scenario: Mở popup sau khi đọc file
- **WHEN** người dùng chọn file xlsx và việc đọc xong
- **THEN** màn hiện nút `Ghép cột` đang bật
- **AND** bấm nút mở bottom sheet liệt kê mọi cột của dòng tiêu đề, mỗi cột có tên cột, một giá trị mẫu và nhãn trường đang ghép

#### Scenario: AI đang đọc bố cục
- **WHEN** trạng thái bố cục là đang hỏi AI
- **THEN** nút `Ghép cột` bị tắt và không mở popup

#### Scenario: Sheet không có dòng tiêu đề
- **WHEN** một sheet không dò được dòng tiêu đề và bị liệt kê trong thông báo "Bỏ qua sheet"
- **THEN** popup vẫn liệt kê sheet đó để người dùng chọn hàng tiêu đề và ghép cột thủ công

### Requirement: Ghép trường với cột, mỗi trường một cột
Popup MUST cho chạm một dòng cột để hiện hàng chip các trường: Tên, SĐT, Email, Tên VĐV 2, SĐT VĐV 2, Email VĐV 2, Đội, Mã cặp, Nội dung, Đã đóng phí, ELO, Ghi chú. Các chip VĐV 2 MUST chỉ hiện khi nội dung đích là đôi. Gán một trường cho cột mới MUST gỡ trường đó khỏi cột cũ và cột cũ MUST trở về `Ghi chú`. Chip `Ghi chú` MUST gỡ cột khỏi mọi trường. Cột không ghép MUST hiện nhãn `Ghi chú` viền đứt và khi đọc dòng MUST được đưa vào ghi chú dạng `Tên cột: giá trị` nối bằng ` · `.

#### Scenario: Gán lại một trường sang cột khác
- **WHEN** cột B đang là Tên và người dùng chọn chip Tên cho cột C
- **THEN** cột C là Tên và cột B hiện `Ghi chú`
- **AND** các dòng đọc lại có `player1Name` lấy từ cột C và ghi chú chứa `Tên cột B: giá trị`

#### Scenario: Chạm lại chip đang chọn hoặc chọn Ghi chú
- **WHEN** người dùng chọn chip `Ghi chú` cho cột đang là SĐT
- **THEN** mapping không còn trường SĐT
- **AND** dòng đọc lại không có `player1Phone` và giá trị cột đó nằm trong ghi chú

#### Scenario: Chip VĐV 2 khi nội dung đơn
- **WHEN** mọi dòng thuộc nội dung đơn
- **THEN** hàng chip không có Tên VĐV 2, SĐT VĐV 2, Email VĐV 2

### Requirement: Cột STT và cột nhạy cảm bị khóa
Cột có tiêu đề là số thứ tự (`STT`, `TT`, `Số TT`, `Số thứ tự`, `No`, `#`) MUST bị khóa và hiện nhãn `STT`. Cột có tiêu đề thuộc nhóm nhạy cảm (ngày/năm sinh, CCCD/CMND, hộ chiếu, địa chỉ, mã số thuế...) MUST bị khóa, hiện ổ khóa và chữ "Không lưu", và giá trị của cột MUST NOT được lưu kể cả vào ghi chú. Cột khóa MUST NOT chạm được. Một cột có tiêu đề chứa từ nhạy cảm nhưng đang được ghép vào trường (ví dụ `Địa chỉ email` ghép Email) MUST NOT bị khóa.

#### Scenario: Cột ngày sinh
- **WHEN** file có cột `Ngày sinh`
- **THEN** popup hiện dòng đó với ổ khóa, không mở được hàng chip
- **AND** ghi chú của mọi dòng không chứa giá trị ngày sinh

#### Scenario: Cột STT
- **WHEN** file có cột `STT`
- **THEN** dòng đó bị khóa với nhãn `STT` và không vào ghi chú

#### Scenario: Địa chỉ email vẫn ghép được
- **WHEN** tiêu đề là `Địa chỉ email` và luật đã ghép cột đó vào Email
- **THEN** dòng đó không bị khóa và đổi được trường

### Requirement: Cách ghép cặp và ký tự ngăn cách
Popup MUST có một dòng chọn cách ghép cặp: Đánh đơn, Mỗi VĐV một cột, Hai VĐV một ô, 2 dòng liền nhau là 1 cặp, chỉ hiện khi nội dung đích là đôi. Khi chọn "Hai VĐV một ô", popup MUST hiện ô nhập ký tự ngăn cách. Cách ghép người dùng chọn MUST thắng cách luật tự suy, kể cả "Đánh đơn" (xóa VĐV 2 của dòng đôi). Gán một cột VĐV 2 khi đang chọn "Đánh đơn" MUST tự chuyển sang "Mỗi VĐV một cột".

#### Scenario: Hai dòng liền nhau là một cặp
- **WHEN** người dùng chọn "2 dòng liền nhau là 1 cặp" cho file đôi mà mỗi VĐV một dòng
- **THEN** số dòng đọc được bằng một nửa số dòng VĐV (làm tròn lên), VĐV ở dòng dưới thành VĐV 2

#### Scenario: Người dùng chọn Đánh đơn
- **WHEN** người dùng chọn "Đánh đơn" cho nội dung đôi có cột Tên VĐV 2
- **THEN** các dòng đọc lại không có VĐV 2 dù mapping còn cột Tên VĐV 2

#### Scenario: Có cột mã cặp
- **WHEN** mapping có cột Mã cặp có giá trị và người dùng chọn "2 dòng liền nhau là 1 cặp"
- **THEN** việc ghép theo mã cặp được ưu tiên như hiện nay (cách chọn được lưu nhưng không đổi kết quả)

### Requirement: Hàng tiêu đề đổi được
Popup MUST có ô số "Hàng tiêu đề" (đánh số từ 1) nhận giá trị trong khoảng 1 tới số dòng của sheet trừ 1. Đổi hàng tiêu đề MUST đọc lại tên cột và mẫu từ hàng mới, dò lại ánh xạ bằng luật dò cột hiện có, giữ nguyên cách ghép cặp đã chọn, và đọc lại các dòng dữ liệu từ hàng ngay dưới. Khi hàng tiêu đề nằm trong một ô gộp ngang, popup MUST hiện cảnh báo lệch cột.

#### Scenario: Đổi hàng tiêu đề từ banner sang hàng thật
- **WHEN** file có banner gộp ngang ở dòng 1 và tiêu đề cột ở dòng 2, và người dùng đặt Hàng tiêu đề = 2
- **THEN** danh sách cột là các ô dòng 2 và mapping được dò lại từ chúng
- **AND** cảnh báo lệch cột biến mất

#### Scenario: Hàng tiêu đề nằm trong ô gộp ngang
- **WHEN** người dùng đặt Hàng tiêu đề = 1 mà dòng 1 là vùng gộp ngang
- **THEN** popup hiện cảnh báo lệch cột

#### Scenario: Giá trị ngoài khoảng
- **WHEN** người dùng nhập 0, chữ, hoặc số lớn hơn số dòng của sheet
- **THEN** giá trị được đưa về khoảng hợp lệ gần nhất, không ném lỗi và popup không đổi sang dữ liệu rỗng

### Requirement: Nút Xong chỉ bật khi đủ điều kiện
Chân popup MUST hiện số dòng đọc được và nút `Xong`. Khi mapping không có Tên VĐV 1, Đội và Email VĐV 1, chân MUST hiện chữ đỏ yêu cầu chọn cột Tên và nút `Xong` MUST bị tắt. Khi số dòng đọc được bằng 0, nút `Xong` MUST bị tắt.

#### Scenario: Thiếu cột nhận diện
- **WHEN** không cột nào là Tên, Đội hoặc Email
- **THEN** chân popup hiện chữ đỏ, dòng cột đầu tiên chưa ghép có viền đỏ gợi ý và `Xong` bị tắt

#### Scenario: Có đội nhưng không có tên VĐV
- **WHEN** chỉ có cột Đội được ghép
- **THEN** `Xong` bật vì Đội đủ để nhận diện

### Requirement: Áp dụng ghép cột vào danh sách và preview
Khi bấm `Xong`, màn Nhập Excel MUST thay khối đã sửa trong danh sách khối đang dùng, ghép lại mọi dòng, tính lại kiểm tra cục bộ và nhóm theo nội dung, rồi chạy lại preview server đúng một lần. Lựa chọn tài khoản của người dùng trước đó MUST được đặt lại về tự động vì chỉ số dòng đã đổi. Nội dung đã tạo trong phiên nhập MUST được giữ. Câu trả lời AI đang bay MUST bị bỏ. Đóng popup không bấm `Xong` MUST NOT đổi gì.

#### Scenario: Sửa ghép cột thành công
- **WHEN** người dùng đổi cột Tên rồi bấm `Xong`
- **THEN** danh sách VĐV hiện tên từ cột mới và preview được gọi với payload mới
- **AND** nút nhập chỉ bật sau khi preview của payload mới trả về

#### Scenario: Đóng popup không bấm Xong
- **WHEN** người dùng đổi vài cột rồi đóng popup bằng nút đóng hoặc vuốt xuống
- **THEN** danh sách và preview giữ nguyên, không có lần gọi preview mới

#### Scenario: Preview thất bại sau Xong
- **WHEN** preview lỗi mạng hoặc quá 30 giây
- **THEN** màn hiện lỗi và nút `Thử lại`, nút nhập bị tắt, và việc ghép cột đã sửa vẫn được giữ

#### Scenario: Ghép cột ra không có dòng nào
- **WHEN** người dùng không thể bấm `Xong` vì mapping thiếu cột nhận diện
- **THEN** danh sách hiện tại không bị thay bằng danh sách rỗng

### Requirement: Mọi chuỗi popup có hai ngôn ngữ
Mọi chuỗi mới của popup MUST có key cùng tên trong `app_vi.arb` và `app_en.arb`, tiền tố `rosterMap`, và code sinh `app_localizations*.dart` MUST được sinh bằng `flutter gen-l10n`. Popup MUST dùng token màu của `AppTheme`, không hardcode màu từng màn, vùng chạm MUST ≥ 44 dp.

#### Scenario: Chế độ tối và tiếng Anh
- **WHEN** máy ở chế độ tối và ngôn ngữ tiếng Anh
- **THEN** popup hiện chuỗi tiếng Anh, màu theo theme tối, không tràn chữ ở màn rộng 360 dp
