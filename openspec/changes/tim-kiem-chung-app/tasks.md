## 1. Shared component

- [x] 1.1 `SearchFilterBar`, `SearchFilterToggle`, per-tab state, accent-insensitive match. Tiêu chí: `flutter test --no-pub test/shared/search_filter_bar_test.dart` → exit 0
  - Files: thêm `lib/shared/widgets/search_filter_bar.dart`, ARB keys; test `test/shared/search_filter_bar_test.dart`

## 2. Wire into tabs

- [x] 2.1 Lịch grid: icon, bar, dim non-matching cards, print into ⋯ menu. Tiêu chí: `flutter test --no-pub test/features/schedule_search_test.dart test/features/schedule_print_test.dart` → exit 0
  - Files: sửa `tournament_schedule_court_grid.dart`, `schedule_grid.dart`; test `test/features/schedule_search_test.dart`
- [x] 2.2 VĐV tab. Tiêu chí: `flutter test --no-pub test/features/athletes_search_test.dart` → exit 0
  - Files: sửa `tournament_management_athletes_tab.dart`, `tournament_management_people_section.dart`; test `test/features/athletes_search_test.dart`
