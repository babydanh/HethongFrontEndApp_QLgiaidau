## ADDED Requirements

### Requirement: Tab Đang diễn ra là bảng trận như Web
Tab "Đang diễn ra" của màn chi tiết giải SHALL hiện bảng trận gồm chip lọc, ô tìm, menu "Tới vòng", hộp "Đang đấu" trên cùng và mỗi vòng một hộp. Tab SHALL hiện khi giải đang thi đấu hoặc có trận đang đấu.

#### Scenario: Giải đang thi đấu chưa có trận live
- **WHEN** giải ở trạng thái đang thi đấu và không có trận nào đang đấu
- **THEN** tab "Đang diễn ra" vẫn hiện và liệt kê các vòng với trận sắp tới

#### Scenario: Lọc theo chip
- **WHEN** người dùng chọn chip "Đã xong"
- **THEN** chỉ các hàng trận đã xong còn hiển thị và hộp "Đang đấu" bị ẩn

### Requirement: Hàng trận có avatar, logo và điểm ngang hàng
Mỗi hàng trận SHALL hiện hai bên xếp dọc; đội có tên riêng hiện logo đội và một dòng tên đội, còn lại mỗi VĐV một dòng gồm avatar và tên viết tắt; điểm của từng bên nằm ngang hàng với bên đó.

#### Scenario: Đôi không tên đội
- **WHEN** một bên có hai VĐV và không có tên đội
- **THEN** bên đó hiện hai dòng, mỗi dòng một avatar và một tên

### Requirement: Mã trận theo vai
Cột đầu mỗi hàng SHALL hiện mã trận `#<mã>` cho Ban tổ chức và số thứ tự trong hộp cho người xem.

#### Scenario: Người xem
- **WHEN** người xem mở tab và trận có mã `V1602`
- **THEN** hàng đó hiện số thứ tự, không hiện `#V1602`

#### Scenario: Ban tổ chức
- **WHEN** Ban tổ chức mở cùng tab
- **THEN** hàng đó hiện `#V1602`

### Requirement: Tab Kết quả chỉ còn bục vinh danh
Tab "Kết quả" SHALL chỉ hiện bục vinh danh và một nút icon chia sẻ; bảng trận SHALL không còn ở tab này.

#### Scenario: Chưa có kết quả
- **WHEN** giải chưa công bố kết quả
- **THEN** tab hiện khung "Chưa có kết quả chính thức" và không hiện bảng trận
