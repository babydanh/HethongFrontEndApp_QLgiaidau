## ADDED Requirements

### Requirement: Header popup chỉ có tiêu đề
Popup "Thêm VĐV" SHALL hiển thị tiêu đề "Thêm VĐV" và nút đóng; SHALL NOT hiển thị dòng mô tả hay dòng tên giải · nội dung.

#### Scenario: Mở popup
- **WHEN** mở popup Thêm VĐV
- **THEN** tiêu đề là "Thêm VĐV" và không có chữ mô tả "Tìm bạn bè, thành viên CLB…" hay tên giải

### Requirement: Form nhập tay gửi đủ trường Backend
Tab "Nhập tên" SHALL có các ô Tên VĐV, Email (tùy chọn), SĐT, Điểm, Loại điểm (ELO hoặc DUPR) và Ghi chú, và SHALL gửi `name`, `email`, `phone`, `notes`, `elo`, `eloSource`, `tournamentDivisionId` đến `POST /tournaments/:id/add-athletes/direct`, bỏ qua trường để trống. Khi có điểm thì SHALL gửi cả `elo` và `eloSource`; điểm không phải số hữu hạn hoặc ngoài khoảng (ELO 100–3000, DUPR 1–8) SHALL bị chặn kèm thông báo.

#### Scenario: Gửi đủ trường
- **WHEN** nhập tên, email, SĐT, điểm 4,5 loại DUPR, ghi chú rồi gửi
- **THEN** request chứa `phone`, `notes`, `elo` = 4.5 và `eloSource` = `DUPR` cùng tên và email

#### Scenario: Điểm sai
- **WHEN** nhập điểm "abc" hoặc DUPR 9
- **THEN** hiện lỗi dưới ô điểm và không gửi request

### Requirement: Thêm nhiều VĐV nhập tay qua hàng chờ
Tab "Nhập tên" SHALL có nút "Thêm vào danh sách" đưa VĐV đang nhập vào hàng chờ (mới nhất trên cùng, tối đa 25, chặn trùng email đã có trong hàng chờ) và nút xoá từng dòng. Nút chính "Thêm (N)" với N = số dòng chờ + 1 nếu form đang điền hợp lệ SHALL gửi tuần tự từng người; dòng thành công SHALL bị xoá khỏi hàng chờ, dòng bị Backend từ chối SHALL ở lại kèm lý do, và lỗi chưa rõ kết quả SHALL dừng loạt gửi.

#### Scenario: Thêm hai người
- **WHEN** nhập người A, bấm "Thêm vào danh sách", nhập người B, bấm "Thêm (2)"
- **THEN** gửi hai request theo thứ tự A rồi B và hàng chờ trống

#### Scenario: Trùng email trong hàng chờ
- **WHEN** thêm vào danh sách một email đã có trong hàng chờ
- **THEN** hiện "VĐV này đã có trong danh sách" và hàng chờ không đổi

#### Scenario: Một người bị từ chối
- **WHEN** người A thành công, người B bị Backend trả 4xx
- **THEN** A bị xoá khỏi hàng chờ, B ở lại kèm lý do và có thông báo "Đã thêm 1 VĐV; thất bại: 1"
