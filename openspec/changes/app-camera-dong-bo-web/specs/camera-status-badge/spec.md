## ADDED Requirements

### Requirement: Badge trạng thái camera đủ 6 trạng thái
Mọi chỗ App hiện camera sân (panel camera, hàng camera theo sân) SHALL hiện badge gồm chấm màu + chữ cho `status`: IDLE=Sẵn sàng, ASSIGNED=Đã gán, WAITING=Chờ tín hiệu, LIVE=Đang live, OFFLINE=Offline, ERROR=Lỗi. Giá trị lạ hoặc rỗng SHALL hiện "Không rõ". Trạng thái SHALL được đọc bằng chữ (Semantics), không chỉ dựa màu.

#### Scenario: Từng trạng thái
- **WHEN** camera có status `OFFLINE`
- **THEN** badge hiện chữ "Offline" cùng chấm

#### Scenario: Trạng thái lạ
- **WHEN** status là `FOO` hoặc rỗng
- **THEN** badge hiện "Không rõ", không crash
