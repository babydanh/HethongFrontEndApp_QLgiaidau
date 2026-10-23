# swiss-format-display Specification

## Purpose
App nhận diện thể thức Thụy Sĩ và hiển thị nhãn đúng ở mọi nơi chọn hoặc hiển thị thể thức.

## Requirements

### Requirement: Nhận diện thể thức Thụy Sĩ
App SHALL coi `swiss` (chữ thường ở `bracketType`) và `SWISS` (chữ hoa ở `stageType`) là thể thức hợp lệ ở mọi nơi chọn, hiển thị hoặc suy nhãn thể thức, và SHALL hiển thị `Thụy Sĩ` (vi) hoặc `Swiss` (en), không rơi về nhãn hay giao diện loại trực tiếp.

#### Scenario: Nhãn thể thức
- **WHEN** một giải hoặc nội dung có `bracketType = 'swiss'` hiện ở thẻ giải, banner, màn đăng ký hoặc màn quản lý nội dung
- **THEN** nhãn là `Thụy Sĩ` (vi) hoặc `Swiss` (en)

#### Scenario: Stage SWISS không phải loại trực tiếp
- **WHEN** một trận có `stageType = 'SWISS'` đi qua `isKnockoutMatch`, `isGroupStageMatch` hoặc `formatRound`
- **THEN** không được coi là loại trực tiếp; nhãn vòng là `Vòng N` / `Round N`, không có "Chung kết" hay "Bán kết"

#### Scenario: Thể thức lạ
- **WHEN** `bracketType` là giá trị App không biết
- **THEN** hiển thị như trước (không rơi vào giao diện Swiss)

### Requirement: Bảng xếp hạng Thụy Sĩ
App SHALL hiển thị bảng xếp hạng phẳng cho nội dung Swiss theo đúng thứ tự `rank` và giá trị Backend trả (không tự tính lại), với cột Buchholz/Cut-1/Sonneborn-Berger/Hiệu số/Số thắng chỉ khi tiebreak tương ứng đang bật trong `roundConfig.swiss.tiebreakOrder`.

#### Scenario: Hiển thị bảng
- **WHEN** người xem mở tab `Xếp hạng` của nội dung Swiss đã có kết quả
- **THEN** bảng có cột Hạng, Đội, Trận, Thắng, Hòa, Thua, Điểm và các cột tiebreak đang bật, sắp theo `rank`; trên màn hẹp bảng cuộn ngang, không tràn layout

#### Scenario: Endpoint trả dòng có rank
- **WHEN** các dòng từ `GET /tournaments/:id/standings` có `rank`
- **THEN** App giữ nguyên thứ tự và giá trị đó, không chạy bản tự tính từ danh sách trận

#### Scenario: Chưa có kết quả
- **WHEN** endpoint trả danh sách rỗng
- **THEN** hiện dòng `Chưa có kết quả`, không báo lỗi

#### Scenario: Lỗi tải
- **WHEN** gọi standings thất bại
- **THEN** hiện thông báo ngắn và cho kéo làm mới; tab `Lịch thi đấu` vẫn dùng được

### Requirement: Lịch trận theo vòng và nhãn BYE
App SHALL hiển thị trận của nội dung Swiss theo vòng với bộ chọn vòng bằng chữ, mặc định vòng hiện tại, và SHALL hiển thị trận BYE bằng tên người nhận kèm nhãn `BYE`.

#### Scenario: Chọn vòng
- **WHEN** người xem chọn `Vòng 2`
- **THEN** chỉ trận có `round = 2` hiện ra

#### Scenario: Trận BYE
- **WHEN** vòng có trận `isBye = true`
- **THEN** dòng trận hiện tên người nhận và `BYE`, không hiện đối thủ trống

#### Scenario: Không có tab bảng chéo
- **WHEN** nội dung là Swiss
- **THEN** màn chỉ có hai tab `Xếp hạng` và `Lịch thi đấu`

### Requirement: Cập nhật theo nhịp poll
App SHALL cập nhật stage Swiss, danh sách trận và xếp hạng theo nhịp poll hiện có (≤ 20 giây) để thấy vòng mới do BTC tạo, và SHALL không yêu cầu socket.

#### Scenario: Vòng mới xuất hiện
- **WHEN** BTC tạo vòng 3 trên thiết bị khác
- **THEN** trong vòng 20 giây lịch trận hiện trận vòng 3 và bảng xếp hạng được tải lại

#### Scenario: Mất mạng
- **WHEN** một lượt poll thất bại
- **THEN** giữ dữ liệu đã có và không hiện lỗi chặn màn hình
