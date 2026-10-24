# organizer-schedule-workspace Specification

## Purpose
Không gian xếp lịch của ban tổ chức (BTC) trên App: màn Vận hành và lịch toàn màn hình phải thấy đủ trận của giải mình quản lý, kể cả khi giải chưa công khai, và lưới lịch phải luôn dùng được để xếp trận.

## Requirements

### Requirement: Màn quản lý lấy trận từ nguồn quản lý
Màn Vận hành, lịch toàn màn hình và phần camera trong quản lý giải SHALL lấy danh sách trận từ route quản lý có đăng nhập `GET /tournaments/:id/manage/matches`, lọc theo nội dung đang chọn. Các màn này MUST NOT lấy trận quản lý từ nguồn công khai `GET /matches?publicOnly=true`. Màn công khai MUST giữ nguồn công khai.

#### Scenario: BTC mở lịch của giải đang nháp
- **WHEN** BTC có quyền quản lý mở màn Vận hành của một giải đang `DRAFT` hoặc riêng tư, và nội dung đang chọn đã có trận
- **THEN** lưới lịch hiện đủ các trận của nội dung đó, giống số trận trên trang quản lý Web

#### Scenario: Giải có nhiều trang trận
- **WHEN** route quản lý trả `meta.hasMore = true` kèm `nextCursor`
- **THEN** App tiếp tục tải theo `nextCursor` cho tới khi hết và hiện đủ tất cả trận

#### Scenario: Người dùng không có quyền quản lý
- **WHEN** route quản lý trả 403
- **THEN** màn Vận hành hiện trạng thái lỗi có nút thử lại, không hiện như "chưa có trận"

#### Scenario: Thiếu mạng hoặc lỗi máy chủ khi chưa có dữ liệu
- **WHEN** lần tải đầu thất bại do mất mạng hoặc lỗi 5xx và chưa có dữ liệu đã lưu
- **THEN** màn hiện trạng thái lỗi có nút thử lại

#### Scenario: Màn công khai không đổi nguồn
- **WHEN** người xem mở bracket công khai hoặc bảng chéo của một giải
- **THEN** App vẫn gọi nguồn công khai với `publicOnly=true`, không gọi route quản lý

### Requirement: Thao tác ghi làm mới nguồn trận quản lý
Sau khi ghi lịch, đổi chỗ, xếp hàng loạt, áp bản nháp xếp tự động, đổi thời lượng, đổi sân, thao tác bracket hoặc cập nhật trận từ điều khiển trận, App SHALL tải lại danh sách trận quản lý của giải đó.

#### Scenario: Thả trận vào ô lịch
- **WHEN** BTC thả một trận vào ô sân và giờ trong lưới, và Backend lưu thành công
- **THEN** lưới tải lại từ nguồn quản lý và trận nằm đúng sân, đúng giờ Backend trả về

#### Scenario: Ghi lịch thất bại
- **WHEN** Backend từ chối thao tác ghi lịch
- **THEN** App báo lỗi như hiện nay và lưới tải lại từ nguồn quản lý, không giữ vị trí tạm của trận

### Requirement: Lưới lịch luôn dùng được ở chế độ lưới
Ở chế độ lưới, màn Vận hành SHALL hiện lưới lịch theo sân, ô chọn nội dung và các nút thao tác của lưới, kể cả khi nội dung đang chọn có 0 trận hoặc bộ lọc làm danh sách hiển thị rỗng.

#### Scenario: Nội dung chưa có trận
- **WHEN** BTC mở tab Quản lý ở chế độ lưới và nội dung đang chọn có 0 trận
- **THEN** lưới theo sân vẫn hiện, ô chọn nội dung vẫn đổi được sang nội dung khác, và không có thông báo che mất lưới

#### Scenario: Giải chưa có sân
- **WHEN** nội dung có 0 trận và giải chưa cấu hình sân
- **THEN** lưới hiện thông báo chưa có sân như hiện nay, ô chọn nội dung vẫn còn

#### Scenario: Có trận và có sân
- **WHEN** nội dung có trận đã xếp và giải có sân
- **THEN** lưới hiện các trận đã xếp trên đúng sân và giờ, trận chưa xếp nằm ở khay chờ

### Requirement: Chuyển sang lưới đặt bộ lọc về tất cả
Khi người dùng bấm chuyển từ dạng danh sách sang dạng lưới, App SHALL đặt bộ lọc trận về "Tất cả". Dạng danh sách MUST giữ hành vi bộ lọc hiện có.

#### Scenario: Đang lọc trận đang đấu rồi chuyển sang lưới
- **WHEN** người dùng đang ở dạng danh sách với bộ lọc "Đang đấu" và bấm nút chuyển sang lưới
- **THEN** lưới hiện mọi trận của nội dung, không chỉ trận đang đấu

#### Scenario: Chuyển ngược về danh sách
- **WHEN** người dùng ở dạng lưới bấm chuyển về dạng danh sách
- **THEN** danh sách giữ bộ lọc hiện tại, không tự đổi bộ lọc
