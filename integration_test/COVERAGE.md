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

## Kết quả lượt cloud (nhánh đã gộp, 2026-11-14)

Mỗi file một lượt `app-e2e` riêng, chạy song song. Không có ca đỏ ngoài các ca `skip` vì lỗi sản phẩm.

| File | Xanh | Bỏ qua | Run |
|---|---|---|---|
| `multi_referee_live_journey_test.dart` | 17 | 5 | 43587778603 |
| `multi_player_journey_test.dart` | 17 | 3 | 43587769964 |
| `multi_club_chat_notify_journey_test.dart` | 18 | 2 | 43587742294 |
| `multi_social_cross_journey_test.dart` | 9 | 3 | 43587795293 |
| `multi_admin_guest_journey_test.dart` | 12 | 8 | 43587734015 |
| `multi_series_ops_lite_journey_test.dart` | 12 | 3 | 43589174093 (lần đầu F-02 đỏ do chờ chưa đủ, đã sửa) |
| `multi_discover_view_journey_test.dart` | 13 | 2 | 43587751665 |
| `multi_permission_matrix_test.dart` | 17 | 2 | 43587760726 |

## Widget và unit test (thư mục `test/`)

Bổ sung bởi change `app-e2e-sua-do-va-bo-sung` (xanh cục bộ, chạy lại trong CI của nhánh):

| Chức năng | File | Ca |
|---|---|---|
| Giao bóng và đổi sân pickleball (đôi/đơn, giao 1/2, mất giao, đổi sân, hoàn tác) | `test/match/pickleball_serve_side_test.dart` | 9 |
| Giao bóng và đổi sân tennis (đổi giao mỗi game, tie-break, đổi sân sau game lẻ, hoàn tác) | `test/match/tennis_serve_side_test.dart` | 14 |
| Giao bóng và đổi sân cầu lông (chẵn/lẻ, giữ giao, đổi ô, set quyết định, hoàn tác) | `test/match/badminton_serve_side_test.dart` | 15 |
| Đội bóng | `test/features/football_team/football_teams_screen_test.dart` | 14 |
| Lời mời trọng tài | `test/features/referee/referee_invites_screen_test.dart` | 9 |
| Kết quả thanh toán và xác minh PayOS | `test/features/payment/payment_screens_test.dart` | 14 |
| Lịch sử thanh toán, thanh toán lại | `test/features/payment/payments_screen_test.dart` | 19 (1 skip BUG-PAY-01) |
| Thanh toán (checkout) | `test/features/payment/checkout_screen_test.dart` | 17 |
| Đặt lại mật khẩu | `test/features/auth/reset_password_screen_test.dart` | 5 |
| Đăng nhập, đăng ký | `test/features/auth/login_register_screen_test.dart` | 18 |
| Quên mật khẩu | `test/features/auth/forgot_password_screen_test.dart` | 11 (1 skip BUG-FORGOT-01) |
| Màn khởi động (điều hướng theo vai) | `test/features/auth/splash_screen_test.dart` | 10 |
| Lời mời CLB | `test/features/community/club_invites_screen_test.dart` | 9 |
| Tạo CLB | `test/features/community/create_club_screen_test.dart` | 8 |
| Điều phối CLB | `test/features/community/club_management_screen_test.dart` | 12 (1 skip BUG-CLUB-02) |
| Chi tiết CLB theo vai | `test/features/community/club_detail_screen_test.dart` | 15 |
| Thẻ trận trực tiếp ở Khám phá | `test/features/explore/live_match_card_test.dart` | 8 |
| Màn Trận đấu trực tiếp | `test/features/live/live_match_screen_test.dart` | 13 |

Vòng 3 (11 màn trước đó chưa có test nào nhắc tới, cộng tennis match tie-break và No-Ad):

