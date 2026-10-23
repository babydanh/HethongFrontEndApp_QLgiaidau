## ADDED Requirements

### Requirement: Mở màn ghép cặp vòng kế
App SHALL hiện nút `Ghép cặp vòng N` cho BTC chỉ khi vòng hiện tại đã xong và còn vòng chưa ghép, và SHALL tải bản đề xuất bằng `POST /tournaments/:id/swiss/preview`.

#### Scenario: Vòng xong, còn vòng
- **WHEN** mọi trận không-BYE của vòng 2 là `COMPLETED` và `totalRounds = 5`
- **THEN** nút `Ghép cặp vòng 3` hiện và mở màn ghép cặp với bản đề xuất của máy

#### Scenario: Vòng chưa xong
- **WHEN** còn một trận không-BYE của vòng hiện tại chưa `COMPLETED`
- **THEN** không có nút; hiện dòng chữ `Vòng 2 đang đấu`

#### Scenario: Đủ số vòng
- **WHEN** vòng hiện tại bằng `totalRounds` và đã xong
- **THEN** không có nút; hiện `Đã đủ 5 vòng`

#### Scenario: Preview thất bại
- **WHEN** preview trả lỗi
- **THEN** hiện thông báo theo mã lỗi (ví dụ `SWISS_ROUND_INCOMPLETE`) và nút thử lại, không hiện bản ghép rỗng

### Requirement: Chỉnh ghép cặp bằng kéo thả hoặc bảng chọn
App SHALL cho BTC hoán đổi người giữa hai ô, chuyển người sang "Chưa ghép", "Nghỉ vòng này" hoặc dòng BYE bằng nhấn giữ và kéo, và SHALL cung cấp đường thay thế không cần kéo (chạm tên rồi chọn "Đổi với..." / "Chuyển tới..." trong bảng chọn) dùng được với trình đọc màn hình.

#### Scenario: Hoán đổi bằng kéo
- **WHEN** BTC nhấn giữ An (bàn 1) rồi thả lên Chi (bàn 4)
- **THEN** giao diện đổi chỗ ngay, rồi gọi `validate` (debounce) và hiện cảnh báo nếu có

#### Scenario: Hoán đổi bằng bảng chọn
- **WHEN** BTC chạm An, chọn "Đổi với..." rồi chọn Chi
- **THEN** kết quả giống kéo thả

#### Scenario: Thả về ô cũ
- **WHEN** BTC nhấc rồi thả lại đúng ô cũ
- **THEN** không gọi `validate`, không đổi trạng thái

#### Scenario: Bỏ ghép một người
- **WHEN** BTC thả Dũng lên "Chưa ghép"
- **THEN** ô của Dũng trống, nút Xác nhận tắt và hiện "Còn 2 đội chưa có chỗ"

### Requirement: Cảnh báo và kiểm tra hợp lệ
App SHALL hiển thị cảnh báo `REMATCH`, `SECOND_BYE`, `SCORE_GAP` bằng dòng chữ cạnh dòng bị ảnh hưởng (không chỉ bằng màu) và SHALL gọi `POST /tournaments/:id/swiss/validate` sau mỗi thay đổi với debounce 250 ms, chỉ áp kết quả của lượt gọi mới nhất.

#### Scenario: Cặp đã gặp
- **WHEN** nháp ghép hai đội đã gặp ở vòng 2
- **THEN** dòng của cặp có chữ `Đã gặp ở vòng 2`

#### Scenario: Gọi validate dồn
- **WHEN** BTC thả ba lần trong 400 ms
- **THEN** chỉ kết quả của lượt cuối được áp; kết quả lượt cũ về muộn bị bỏ

#### Scenario: Lỗi cứng
- **WHEN** validate trả `valid = false` với `MISSING_PARTICIPANT`
- **THEN** nút Xác nhận tắt và hiện lỗi ngắn theo mã

### Requirement: Xác nhận vòng
App SHALL chỉ bật nút Xác nhận khi mọi đội đã có chỗ (cặp đủ hai người, BYE hoặc nghỉ vòng) và `validate` hợp lệ, SHALL gửi `confirmWarnings: true` chỉ khi BTC bấm "Xác nhận dù có cảnh báo", và SHALL làm mới sơ đồ sau khi tạo vòng.

#### Scenario: Xác nhận không cảnh báo
- **WHEN** BTC bấm `Xác nhận vòng 3` với nháp hợp lệ, không cảnh báo
- **THEN** gọi `POST .../swiss/next-round`, đóng màn, hiện thông báo `Đã tạo vòng 3` và lịch trận có vòng 3

#### Scenario: Có cảnh báo
- **WHEN** nháp còn cảnh báo
- **THEN** nút là `Xác nhận dù có cảnh báo`; chỉ khi bấm nút này mới gửi `confirmWarnings: true`

#### Scenario: Bấm đúp
- **WHEN** BTC bấm Xác nhận hai lần liên tiếp
- **THEN** chỉ một request được gửi (nút tắt khi đang gửi)

#### Scenario: Người khác vừa tạo vòng
- **WHEN** Backend trả 409 `SWISS_ROUND_EXISTS`
- **THEN** tải lại preview, hiện `Vòng này vừa được tạo. Đã tải lại bản ghép cặp` và bỏ nháp cũ

#### Scenario: Mạng lỗi
- **WHEN** request next-round thất bại do mạng
- **THEN** giữ nguyên nháp BTC đã chỉnh, hiện lỗi ngắn và cho gửi lại

### Requirement: Hoàn tác vòng mới nhất
App SHALL hiện nút `Hoàn tác vòng N` khi vòng mới nhất (N ≥ 2) chưa có trận không-BYE nào khác `SCHEDULED`, và SHALL gọi `POST .../swiss/rounds/:round/undo` sau khi BTC xác nhận.

#### Scenario: Hoàn tác thành công
- **WHEN** vòng 3 vừa tạo, chưa trận nào bắt đầu, BTC xác nhận hoàn tác
- **THEN** vòng 3 biến mất khỏi lịch trận, nút `Ghép cặp vòng 3` hiện lại, thông báo `Đã hoàn tác vòng 3`

#### Scenario: Đã có trận bắt đầu
- **WHEN** một trận của vòng mới nhất đang đấu
- **THEN** không hiện nút; nếu Backend vẫn trả 409 `SWISS_ROUND_STARTED` thì hiện lỗi theo mã

### Requirement: Giao diện phẳng, ít icon
Màn ghép cặp và các view Swiss SHALL dùng một mặt phẳng không có khung lồng khung (không `Card` trong `Card`, không viền bo quanh từng bàn) và SHALL dùng tối đa một loại icon (tay nắm kéo); nút và cảnh báo khác dùng chữ.

#### Scenario: Cấu trúc giao diện
- **WHEN** màn hiển thị 12 cặp
- **THEN** mỗi cặp là một hàng chữ ngăn bằng `Divider`; không widget nào có cả viền và bo góc bao quanh một hàng cặp

#### Scenario: Màn hẹp và màn rộng
- **WHEN** chiều rộng < 600 dp
- **THEN** bố cục một cột, nút Xác nhận cố định đáy trong `SafeArea`, không `RenderFlex overflow`; khi ≥ 600 dp có hai cột

#### Scenario: Giảm chuyển động
- **WHEN** `MediaQuery.disableAnimations` là true
- **THEN** không có hiệu ứng chuyển động khi hoán đổi hoặc mở màn
