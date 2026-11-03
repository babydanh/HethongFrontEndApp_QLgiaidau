## 1. Bảng đấu báo ngược lựa chọn

- [x] 1.1 `BracketViewScreen` nhận `selectedDivisionId` (host điều khiển, dải vẫn hiện; khác `divisionId` là khoá cứng và ẩn dải) và gọi `onDivisionChanged` khi chọn chip. Tiêu chí: `flutter test --no-pub test/features/bracket_view_division_callback_test.dart` → exit 0 (đỏ trước, xanh sau; đã chạy: 15/15 cùng test bracket nhúng và division_strip)
  - Files: sửa `lib/features/bracket/screens/bracket_view_screen.dart:38-66,186-191`; tạo `test/features/bracket_view_division_callback_test.dart`
  - Giao: `BracketViewScreen({..., String? selectedDivisionId, ValueChanged<String>? onDivisionChanged})` cho 4.1 · Nhận: (không)
  - Chủ file chung: 1.1 giữ `bracket_view_screen.dart`
  - Phụ thuộc: không

## 2. Lịch: lưới sân dùng DivisionStrip

- [x] 2.1 Lưới sân bỏ dropdown nội dung, dùng `DivisionStrip` ở hàng riêng trên thanh công cụ (cả màn toàn màn hình hưởng theo); `OrganizerOpsScreen` nhận `selectedDivisionId` điều khiển từ ngoài. Tiêu chí: `flutter test --no-pub test/features/ops_matches_view_toggle_test.dart` → exit 0, không còn key `schedule-division-dropdown` (đã chạy cùng 8 file lịch: 80/80 xanh)
  - Files: sửa `lib/features/tournament/widgets/tournament_schedule_court_grid.dart:318-330,926-936,1065-1090`; `lib/features/organizer_ops/screens/organizer_ops_screen.dart:40-75,290-300,2282`; `lib/features/tournament/screens/schedule_fullscreen_screen.dart:165`; test `test/features/ops_matches_view_toggle_test.dart` (TC-DIVSHARE-03 + 2 test đổi từ dropdown sang dải chip)
  - Giao: `OrganizerOpsScreen({..., String? selectedDivisionId})` (đổi `selectedDivisionId` → đồng bộ `_selectedDivisionId` trong `didUpdateWidget`) cho 4.1 · Nhận: (không)
  - Chủ file chung: 2.1 giữ 3 file trên
  - Phụ thuộc: không

## 3. Vận động viên: DivisionStrip thay accordion

- [x] 3.1 Tab VĐV hiện nội dung đang chọn trên `DivisionStrip`, bỏ `_expandedDivisionId`/`_toggle`; các nút thao tác giữ nguyên. Tiêu chí: `flutter test --no-pub test/features/athletes_tab_actions_test.dart test/features/tournament_management_hub_screen_test.dart` → exit 0 (sửa test accordion cũ theo hành vi mới, nêu trong commit; đã chạy cùng division_strip, bracket, ops: 100/100 xanh). Phát hiện thêm: `DivisionStrip` tự căn chip bằng `Scrollable.ensureVisible` cuộn luôn PageView của hub, đã giới hạn trong thanh chip
  - Files: sửa `lib/features/tournament/widgets/tournament_management_athletes_tab.dart:27-70,244-296,299-490`; `lib/features/tournament/widgets/division_strip.dart:82-95`; test `test/features/athletes_tab_actions_test.dart`, `test/features/tournament_management_hub_screen_test.dart`
  - Giao: `TournamentManagementAthletesTab({required Tournament tournament, String? selectedDivisionId, ValueChanged<String>? onDivisionChanged})` cho 4.1 · Nhận: (không)
  - Chủ file chung: 3.1 giữ `tournament_management_athletes_tab.dart`
  - Phụ thuộc: không

## 4. Hub nối lựa chọn chung

- [x] 4.1 Hub giữ `_divisionId` và truyền xuống 3 tab. Tiêu chí: `flutter test --no-pub test/features/tournament_management_hub_division_share_test.dart` → exit 0 (3 kịch bản trong spec; đỏ trước, đã chạy cùng test hub cũ: 73/73 xanh; kịch bản "nội dung bị xoá" kiểm ở tab VĐV TC-DIVSHARE-08)
  - Files: sửa `lib/features/tournament/screens/tournament_management_hub_screen.dart:52-75,412-452`; tạo `test/features/tournament_management_hub_division_share_test.dart`; thêm TC-DIVSHARE-08 vào `test/features/athletes_tab_actions_test.dart`
  - Giao: `String? _divisionId; void _selectDivision(String id)` · Nhận: `BracketViewScreen.onDivisionChanged` (1.1), `OrganizerOpsScreen.selectedDivisionId` (2.1), `TournamentManagementAthletesTab.selectedDivisionId/onDivisionChanged` (3.1)
  - Chủ file chung: 4.1 giữ `tournament_management_hub_screen.dart`
  - Phụ thuộc: sau 1.1, 2.1, 3.1

## 5. Kết quả công khai

- [x] 5.1 Tab Kết quả của màn giải công khai thay danh sách chọn tự dựng bằng `DivisionStrip` (đúng phạm vi proposal; tab Đội và Bảng đấu công khai vẫn dùng accordion vì nội dung hiện ngay dưới từng nội dung, tab Trực tiếp có bộ chọn riêng, để ngoài change này). Tiêu chí: `flutter test --no-pub test/features/tournament_intro_division_strip_test.dart` → exit 0 (đỏ trước, xanh sau; cùng `tournament_intro_access_test` 5/5)
  - Files: sửa `lib/features/tournament/screens/tournament_intro_screen.dart` (thêm `_buildResultsDivisionStrip`, dùng ở tab Kết quả); tạo `test/features/tournament_intro_division_strip_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 5.1 giữ `tournament_intro_screen.dart`
  - Phụ thuộc: không

## 6. Kiểm chung

- [x] 6.1 Phân tích tĩnh và test liên quan. Tiêu chí: `flutter analyze --no-pub <các file đã sửa>` → exit 0; `flutter test --no-pub test/design test/features/division_strip_test.dart` + các test ở 1–5 → exit 0; cổng cloud của `merge-lane` xanh (đã chạy 32 file test liên quan: 325/325 xanh; cổng cloud chạy ở bước gộp)
  - Files: không sửa thêm
  - Giao: (không) · Nhận: kết quả 1–5
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.1–5.1
