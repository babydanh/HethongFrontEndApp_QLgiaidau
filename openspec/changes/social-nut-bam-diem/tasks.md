## 1. Bấm điểm trong tab Trận đấu

- [x] 1.1 Test đỏ rồi sửa `social_match_tab.dart` + i18n (TC-SOCIAL-SCORE-01..07). Tiêu chí: `flutter test --no-pub test/features/social/social_match_tab_test.dart` xanh
  - Files: sửa `lib/features/social/widgets/match_tab/social_match_tab.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, `test/features/social/social_match_tab_test.dart`
  - Phụ thuộc: (không)
- [x] 1.2 Cập nhật E2E TC-SOCIAL-APP-11 (thẻ có nút Bấm điểm). Tiêu chí: `flutter analyze --no-pub integration_test` sạch; chạy cloud khi cần
  - Files: sửa `integration_test/social_run_journey_test.dart`
  - Phụ thuộc: sau 1.1
