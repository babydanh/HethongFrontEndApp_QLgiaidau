# schedule-grid-match-cards Specification

## Purpose
Định nghĩa cách thẻ lịch thi đấu phân biệt hạng mục, trình bày tên hai đội và căn điểm số để người xem đọc đúng trận đang diễn ra hoặc đã hoàn tất trên màn hình nhỏ.

## Requirements

### Requirement: Màu thẻ phản ánh hạng mục đôi nam và đôi nữ
Thẻ lịch MUST xác định màu từ metadata loại trận và giới tính của hạng mục, không phụ thuộc tên hiển thị hay thứ tự trong giải. Hạng mục `DOUBLES` + `MALE` MUST màu xanh dương; `DOUBLES` + `FEMALE` MUST màu hồng; loại khác MUST giữ màu dự phòng hiện có.

#### Scenario: Metadata giữ màu khi tên hoặc thứ tự khác nhau
- **WHEN** hạng mục có `matchType` là `DOUBLES` và `genderRestriction` là `MALE` hoặc `FEMALE`, dù tên hiển thị khác hoặc thứ tự hạng mục đổi
- **THEN** hạng mục nam luôn xanh dương và hạng mục nữ luôn hồng

#### Scenario: Metadata thiếu hoặc không thuộc hai loại trên
- **WHEN** hạng mục không có metadata phù hợp, là đánh đơn, đánh đôi hỗn hợp hoặc không có hạng mục
- **THEN** thẻ không suy màu nam/nữ từ tên và vẫn dùng màu dự phòng hiện có nếu có hạng mục

### Requirement: Tên đội dài không đẩy lệch điểm số
Tên đội trong thẻ lịch đầy đủ MUST được giới hạn tối đa hai dòng và được rút gọn bằng dấu ba chấm khi vượt quá chỗ; điểm số MUST luôn tách khỏi tên đội và nằm ở cạnh phải của hàng.

#### Scenario: Tên đội dài có điểm theo set
- **WHEN** tên một đội dài hơn chỗ còn lại và trận có điểm theo set
- **THEN** tên được giới hạn hai dòng, không tràn khỏi thẻ, và điểm vẫn nằm ở cạnh phải

#### Scenario: Không có điểm theo set
- **WHEN** trận chưa có dữ liệu điểm theo set
- **THEN** thẻ không tạo cột điểm rỗng và tên đội vẫn nằm gọn trong hàng

### Requirement: Trạng thái chưa hoàn tất không bị trình bày như kết quả cuối
Thẻ lịch MUST NOT nhấn mạnh đội thắng hoặc trình bày trạng thái hoàn tất khi trận chưa thực sự hoàn tất; điểm trực tiếp có thể hiển thị riêng khi trận đang diễn ra.

#### Scenario: Trận đang diễn ra có điểm
- **WHEN** trạng thái trận đang diễn ra và có điểm theo set
- **THEN** điểm hiện sát cạnh phải nhưng tên đội không được định dạng như đội thắng cuối trận

#### Scenario: Trận chưa bắt đầu không có điểm
- **WHEN** trận chưa bắt đầu và không có dữ liệu điểm
- **THEN** thẻ không hiện điểm cuối hoặc dấu hiệu trận đã kết thúc
