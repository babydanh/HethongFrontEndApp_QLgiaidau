## 1. App giải tôi tổ chức
- [x] 1.1 Provider + section + gắn vào hồ sơ (TC-PROFILE-ORG-01..06). Tiêu chí: `flutter test --no-pub test/profile/organized_tournaments_section_test.dart` → exit 0
  - Files: `lib/providers/organized_tournaments_provider.dart`, `lib/features/profile/widgets/organized_tournaments_section.dart`, `lib/features/profile/screens/profile_screen.dart`
- [x] 1.2 Tham số `role` ở repository + chuỗi l10n. Tiêu chí: `flutter test --no-pub test/data/api_tournament_repository_gaps_test.dart` → exit 0
  - Files: `tournament_repository.dart`, `api_tournament_repository.dart`, `app_vi.arb`, `app_en.arb`, file l10n sinh
