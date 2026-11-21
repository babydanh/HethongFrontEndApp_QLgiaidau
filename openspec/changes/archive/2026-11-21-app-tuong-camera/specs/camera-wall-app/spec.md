## ADDED Requirements

### Requirement: Nút mở tường camera trên App
Tab Camera của BTC trong App SHALL có nút "Xem camera" chỉ hiện khi giải có ít nhất một camera. Bấm nút MUST mở màn tường camera toàn màn hình với lưới mặc định 2×2.

#### Scenario: Giải chưa có camera
- **WHEN** `tournamentCamerasProvider` trả danh sách rỗng
- **THEN** nút "Xem camera" không hiện

#### Scenario: Mở tường camera
- **WHEN** giải có camera và BTC bấm "Xem camera"
- **THEN** màn tường camera mở với lưới 2×2

### Requirement: Lưới và chia trang
Tường camera SHALL cho chọn lưới 1×1, 2×2, 3×3, 4×4 và MUST hiện tối đa `n×n` camera một trang; nhiều camera hơn thì chia trang.

#### Scenario: Nhiều camera hơn số ô
- **WHEN** giải có 20 camera và BTC chọn lưới 4×4
- **THEN** trang 1 hiện 16 ô và chuyển sang trang 2 thì hiện 4 ô

#### Scenario: Chạm đúp phóng to
- **WHEN** BTC chạm đúp ô của một camera trong lưới 2×2
- **THEN** tường chuyển sang lưới 1×1 và hiện đúng camera đó

### Requirement: Trình phát và công tắc xem thử
Chỉ camera có trạng thái `LIVE`, có `playbackUrl` và công tắc xem thử đang bật SHALL mở trình phát. Tắt công tắc MUST ngắt trình phát trên máy BTC và MUST NOT gọi Backend.

#### Scenario: Camera chưa phát
- **WHEN** một camera có trạng thái `OFFLINE`
- **THEN** ô của camera đó không có `LiveVideoPlayer` và hiện huy hiệu trạng thái

#### Scenario: Tắt xem thử
- **WHEN** BTC tắt công tắc của một ô đang `LIVE`
- **THEN** ô không còn `LiveVideoPlayer` và không có yêu cầu nào gửi lên Backend

### Requirement: Dòng trận đang chiếu
Mỗi ô SHALL hiện mã trận và tên hai bên, không hiện tỉ số. Trận được chọn theo thứ tự: trận đang phát qua chính camera; trận `ONGOING` trên sân gắn với camera; trận `SCHEDULED` sớm nhất trên sân đó. Không có trận thì hiện "Chưa có trận".

#### Scenario: Camera đang phát một trận
- **WHEN** một camera là nguồn phát `live` của trận mã `CK01`
- **THEN** ô hiện `#CK01` cùng tên hai bên

#### Scenario: Camera chưa có trận
- **WHEN** camera chưa gắn sân và không phát trận nào
- **THEN** ô hiện "Chưa có trận"
