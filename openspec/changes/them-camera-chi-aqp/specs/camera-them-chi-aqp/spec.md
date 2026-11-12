## ADDED Requirements

### Requirement: Hộp Thêm camera chỉ có đường AQP
Hộp "Thêm camera" của giải đấu trong App SHALL tạo camera chế độ `PUSH` và SHALL NOT cho chọn PUSH/PULL hay nhập URL phát.

#### Scenario: Mở hộp Thêm camera
- **WHEN** BTC mở hộp "Thêm camera"
- **THEN** hộp hiện ô tên camera và ô chọn sân, không có nút PUSH/PULL và không có ô URL phát

#### Scenario: Gửi camera mới
- **WHEN** BTC điền tên hợp lệ rồi bấm "Thêm camera"
- **THEN** App gửi `mode: PUSH` không kèm URL, rồi mở popup Server và Stream Key như trước

### Requirement: Nút ? hướng dẫn có hoạt hình
Hộp "Thêm camera" SHALL có nút "?" mở khung hướng dẫn gồm sơ đồ động và 3 bước. Hoạt hình MUST tắt khi hệ điều hành bật giảm chuyển động, và khung hướng dẫn MUST vừa màn hình rộng 320dp.

#### Scenario: Mở và đóng hướng dẫn
- **WHEN** BTC bấm "?" rồi bấm "?" lần nữa
- **THEN** khung hướng dẫn mở rồi đóng, hộp "Thêm camera" vẫn mở và ô tên vẫn dùng được

#### Scenario: Giảm chuyển động
- **WHEN** hệ điều hành bật giảm chuyển động
- **THEN** khung hướng dẫn mở không có hoạt hình lặp
