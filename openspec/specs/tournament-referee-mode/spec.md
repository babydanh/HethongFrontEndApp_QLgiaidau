# tournament-referee-mode Specification

## Purpose
Màn quản lý giải trên App hiển thị và cho thao tác theo vai do Backend trả về (ban tổ chức hoặc trọng tài đã nhận lời), để trọng tài vận hành trận mà không chạm được thiết lập của ban tổ chức.

## Requirements

### Requirement: Vai quản lý lấy từ Backend

App SHALL xác định vai của người dùng trên màn quản lý giải bằng `GET /tournaments/:id?manage=true`: `manageRole = 'REFEREE'` là trọng tài, `'MANAGER'` hoặc thiếu trường là ban tổ chức, giá trị khác là trọng tài. Phản hồi 401/403/404 (Backend trả 404 cho trọng tài của giải DRAFT/PENDING) SHALL được coi là không có quyền; lỗi khác SHALL hiện nút thử lại, không đoán quyền. Vai SHALL NOT lấy từ bộ nhớ đệm khi mạng lỗi.

#### Scenario: Backend cũ không có manageRole
- **WHEN** `?manage=true` trả 200 không có `manageRole`
- **THEN** người dùng vào màn quản lý với đủ quyền ban tổ chức như trước

#### Scenario: Trọng tài đã nhận lời
- **WHEN** `?manage=true` trả 200 với `manageRole = 'REFEREE'`
- **THEN** người dùng vào màn quản lý ở chế độ trọng tài

#### Scenario: Người ngoài
- **WHEN** `?manage=true` trả 403
- **THEN** màn hiện "Bạn không có quyền vận hành giải đấu này." và không dựng màn quản lý

### Requirement: Trọng tài chỉ thấy sáu tab

Ở chế độ trọng tài, màn quản lý SHALL hiện đúng các tab Tổng quan, Nội dung, VĐV, Bảng đấu, Lịch thi đấu, Kết quả theo thứ tự này, SHALL NOT hiện Camera, Cài đặt, nhóm THIẾT LẬP/HỆ THỐNG, menu ba chấm (xuất, báo cáo, kết thúc, xoá giải). Đầu trang SHALL có nhãn chữ "Trọng tài" và một dải thông báo một dòng nói trọng tài được đổi giờ, sân và nhập kết quả.

#### Scenario: Mở màn quản lý với vai trọng tài
- **WHEN** trọng tài mở `/organizer/tournaments/:id/manage`
- **THEN** thanh tab có 6 tab, không có Camera và Cài đặt, có nhãn "Trọng tài" và dải thông báo

### Requirement: Thao tác ghi ngoài quyền bị ẩn với trọng tài

Ở chế độ trọng tài, App SHALL ẩn mọi thao tác ghi trừ đổi giờ/sân/thời lượng/hoán đổi trận trên lịch và nhập kết quả trận chưa chốt qua luồng chấm điểm hiện có. Cụ thể SHALL ẩn: sửa thông tin/ảnh/liên hệ/phí giải, nút vòng đời giải, xác nhận lại kết quả, thêm/sửa/xoá nội dung, thêm/nhập/ghép/duyệt/loại VĐV, check-in, mở hồ sơ VĐV, tạo/xoá/sửa sơ đồ, tạo sân, giờ sân, xếp lịch tự động/AI, bản nháp, gán trọng tài, thao tác đặc biệt, mở trang sơ đồ của BTC.

#### Scenario: Tab VĐV chỉ xem
- **WHEN** trọng tài mở tab VĐV có hồ sơ chờ duyệt
- **THEN** danh sách hiện tên và trạng thái, không có nút thêm VĐV, duyệt, từ chối, menu dòng

#### Scenario: Kết quả chỉ nhập trận chưa chốt
- **WHEN** trọng tài mở tab Kết quả
- **THEN** trận chưa chốt có nút nhập điểm, trận đã chốt không có; hộp sửa lịch (giờ, sân, thời lượng) vẫn mở cho trận chưa khoá

### Requirement: Ghi lịch của trọng tài không có refereeId

Ở chế độ trọng tài, mọi lệnh `PATCH /matches/:id/schedule` App gửi SHALL NOT có khoá `refereeId` (kể cả null) và `matchConfig` SHALL chỉ có khoá `durationMinutes`.

#### Scenario: Lịch thi đấu chỉ còn kéo thả giờ/sân
- **WHEN** trọng tài kéo một trận sang ô khác hoặc từ khay chờ vào lưới
- **THEN** App gửi `PATCH /matches/:id/schedule` chỉ với `courtId`, `courtName`, `scheduledAt` và `matchConfig.durationMinutes` (hoặc xoá đúng ba trường giờ/sân), không có khoá `refereeId`

#### Scenario: Hộp sửa nhanh của trọng tài
- **WHEN** trọng tài chạm một trận chưa khoá trên lưới lịch và lưu
- **THEN** hộp không có ô chọn trọng tài và lệnh ghi không có khoá `refereeId`

### Requirement: Trang của ban tổ chức chặn cả deep link

Route `/organizer/tournaments/:id/ops`, `/organizer/tournaments/:id/ops/bracket` và các route con `/organizer/tournaments/:id/manage/{teams, teams/add, teams/edit, draw, bracket, swiss-pairing/:divisionId}` SHALL chỉ dựng nội dung cho ban tổ chức; trọng tài và người ngoài SHALL thấy màn không có quyền. Các lối vào hub khác (`/admin/tournament/:id`, `/lite-manage/:id`, `/lite/tournaments/:id/manage`) SHALL áp cùng luật vai. Màn quản lý Lite (giải CLB Lite) SHALL chỉ dành cho ban tổ chức.

#### Scenario: Trọng tài mở link xếp sơ đồ
- **WHEN** trọng tài mở `/organizer/tournaments/:id/manage/draw`
- **THEN** App hiện màn không có quyền, không dựng màn xếp sơ đồ

### Requirement: Lối vào cho trọng tài

Tab Hoạt động của dashboard SHALL liệt kê các giải người dùng làm trọng tài (đã nhận lời), mỗi giải một dòng, bỏ giải DRAFT/PENDING, và chạm vào một giải SHALL mở `/organizer/tournaments/:id/manage`.

#### Scenario: Có giải làm trọng tài
- **WHEN** workspace có `refereeTournaments` không rỗng
- **THEN** dashboard hiện nhóm "Giải làm trọng tài", chạm một dòng mở màn quản lý giải đó
