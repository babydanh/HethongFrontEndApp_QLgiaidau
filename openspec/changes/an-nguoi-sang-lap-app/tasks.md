## 1. Founder visibility

- [x] 1.1 Getter `Tournament.showFounder`. Tiêu chí: `flutter test --no-pub test/domain/tournament_founder_visibility_test.dart` → exit 0
  - Files: sửa `lib/domain/entities/tournament.dart`; test `test/domain/tournament_founder_visibility_test.dart`
- [x] 1.2 Ba tab ẩn khối người sáng lập khi `!showFounder`. Tiêu chí: `flutter test --no-pub test/features/tournament_overview_content_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/intro_tab.dart`, `overview_tab.dart`, `about_tab.dart`; test `test/features/tournament_overview_content_test.dart`

## 2. Manager toggle in the hub

- [x] 2.1 Nút con mắt bật/tắt `contactInfo.hidden` ở tab Tổng quan của hub quản lý. Tiêu chí: `flutter test --no-pub test/features/tournament_overview_content_test.dart test/features/tournament_management_hub_screen_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/overview_tab.dart`, `lib/features/tournament/screens/tournament_management_hub_screen.dart`; test `test/features/tournament_overview_content_test.dart`
