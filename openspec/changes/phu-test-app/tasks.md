# Tasks — phu-test-app

Tiêu chí chung: lệnh hẹp `flutter test --no-pub <file>` exit 0; trước PR `dart analyze <file test thêm>` exit 0.

- [x] T1 ApiCommunityRepository (0% → parse/lọc/phân trang/lỗi)
  Files: test/data/api_community_repository_test.dart, test/support/fake_api_adapter.dart
  Tiêu chí: `flutter test --no-pub test/data/api_community_repository_test.dart`
  Phụ thuộc: không
- [x] T2 ApiCommunitySocialRepository (0%)
  Files: test/data/api_community_social_repository_test.dart
  Tiêu chí: `flutter test --no-pub test/data/api_community_social_repository_test.dart`
- [x] T3 ApiSocialSessionRepository + SocialSessionModel (31%/45%)
  Files: test/data/api_social_session_repository_test.dart, test/data/models/social_session_model_test.dart
- [x] T4 ApiTeamRepository (25%)
  Files: test/data/api_team_repository_test.dart
- [x] T5 ApiTournamentRepository phần còn thiếu (46%)
  Files: test/data/api_tournament_repository_gaps_test.dart
- [x] T6 ApiMatchRepository phần còn thiếu (59%)
  Files: test/data/api_match_repository_gaps_test.dart
- [x] T7 Notifier: lite_management_notifier, social_provider (score_panel_notifier bỏ qua: đã dày, phần hổng là sync/timer)
  Files: test/providers/*_gaps_test.dart
- [ ] T8 Đo lại, review, handoff, PR
  Files: openspec/changes/phu-test-app/{coverage-after.md,handoff.md,findings.md}
