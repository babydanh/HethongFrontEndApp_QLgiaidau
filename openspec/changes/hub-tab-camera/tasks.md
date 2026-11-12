## 1. Tab Camera trong Quản lý giải

- [x] 1.1 Test đỏ TC-HUB-CAM-01..04 rồi thêm tab Camera vào hub, dùng chung luật chỉ-đọc với màn Vận hành. Tiêu chí: `flutter test --no-pub test/features/tournament/management_camera_tab_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_hub_screen.dart` (tabHeaders ~466, TabBarView ~486, enum `_HubTab` ~1169); sửa `lib/features/organizer_ops/screens/organizer_ops_screen.dart:170,3237`; test mới `test/features/tournament/management_camera_tab_test.dart`
  - Giao: `bool isReadOnlyTournamentStatus(String status)` (top-level, organizer_ops_screen.dart) · Nhận: `TournamentManagementCameraSection({tournamentId, divisionId, readOnly})`
  - Chủ file chung: 1.1 giữ cả hai file lib
  - Phụ thuộc: không
- [x] 1.2 Cập nhật test đang khẳng định hub có 7 tab. Tiêu chí: `flutter test --no-pub test/features/tournament/management_results_tab_test.dart test/features/tournament_management_hub_screen_test.dart` → exit 0
  - Files: sửa `test/features/tournament/management_results_tab_test.dart:96-115`, `test/features/tournament_management_hub_screen_test.dart:1998-2008`, `test/features/tournament/overview_step_popup_test.dart:142-143`
  - Giao: (không) · Nhận: thứ tự tab của 1.1
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.1

## 2. Kiểm tra

- [x] 2.1 Phân tích tĩnh và test liên quan. Tiêu chí: `flutter analyze --no-pub lib/features/tournament/screens lib/features/organizer_ops` → 0 lỗi; test của 1.1 và 1.2 chạy trên cloud runner → exit 0
  - Files: (không)
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.2
