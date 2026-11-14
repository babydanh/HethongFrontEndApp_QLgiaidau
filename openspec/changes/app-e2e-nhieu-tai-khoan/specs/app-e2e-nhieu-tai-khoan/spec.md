## ADDED Requirements

### Requirement: Hành trình nhiều tài khoản cho mọi module người dùng
Bộ `integration_test/` SHALL có các file hành trình `multi_*_journey_test.dart`. Mỗi file tự tạo bộ tài khoản riêng cho từng vai và kiểm hiệu ứng chéo: hành động của một tài khoản phải hiện đúng ở tài khoản khác. Mỗi file chạy độc lập được trên job `app-e2e` cloud trong tối đa 60 phút, và chạy song song với file khác không đụng dữ liệu nhau.

#### Scenario: Lời mời trọng tài đi trọn vòng
- **WHEN** BTC mời một tài khoản VĐV mới làm trọng tài của giải
- **THEN** tài khoản đó đăng nhập trên app, mở được danh sách lời mời, chấp nhận, rồi thấy nút chấm điểm ở trận được phân

#### Scenario: Người xem thấy tỉ số live không cần tải lại
- **WHEN** trọng tài cộng điểm qua API trong lúc tài khoản người xem đang mở `/live/:matchId`
- **THEN** tỉ số trên màn người xem đổi trong vòng 10 giây mà không cần kéo để tải lại

#### Scenario: Thông báo chéo tài khoản
- **WHEN** chủ CLB duyệt yêu cầu tham gia của một tài khoản
- **THEN** tài khoản đó thấy thông báo mới trong `/notifications` và thấy mình là thành viên ở trang CLB

### Requirement: Phân quyền âm theo vai
Mỗi file hành trình SHALL có ca kiểm vai không đủ quyền: không thấy nút của vai cao hơn, và mở route riêng thì bị đưa về đăng nhập hoặc trang chủ, hoặc thấy màn báo không có quyền. Không chấp nhận màn trắng hay lỗi 401/403 thô.

#### Scenario: Khách mở route cần đăng nhập
- **WHEN** khách chưa đăng nhập mở `/chat` hoặc `/club-create`
- **THEN** app đưa khách tới `/login`, hoặc hiện màn yêu cầu đăng nhập, thay vì màn chức năng gọi API lỗi

#### Scenario: VĐV mở màn quản lý giải của người khác
- **WHEN** một VĐV không phải BTC mở `/organizer/tournaments/:id/manage`
- **THEN** app không hiện các nút quản lý và báo không có quyền

### Requirement: Lỗi sản phẩm được ghi lại, không che
Ca test đỏ vì lỗi sản phẩm SHALL giữ nguyên `expect`, được đánh dấu `skip: 'BUG-<id>: ...'`, và lỗi được ghi ở mục "Phát hiện" của `design.md`. Không ca nào được bọc `if (finder.evaluate().isNotEmpty)` để xanh giả.

#### Scenario: Ca phát hiện lỗi
- **WHEN** một ca hành trình đỏ vì app chặn sai quyền
- **THEN** ca đó có `skip` ghi mã lỗi, và `design.md` có dòng mã lỗi kèm `path:line` và bước tái hiện
