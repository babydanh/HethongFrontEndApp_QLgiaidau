## ADDED Requirements

### Requirement: Bảng điểm overlay dưới video cho người xem
Trang xem live của người xem SHALL vẽ bảng điểm kiểu overlay Web (hai hàng chồng, vạch xanh, ô điểm vát) ở phía dưới video, và MUST tạm ẩn bảng điểm khi overlay H2H hoặc Sơ đồ đang hiện.

#### Scenario: Không có overlay H2H hay Sơ đồ
- **WHEN** người xem mở trận có bảng điểm bật và không có overlay khác
- **THEN** bảng điểm hiện ở góc dưới trái video, không nằm dưới nút Quay lại

#### Scenario: H2H đang hiện
- **WHEN** trọng tài bật overlay H2H
- **THEN** bảng điểm không hiện trong lúc đó

### Requirement: Popup Chi tiết trận gọn
Popup Chi tiết trận SHALL không hiển thị dòng hoặc khối chưa có dữ liệu (ELO, trọng tài, phạt/thẻ).

#### Scenario: Chưa có Elo, trọng tài, thẻ phạt
- **WHEN** mở popup của trận chưa có các dữ liệu đó
- **THEN** popup không có thẻ ELO và không có dòng "Chưa có"
