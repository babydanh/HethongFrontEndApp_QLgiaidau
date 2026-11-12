## ADDED Requirements

### Requirement: Nút Bấm điểm trên thẻ trận Social
Thẻ trận trong tab Trận đấu của buổi Social SHALL có nút "Bấm điểm" khi trận chưa COMPLETED và người dùng đã đăng nhập; nút SHALL mở thẳng bảng bấm điểm live và SHALL cao tối thiểu 44.

#### Scenario: Trận chưa xong, đã đăng nhập
- **WHEN** thẻ trận SCHEDULED hoặc ONGOING hiện cho người đã đăng nhập
- **THEN** thẻ có nút "Bấm điểm" và bấm nút mở bảng bấm điểm live, không qua hộp thoại kết quả

#### Scenario: Trận đã hoàn thành hoặc chưa đăng nhập
- **WHEN** trận COMPLETED, hoặc người xem chưa đăng nhập
- **THEN** thẻ không có nút "Bấm điểm"

#### Scenario: Chạm thẻ
- **WHEN** người dùng chạm vào thẻ trận
- **THEN** hộp thoại kết quả vẫn mở như cũ

### Requirement: Mở bảng điểm sau khi tạo trận
Sau khi tạo trận, hộp thoại kết quả SHALL hiện "Mở bảng điểm" theo cùng điều kiện với nút trên thẻ.

#### Scenario: Trận vừa tạo chưa xong
- **WHEN** host tạo trận xong và đã đăng nhập
- **THEN** hộp thoại kết quả có "Mở bảng điểm"; chọn thì mở bảng bấm điểm live của trận vừa tạo

#### Scenario: Trận vừa tạo đã hoàn thành
- **WHEN** trận vừa tạo có trạng thái COMPLETED
- **THEN** hộp thoại không có "Mở bảng điểm"
