## ADDED Requirements

### Requirement: Overlay trên video là kính mờ, nhỏ gọn theo kích thước video
Khung H2H, sơ đồ giải và bảng điểm phủ trên video trực tiếp SHALL co theo bề rộng video, dùng nền navy bán trong suốt có làm mờ hậu cảnh, và không làm mờ chữ, avatar, viền hay nút đóng.

#### Scenario: H2H trên video rộng 400dp
- **WHEN** video rộng 400dp và overlay H2H đang hiện
- **THEN** khung H2H rộng khoảng 50% bề rộng video (tỉ lệ thuận, nằm trong khung hình thật), canh giữa theo chiều ngang, nằm sát đáy video phía trên thanh điều khiển, và không có `Opacity` < 1 bọc khung

#### Scenario: Video hẹp hơn
- **WHEN** video chỉ rộng 280dp
- **THEN** chiều cao khung H2H nhỏ hơn bản 400dp theo tỉ lệ co và không tràn

#### Scenario: Nút đóng
- **WHEN** overlay H2H hoặc sơ đồ có nút đóng
- **THEN** chấm tròn nhìn thấy rộng tối thiểu 24dp, vùng chạm tối thiểu 40dp, nút không che nhãn vòng đấu

#### Scenario: Xem ngang có tai thỏ camera
- **WHEN** điện thoại ở landscape fullscreen và có vùng không an toàn (tai thỏ) ở một bên
- **THEN** hình video 16:9 thấy trọn (không cắt, cao hết màn hình), nằm sát mép trong của tai thỏ, phần đen dư dồn về phía xa camera; không có tai thỏ thì hình canh giữa; overlay H2H/sơ đồ/bảng điểm nằm trong hình đó