| Chức năng | File | Ca |
|---|---|---|
| Tìm kiếm cộng đồng | `test/features/community/community_search_screen_test.dart` | 29 (1 skip BUG-SEARCH-01) |
| Giải đấu của CLB | `test/features/community/club_tournaments_screen_test.dart` | 32 (1 skip BUG-CLBTOUR-01) |
| Tạo buổi giao lưu CLB | `test/features/community/club_match_session_create_screen_test.dart` | 37 |
| Chi tiết buổi giao lưu CLB | `test/features/community/club_match_session_detail_page_test.dart` | 75 (3 skip BUG-SESSDETAIL-01..03) |
| Tham gia đội bằng mã | `test/features/register/join_team_screen_test.dart` | 15 |
| Màn chờ sau đăng nhập | `test/features/auth/login_loading_screen_test.dart` | 10 |
| Thêm/sửa đội | `test/features/teams/add_team_screen_test.dart` | 21 |
| Quét QR | `test/features/home/qr_scanner_screen_test.dart` | 21 (1 skip BUG-QR-01) |
| Danh sách chat, tab AI, tab Hỗ trợ | `test/features/chat/chat_screen_test.dart` | 39 (1 skip BUG-CHAT-02) |
| Hồ sơ người khác | `test/features/profile/user_profile_screen_test.dart` | 40 (1 skip BUG-PROFILE-01) |
| Tạo giải nhanh công khai (cơ bản, môn/thể thức, bóng đá, bracket và số đội, vòng tròn, lịch, địa điểm, tỉnh/phường, lệ phí, gửi) | `test/features/tournament/create_quick_tournament_*_test.dart` (10 file) | 145 (1 skip BUG-QUICKCREATE-01) |
| Tennis match tie-break 10 điểm và No-Ad | `test/match/tennis_match_tiebreak_noad_test.dart` | 29 |

Chưa phủ: dialog Thêm nội dung và mô tả giải/upload ảnh của tạo giải nhanh, lỗi mạng/5xx lúc gửi tạo giải nhanh, `ClubStandaloneMatchDialog`, nút chia sẻ, `OfficialScorePage` từ thẻ trận CLB; luồng `launchUrl` thật khi tạo link thanh toán; danh sách CLB (không có màn riêng); nút Apple ngoài iOS.

## Kết quả lượt cloud trên nhánh `app-e2e-sua-do-va-bo-sung` (2026-11-14, sha `2fe1d964`)

33 file `integration_test/` đều xanh (không file nào đỏ). Run id từng file:

| File | Xanh | Bỏ qua | Run |
|---|---|---|---|
| `auth_flow_test.dart` | 2 | 0 | 43614720378 |
| `chup_profile_admin_test.dart` | 1 | 0 | 43614730897 |
| `chup_profile_btc_test.dart` | 1 | 0 | 43614740783 |
| `chup_profile_vdv_test.dart` | 1 | 0 | 43614751392 |
| `multi_admin_guest_journey_test.dart` | 12 | 8 | 43614762634 |
| `multi_club_chat_notify_journey_test.dart` | 18 | 2 | 43614773497 |
| `multi_discover_view_journey_test.dart` | 13 | 2 | 43614898345 |
| `multi_permission_matrix_test.dart` | 17 | 2 | 43614908918 |
| `multi_player_journey_test.dart` | 17 | 3 | 43614919672 |
| `multi_referee_live_journey_test.dart` | 17 | 5 | 43614931037 |
| `multi_series_ops_lite_journey_test.dart` | 12 | 3 | 43614942332 |
| `multi_social_cross_journey_test.dart` | 9 | 3 | 43614953648 |
| `organizer_flow_test.dart` | 1 | 0 | 43614964869 |
| `organizer_formats_journey_test.dart` | 5 | 0 | 43614976295 |
| `organizer_run_journey_test.dart` | 8 | 0 | 43614987001 |
| `organizer_schedule_settings_journey_test.dart` | 7 | 0 | 43614997966 |
| `organizer_setup_journey_test.dart` | 10 | 0 | 43615009033 |
| `smoke_test.dart` | 1 | 0 | 43615020266 |
| `social_chat_journey_test.dart` | 4 | 2 | 43615033454 |
| `social_create_journey_test.dart` | 4 | 0 | 43615045912 |
| `social_run_journey_test.dart` | 8 | 0 | 43615058109 |
| `tournament_player_flow_test.dart` | 2 | 0 | 43615069973 |
| `xem_bam_diem_bongda_test.dart` | 4 | 0 | 43615081726 |
| `xem_bam_diem_pickleball_test.dart` | 4 | 0 | 43615093804 |
| `xem_bam_diem_rally_test.dart` | 4 | 0 | 43615105082 |
| `xem_bam_diem_tennis_test.dart` | 4 | 0 | 43615126051 |
| `xem_ketqua_btc_test.dart` | 2 | 0 | 43615137878 |
| `xem_noidung_form_vongdoi_test.dart` | 3 | 0 | 43615149477 |
| `xem_taichinh_doi_xuat_phanquyen_test.dart` | 4 | 0 | 43615160699 |
| `xem_tai_tro_1_7_test.dart` | 15 | 0 | 43615171543 |
| `xem_tai_tro_livestream_ketqua_test.dart` | 4 | 0 | 43615182204 |
| `xem_tongquan_thongtin_diadiem_test.dart` | 3 | 0 | 43615193492 |
| `xem_vdv_lich_test.dart` | 6 | 0 | 43615204016 |
| **Tổng (33 file)** | **223** | **30** | |
