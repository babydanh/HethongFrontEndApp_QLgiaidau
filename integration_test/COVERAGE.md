# Độ phủ E2E App (integration_test)

Chức năng → mã TC. Cột "Vai" cho biết ai thao tác trên giao diện (UI) và ai qua API. Ca có `BUG-...` đang `skip: true`
(đỏ vì lỗi sản phẩm, lý do ở `openspec/changes/app-e2e-nhieu-tai-khoan/design.md`, mục "Phát hiện").
Kết quả lượt cloud 2026-11-14 (nhánh đã gộp): số ca xanh / bỏ qua của từng file ở cuối file này.

## Quản lý giải của Ban tổ chức (TC-QLGD-APP-01..80)

Bốn file `organizer_*_journey_test.dart`, xem bảng trong `ORGANIZER_JOURNEYS.md`.

## Nhiều tài khoản (TC-MULTI-*)

| Chức năng | TC | Vai |
|---|---|---|
| Thêm trọng tài, trọng tài thấy vai ở Dashboard | A-01, A-02 | BTC UI, trọng tài UI |
| Lời mời trọng tài (`/referee/invites`) | A-03, A-04 (BUG-REF-01) | trọng tài UI |
| Chấm điểm live, người xem thấy tỉ số đổi trong 10 giây | A-05..A-09, A-12 | trọng tài UI + API, người xem UI |
| Chat trận (người xem, trọng tài) | A-10, A-11 | người xem UI, trọng tài API |
| Đồng BTC quản lý giải | A-14..A-16 | BTC API, đồng BTC UI |
| Phân quyền âm chấm điểm/trạng thái trận | A-13, A-17, A-18, A-19, A-19b, A-19c, A-20 | người ngoài, ADMIN |
| Đăng ký đơn, đôi, đội; mã mời `/join/:code`, `/join-team`, `/lite-join/:code` | B-01..B-07 | VĐV UI |
| Theo dõi giải | B-08 (BUG-FOLLOW-01) | VĐV UI |
| Thanh toán lệ phí (tới màn cổng), dashboard VĐV | B-09, B-10 | VĐV UI |
| Hồ sơ, đổi mật khẩu, xếp hạng | B-11..B-13 | VĐV UI |
| Phân quyền âm VĐV (màn quản lý, `/admin`, `/ops`, API) | B-14..B-20 | VĐV UI + API |
| Tạo CLB, xin vào, duyệt, từ chối, thông báo | C-01..C-04, C-19 | chủ CLB UI, thành viên UI |
| Mời thành viên CLB, màn Lời mời | C-06, C-07 | chủ API, thành viên UI |
| Chat CLB hai chiều, danh sách chat, chat 1-1 | C-08..C-11 | chủ UI, thành viên UI |
| Thông báo: đọc, Đọc tất cả, lọc | C-12..C-15 | thành viên UI |
| Phân quyền âm CLB | C-05, C-16, C-17 (BUG-CLUB-02), C-18 | thành viên, người ngoài |
| Thoát màn chat khi socket đóng | C-20 (BUG-CHAT-01) | chủ CLB UI |
| Social: thêm người chơi, thu tiền, báo cáo kèo | D-01, D-04..D-07, D-09 | host UI, người chơi UI |
| Social: thông báo, trạng thái thanh toán của người chơi | D-02, D-03 (BUG-SOCIAL-D-02), D-08 (BUG-SOCIAL-D-01) | người chơi |
| Social: phân quyền âm | D-10..D-12 | người chơi, người ngoài |
| Đăng ký, quên mật khẩu, đăng nhập sai | E-01..E-04 | khách UI |
| Admin: 4 màn quản trị, duyệt giải | E-05, E-15 | admin UI |
| Admin: `/admin` tổng, CLB, yêu cầu thay đổi, khiếu nại, xác minh | E-06..E-12 (BUG-ADMIN-01, 03, 04) | admin UI |
| Khách: trang chủ, bracket, live, link mời | E-14, E-16, E-17, E-20 | khách UI |
| Phân quyền âm admin, khách | E-13, E-18, E-19 (BUG-GUEST-01) | VĐV, khách |
| Chuỗi giải: tạo, sửa, xóa, vòng | F-01..F-04 | BTC UI |
| Nhân sự chuỗi | F-05, F-06 (BUG-F-01) | BTC API, người nhận API |
| `/ops`: danh sách VĐV, đồng BTC | F-07, F-08 (BUG-F-02), F-09 | BTC UI, đồng BTC UI |
| Lite: vào bằng mã, ghép cặp | F-14, F-15 | VĐV UI, BTC UI |
| Phân quyền âm chuỗi, `/ops` | F-10..F-13 | VĐV, người dùng thường, khách |
| Tìm và lọc giải (tên, trạng thái, môn, tỉnh), tìm địa điểm | G-01..G-05 (G-02: BUG-FILTER-01) | khách UI |
| Trang giải, bracket 3 thể thức, xem lại trận | G-06..G-10 | khách UI |
| Xếp hạng, hồ sơ VĐV, dữ liệu công khai chung | G-11..G-13 | khách UI, VĐV UI |
| Phân quyền âm xem | G-14, G-15 (BUG-PERM-01) | khách, VĐV |
| Ma trận vai × lệnh API nhạy cảm (16 ô) | H-01..H-16 | API |
| Phân quyền âm màn vận hành `/ops` | H-17, H-18, H-19 (BUG-PERM-01) | VĐV UI, người dùng thường |

## Ô còn trống

- Hai máy cùng lúc (realtime hai chiều thật): chỉ kiểm bằng API ghi, UI một máy đọc (cách A trong `design.md`).
- Tài khoản mới chưa xác minh email: không kiểm được đồng BTC "qua" ở ma trận H, nên các ô "chặn" của vai mới cần đọc kèm giới hạn đó.
- Cổng thanh toán, đăng nhập Google, thư viện ảnh hệ thống (chọn logo): chỉ tới nút hoặc màn chuyển hướng.
- Màn Xếp hạng/ELO có dữ liệu thật: seed chưa có VĐV có ELO.
- Mời nhân sự chuỗi giải qua giao diện: app chưa có màn, API trả 500 (BUG-F-01).
- Ca "nhẹ" chỉ kiểm màn mở được: B-07, B-09, B-13.
