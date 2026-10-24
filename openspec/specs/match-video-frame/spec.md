# match-video-frame Specification

## Purpose
Khung video ở màn chi tiết trận luôn đủ cao để bảng điểm và nhãn camera không đè lên nhau, kể cả khi trận chưa có luồng phát.

## Requirements

### Requirement: Khung chưa có tín hiệu giữ tỉ lệ 16:9
Khi trận chưa có luồng phát, khung video SHALL có chiều cao bằng chiều rộng nhân 9/16, giống trình phát lúc luồng chưa có metadata.

#### Scenario: Trận chưa gán camera
- **WHEN** người xem mở chi tiết trận chưa có luồng phát trên màn rộng 412 px
- **THEN** khung video cao khoảng 232 px, hiện icon camera và chữ "Chưa có tín hiệu phát trực tiếp" ở giữa, bảng điểm nằm góc trên trái không đè chữ

#### Scenario: Backend lỗi khi tải playback
- **WHEN** tải thông tin phát lỗi
- **THEN** khung vẫn hiện trạng thái chưa có tín hiệu với tỉ lệ 16:9, không làm hỏng màn
