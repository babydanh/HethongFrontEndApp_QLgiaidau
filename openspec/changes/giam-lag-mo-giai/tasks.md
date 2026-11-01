## 1. Tầng dữ liệu
- [x] 1.1 `getById` gửi song song `/divisions` và `/sponsors`; tải đội gửi song song `/participants` và `/divisions`. Tiêu chí: `flutter test --no-pub test/data/tournament_open_speed_repository_test.dart` exit 0 (đỏ trước).
  - Files: sửa `lib/data/repositories/api/api_tournament_repository.dart:34-57`, `lib/data/repositories/api/api_team_repository.dart:232-245`; tạo test `test/data/tournament_open_speed_repository_test.dart`
  - Phụ thuộc: không
- [x] 1.2 Luồng trận phát ngay dữ liệu đã lưu khi mở lại và bỏ qua sự kiện socket của giải khác. Tiêu chí: `flutter test --no-pub test/data/api_match_repository_open_speed_test.dart` exit 0 (đỏ trước).
  - Files: sửa `lib/data/repositories/api/api_match_repository.dart:225-250`; tạo test `test/data/api_match_repository_open_speed_test.dart`
  - Phụ thuộc: không
- [x] 1.3 Provider Lite giữ danh sách trận cuối khi một lần poll lỗi. Tiêu chí: `flutter test --no-pub test/providers/lite_bracket_provider_test.dart` exit 0 (đỏ trước).
  - Files: sửa `lib/providers/query_providers.dart:234-312`; tạo test `test/providers/lite_bracket_provider_test.dart`
  - Phụ thuộc: không

## 2. Màn chi tiết giải
- [ ] 2.1 Skeleton thay vòng xoay; bỏ cổng `teamsAsync.when`; tab Live/Kết quả theo trạng thái giải; tóm tắt live/kết quả bằng provider riêng; huỷ `TabController` cũ sau frame. Tiêu chí: `flutter test --no-pub test/features/tournament/results_tab_test.dart test/features/tournament/tournament_open_speed_screen_test.dart` exit 0.
  - Files: sửa `lib/features/tournament/screens/tournament_intro_screen.dart`, `lib/providers/query_providers.dart` (thêm provider tóm tắt, chủ file chung: 1.3 xong trước), `lib/features/tournament/widgets/tournament_state_views.dart` (chỉ dùng lại); tạo test `test/features/tournament/tournament_open_speed_screen_test.dart`
  - Phụ thuộc: 1.3

## 3. Bảng trận
- [ ] 3.1 `ResultsMatchBoard` không tính lại vòng/nhãn mỗi build, hàng trận dựng lazy, ô tìm debounce. Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/results_match_board_test.dart test/features/tournament/widgets/live_tab_test.dart` exit 0.
  - Files: sửa `lib/features/tournament/widgets/results_match_board.dart`, `lib/features/tournament/utils/results_rounds.dart`, `lib/features/tournament/widgets/live_tab.dart`
  - Phụ thuộc: 2.1

## 4. Kiểm chứng
- [ ] 4.1 `flutter analyze --no-pub` các file đã sửa; test hẹp; `app-run.py status`; xem thật trên điện thoại khi máy thức. Tiêu chí: exit 0.
  - Phụ thuộc: 3.1
