## ADDED Requirements

### Requirement: Bảng điểm overlay góc trên trái video cho người xem
Trang xem live của người xem SHALL vẽ bảng điểm kiểu overlay Web (hai hàng chồng, vạch xanh, ô điểm vát) ở góc trên trái video như Web, tên viết tắt IN HOA, và MUST tạm ẩn bảng điểm khi overlay Sơ đồ phủ kín khung đang hiện.

#### Scenario: Không có overlay Sơ đồ
- **WHEN** người xem mở trận có bảng điểm bật và Sơ đồ không hiện
- **THEN** bảng điểm hiện ở góc trên trái video, cùng hàng với nút Quay lại và nằm ngay sau nút đó, không xuống hàng

#### Scenario: Sơ đồ đang hiện
- **WHEN** trọng tài bật overlay Sơ đồ
- **THEN** bảng điểm không hiện trong lúc đó

### Requirement: Popup Chi tiết trận gọn
Popup Chi tiết trận SHALL không hiển thị dòng hoặc khối chưa có dữ liệu (ELO, trọng tài, phạt/thẻ).

#### Scenario: Chưa có Elo, trọng tài, thẻ phạt
- **WHEN** mở popup của trận chưa có các dữ liệu đó
- **THEN** popup không có thẻ ELO và không có dòng "Chưa có"
