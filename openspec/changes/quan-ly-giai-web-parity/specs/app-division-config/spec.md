## ADDED Requirements

### Requirement: Sheet hạng mục đầy đủ cho tạo và sửa
Màn quản lý SHALL mở một sheet hạng mục duy nhất dùng cho cả tạo và sửa, chứa đủ các phần như Web `CreateDivisionModal`: nhận dạng (tên, loại đơn/đôi/đôi nam nữ), thể thức, переключ luật chuẩn/Lite, giới hạn (sức chứa, ELO, lệ phí riêng), luật theo môn, số lượt vòng tròn, cấu hình vòng bảng + playoff, cấu hình Swiss (giữ `SwissConfigEditor`); sheet gọi đúng route tạo/cập nhật hạng mục mà Web dùng.

#### Scenario: Tạo hạng mục đôi có ELO và phí riêng
- WHEN BTC tạo hạng mục "Đôi Nam" sức chứa 16, ELO 1000–1600, phí riêng 200.000₫
- THEN sheet validate ELO min ≤ max và gửi payload đủ các trường đó; hạng mục mới hiện đúng giá trị

#### Scenario: Sửa hạng mục đã có bracket
- WHEN BTC mở sửa hạng mục đã sinh sơ đồ
- THEN thể thức và các trường kết cấu bị khoá, vẫn sửa được giới hạn/luật từng vòng qua sheet vòng đấu

### Requirement: Preset theo môn và validate hạng mục
Sheet hạng mục SHALL có preset nhanh theo môn điền sẵn các trường luật, cho sửa tay sau khi áp. Validate SHALL theo luật Web: ELO min ≤ max, sức chứa ≥ 1; lỗi hiển thị tại trường, không gửi request khi còn lỗi.

#### Scenario: Preset theo môn
- WHEN BTC chọn preset "Pickleball chuẩn"
- THEN các trường số set/điểm/win-by-2/deuce tự điền theo preset và vẫn sửa tay được

#### Scenario: ELO min lớn hơn max
- WHEN BTC nhập ELO min 1600, max 1000
- THEN sheet báo lỗi tại trường và nút lưu bị chặn

### Requirement: Sheet cấu hình từng vòng đấu
Khi hạng mục đã có sơ đồ, màn quản lý SHALL cho mở sheet cấu hình của từng vòng trong stage: tên sân mặc định, giờ mặc định, và luật riêng của vòng (số set, điểm/set, win-by-2, điểm deuce tối đa, super tiebreak, ghi chú); lưu gọi `PATCH /tournaments/stages/:stageId` với payload giống Web `handleSaveStageDetails`.

#### Scenario: Sửa giờ mặc định vòng 2
- WHEN BTC đặt giờ mặc định vòng 2 là 08:30 và bấm lưu
- THEN App gửi PATCH stages với scheduledAt mặc định mới và vòng đó cập nhật sau tải lại

#### Scenario: Lỗi validate
- WHEN BTC nhập điểm/set bằng 0
- THEN sheet báo lỗi validate và không gửi request
