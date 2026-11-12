# Độ phủ sau khi thêm test

**CHƯA ĐO LẠI.** Lần đo toàn repo thứ hai (`flutter test --no-pub --coverage -j 2`) bị hệ thống dừng khi mới chạy ~410/3800 test vì máy thiếu RAM (thông báo "stopped because the system is running low on memory"). Theo luật của harness, không tự chạy lại; cần người dùng cho phép hoặc đo chia nhỏ theo thư mục.

Số nền để so sánh: xem `coverage-baseline.md` (55,06% = 54076/98206 dòng).

Cách đo lại gợi ý (mỗi lần một lệnh, qua khoá máy):
`flock /tmp/qlgd-heavy.lock cloud-flutter test --no-pub --coverage -j 1 test/data test/providers test/domain test/models test/core`
rồi gộp với phần còn lại của `test/` (lcov các thư mục khác) và chạy `lcov_report.py` như lần nền.

Các file đích đã thêm test (chưa có % sau): api_community_repository, api_community_social_repository, api_team_repository, api_social_session_repository, social_session_model, api_tournament_repository (2 nhóm), api_match_repository, social_provider, lite_management_notifier, score_validator, api_user/ranking/auth/token repository, vietnam_address_parser, user.dart, elo_history_log, api_club_match_session_repository.
