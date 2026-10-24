## MODIFIED Requirements

### Requirement: Thao tác ghi làm mới nguồn trận quản lý
Sau khi ghi lịch, đổi chỗ, xếp hàng loạt, áp bản nháp xếp tự động, xếp nối tiếp nhiều trận từ một ô, xếp hàng loạt từ khay chờ, đổi thời lượng, đổi sân, thao tác bracket hoặc cập nhật trận từ điều khiển trận, App SHALL tải lại danh sách trận quản lý của giải đó. Sau mỗi thao tác ghi thành công, nếu phát hiện VĐV bị xếp trùng giờ hai nơi, App SHALL hiện cảnh báo danh sách xung đột (trận, sân, giờ, VĐV trùng).

#### Scenario: Thả trận vào ô lịch
- WHEN BTC thả một trận vào ô sân và giờ trong lưới, và Backend lưu thành công
- THEN lưới tải lại từ nguồn quản lý và trận nằm đúng sân, đúng giờ Backend trả về

#### Scenario: Ghi lịch thất bại
- WHEN Backend từ chối thao tác ghi lịch
- THEN App báo lỗi như hiện nay và lưới tải lại từ nguồn quản lý, không giữ vị trí tạm của trận

#### Scenario: VĐV bị xếp trùng giờ
- WHEN một VĐV có hai trận cùng giờ trên hai sân sau thao tác ghi
- THEN App hiện cảnh báo liệt kê hai trận, hai sân và tên VĐV trùng

## ADDED Requirements

### Requirement: Xếp nhiều trận nối tiếp từ một ô
Bấm vào một ô trống của lưới SHALL mở sheet chọn nhiều trận chưa xếp cùng lúc: từng trận có ô thời lượng (15–240 phút, bộ 5, validate tại chỗ), lọc theo vòng, tìm theo tên VĐV/đội, chọn hiện tại đang thấy; nút "Xếp N trận" xếp nối tiếp bắt đầu từ ô được chọn (mỗi trận bắt đầu sau khi trận trước kết thúc) bằng cách ghi tuần tự lịch từng trận; lỗi giữa chừng dừng và báo "đã xếp i/N".

#### Scenario: Xếp 3 trận nối tiếp
- WHEN BTC chọn 3 trận từ ô 08:00 sân 2, thời lượng 30/45/30 phút
- THEN ba trận được xếp 08:00, 08:30, 09:15 trên sân 2

#### Scenario: Thời lượng không hợp lệ
- WHEN BTC nhập 33 phút cho một trận
- THEN sheet báo lỗi ở dòng đó và không cho xác nhận tới khi sửa

### Requirement: Xếp hàng loạt từ khay chờ có sân đích và khung giờ
Khay "chưa xếp" SHALL cho chọn nhiều trận (checkbox + chọn tất cả), chọn sân đích và khung giờ bắt đầu, rồi xếp toàn bộ chọn theo thứ tự nối tiếp trên sân đích; ghi tuần tự với tiến độ, có thể huỷ giữa chừng.

#### Scenario: Dồn 5 trận lên sân 4 lúc 13:00
- WHEN BTC chọn 5 trận trong khay, chọn sân 4 và 13:00
- THEN 5 trận được xếp nối tiếp trên sân 4 từ 13:00

### Requirement: Cài đặt khung giờ sân
Màn lưới SHALL mở được sheet cài đặt khung giờ: giờ mở cửa và đóng cửa sân trong ngày, bước ô thời gian 5/10/15/30/60 phút; lưu vào cấu hình giải qua đúng route Web dùng; lưới vẽ lại theo bước mới.

#### Scenario: Đổi bước ô sang 10 phút
- WHEN BTC đặt bước 10 phút và lưu
- THEN lưới vẽ các ô 10 phút và bước được giữ sau khi tải lại

### Requirement: AI xếp lịch bằng lệnh chữ
Màn lưới SHALL có sheet "AI xếp lịch": ô nhập lệnh chữ tự nhiên (ví dụ "vòng 1 từ 8h, 1 set 15 phút, cách nhau 5 phút trên sân 1-4"), gửi `POST /ai/tournaments/:id/schedule-preview` để xem kế hoạch, hiển thị kế hoạch như bản nháp trên lưới rồi áp dụng tuần tự như xếp tự động hiện có. Khi route AI không khả dụng (404/đủ lỗi hạ tầng), App SHALL ẩn mục này mà không phá các chức năng còn lại.

#### Scenario: Xem trước rồi áp dụng
- WHEN BTC nhập lệnh và bấm "Xem trước"
- THEN App gọi schedule-preview, hiện bản nháp kế hoạch trên lưới với thanh "Áp dụng N trận / Huỷ"

#### Scenario: Route AI chưa có
- WHEN Backend trả 404 cho schedule-preview
- THEN App ẩn mục AI xếp lịch trong phiên màn hiện tại và mọi chức năng khác vẫn dùng được
