## ADDED Requirements

### Requirement: Luật theo vòng dự kiến khi chưa có sơ đồ
App SHALL tính vòng dự kiến từ thể thức và số đội và cho sửa luật từng vòng, lưu vào `roundConfig` của hạng mục.

#### Scenario: Loại trực tiếp
- WHEN số đội tối đa N >= 2 THEN số vòng = log2(min(64, 2^ceil(log2 N))); nhãn từ cuối: Chung kết, Bán kết, Tứ kết, Vòng 16/32/64.

#### Scenario: Vòng bảng + knockout
- WHEN thể thức GROUP_STAGE_KNOCKOUT THEN danh sách = Vòng bảng dùng chung (vòng 0) + các Lượt `leg_N` + knockout tính theo số bảng × đội đi tiếp.

#### Scenario: Vòng tròn / Thụy Sĩ / thiếu số đội
- WHEN ROUND_ROBIN THEN chỉ phần vòng bảng; SWISS hoặc số đội null/0/1 (knockout) THEN rỗng và mục bị ẩn, không báo lỗi.

#### Scenario: Đổi số đội sau khi đã lưu
- WHEN một vòng không còn tồn tại THEN ẩn khỏi danh sách nhưng KHÔNG xóa khóa đã lưu trong `roundConfig`.

#### Scenario: Đã có sơ đồ
- WHEN hạng mục đã có sơ đồ THEN dùng stage thật như trước.
