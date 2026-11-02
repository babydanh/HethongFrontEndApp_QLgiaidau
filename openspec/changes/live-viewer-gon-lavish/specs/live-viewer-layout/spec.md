## ADDED Requirements

### Requirement: Bảng điểm overlay đáy video cho người xem
Trang xem live của người xem SHALL vẽ bảng điểm kiểu overlay Web (hai hàng chồng, vạch xanh, ô điểm vát) ở đáy video, góc dưới trái, tên viết tắt IN HOA, và MUST tạm ẩn bảng điểm khi overlay H2H hoặc Sơ đồ đang hiện.

#### Scenario: Không có overlay H2H hay Sơ đồ
- **WHEN** người xem mở trận có bảng điểm bật và không có overlay khác
- **THEN** bảng điểm hiện ở góc dưới trái video, nút Quay lại/LIVE/Chia sẻ giữ nguyên trên video

#### Scenario: H2H đang hiện
- **WHEN** trọng tài bật overlay H2H
- **THEN** bảng điểm không hiện trong lúc đó

### Requirement: Popup Chi tiết trận gọn
Popup Chi tiết trận SHALL không hiển thị dòng hoặc khối chưa có dữ liệu (ELO, trọng tài, phạt/thẻ).

#### Scenario: Chưa có Elo, trọng tài, thẻ phạt
- **WHEN** mở popup của trận chưa có các dữ liệu đó
- **THEN** popup không có thẻ ELO và không có dòng "Chưa có"

### Requirement: Overlay H2H và Sơ đồ cùng tông Web
Overlay H2H và Sơ đồ trên video SHALL dùng tông navy + xanh #1E90FF như Web, và overlay H2H MUST NOT hiện chip ELO "Chưa có" khi bên đó chưa có điểm ELO.

#### Scenario: H2H đang hiện
- **WHEN** trọng tài bật overlay H2H cho trận chưa có điểm ELO
- **THEN** overlay hiện hai thẻ tên kèm vòng avatar, chữ "VS" ở giữa và không có chữ "Chưa có"

### Requirement: Avatar mỗi bên và chuyển động overlay
Popup Chi tiết trận và overlay H2H SHALL hiện đúng một avatar cho VĐV đơn hoặc đội và hai avatar chồng nhau cho cặp đôi; không có ảnh thì SHALL hiện chữ cái đầu của tên. Overlay trên video SHALL hiện và ẩn bằng chuyển động mờ dần (ẩn nhanh hơn hiện) và SHALL không chuyển động khi người dùng bật giảm chuyển động.

#### Scenario: Cặp đôi và tên một chữ
- **WHEN** một bên là cặp đôi, bên kia là VĐV đơn có tên `odi695` và chưa có ảnh
- **THEN** bên cặp đôi hiện hai avatar chồng nhau, bên đơn hiện một avatar chữ `O`

#### Scenario: Bật giảm chuyển động
- **WHEN** hệ điều hành bật giảm chuyển động và trọng tài bật overlay H2H
- **THEN** overlay hiện ngay, không có hiệu ứng trượt hay mờ dần

