## 1. Thanh tiến trình 4 bước
- [x] 1.1 Đổi `lifecycleStepIndex` và `LifecycleStepBar` sang 4 bước vòng tròn như Web; nhãn đi qua l10n vi/en. Tiêu chí: `flutter test --no-pub test/features/lifecycle_stepper_test.dart` exit 0 (viết test đỏ trước); `flutter analyze --no-pub lib/features/tournament/widgets/lifecycle_stepper.dart` không lỗi mới.
  - Files: sửa `lib/features/tournament/widgets/lifecycle_stepper.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (+ `flutter gen-l10n`), `test/features/lifecycle_stepper_test.dart`
  - Giao: `int? lifecycleStepIndex(String status)` trả -1 cho nháp, 0..3 cho 4 bước, null cho đã huỷ; `LifecycleStepBar(status:)` giữ chữ ký và key `lifecycle-step-current`
  - Chủ file chung: task này giữ `lifecycle_stepper.dart` và hai file arb
  - Phụ thuộc: không

## 2. Đầu trang
- [x] 2.1 Đưa thẻ vòng đời (thanh + nút bước) lên đầu hub; tab Cài đặt chỉ còn nhóm "Khác". Tiêu chí: `flutter test --no-pub test/features/tournament_management_hub_screen_test.dart` exit 0 (kể cả TC-APP-LIFECYCLE-04).
  - Files: sửa `lib/features/tournament/screens/tournament_management_section_screen.dart:1077-1262` (tham số `showLifecycle`), `lib/features/tournament/screens/tournament_management_hub_screen.dart:320-341, 511-521`, `test/features/tournament_management_hub_screen_test.dart:1163-1180`
  - Giao: `TournamentLifecycleCard({showLifecycle = true})`
  - Chủ file chung: task này giữ `tournament_management_section_screen.dart`
  - Phụ thuộc: 1.1
- [x] 2.2 Logo tròn đè banner, bỏ khung 4 ô số, hiện dòng Lệ phí trong Tổng quan. Tiêu chí: `flutter test --no-pub test/features/tournament_management_hub_screen_test.dart test/features/tournament_overview_content_test.dart` exit 0; `flutter analyze --no-pub lib/features/tournament` không lỗi mới.
  - Files: sửa `lib/features/tournament/widgets/tournament_management_header.dart`, `lib/features/tournament/widgets/overview_tab.dart:564-651`, `lib/features/tournament/screens/tournament_management_hub_screen.dart:320-335`, `test/features/tournament_management_hub_screen_test.dart:331-390`, `integration_test/organizer_flow_test.dart:86-91`
  - Giao: `TournamentManagementSummary` chỉ còn `tournament`, `onEditInformation`; `TournamentManagementBanner` vẽ logo
  - Chủ file chung: task này giữ `tournament_management_header.dart`, `overview_tab.dart`
  - Phụ thuộc: 2.1

## 3. Kiểm chứng
- [x] 3.1 `ripwire affected` các file đã sửa và chạy đúng test nó chọn; xem `app-run.py status`. Tiêu chí: exit 0, `errors` rỗng với nhánh `header-tong-quan-tien-trinh`; chụp màn thật khi điện thoại thức.
  - Phụ thuộc: 2.2
