## 1. Bộ widget chung

- [x] 1.1 Viết test đỏ rồi thêm widget Lavish chung. Tiêu chí: `flutter test --no-pub test/tournament/lavish_kit_extras_test.dart` → exit 0
  - Files: tạo `lib/features/tournament/widgets/lavish_kit_extras.dart`, `test/tournament/lavish_kit_extras_test.dart`; thêm key l10n dùng chung vào `lib/l10n/app_vi.arb`, `app_en.arb`
  - Giao: `LavishScaffold({required String title, required Widget body, List<Widget> actions=const[], Widget? bottom, VoidCallback? onBack})`, `LavishTextField({required String label, TextEditingController? controller, String? errorText, bool obscure=false, TextInputType? keyboardType, int maxLines=1, int? maxLength, Widget? trailing, ValueChanged<String>? onChanged, bool enabled=true})`, `LavishStickyBar({required String label, required VoidCallback? onPressed, bool busy=false, String? error})`, `LavishStat({required String label, required String value, LavishTone tone=LavishTone.neutral})`, `LavishStatGrid({required List<LavishStat> items})`, `LavishEmptyState({required IconData icon, required String title, String? action, VoidCallback? onAction})`, `LavishErrorState({required VoidCallback onRetry, String? message})`, `LavishRowSkeleton({int count=5})`
  - Phụ thuộc: (không)

## 2. Màn và logic (song song theo file)

- [x] 2.1 Đổi mật khẩu: vẽ lại + đúng route. Tiêu chí: `flutter test --no-pub test/profile/change_password_screen_test.dart` → exit 0
  - Files: sửa `lib/features/profile/screens/change_password_screen.dart`; tạo `test/profile/change_password_screen_test.dart`
  - Phụ thuộc: sau 1.1
- [x] 2.2 Báo cáo: vẽ lại danh sách + sửa `ReportSheet`. Tiêu chí: `flutter test --no-pub test/reports` → exit 0
  - Files: sửa `lib/features/reports/screens/my_reports_screen.dart`, `lib/shared/widgets/report_sheet.dart`, `lib/features/community/social/widgets/community_post_card.dart` (chỉ `targetType`); test trong `test/reports/`
  - Phụ thuộc: sau 1.1
- [x] 2.3 Lịch sử ELO: vẽ lại, ELO thật, hiện lỗi. Tiêu chí: `flutter test --no-pub test/rankings` → exit 0
  - Files: sửa `lib/features/rankings/screens/elo_history_screen.dart`, `lib/providers/ranking_provider.dart`, `lib/core/router/app_router.dart` (chỉ dòng `currentElo` của route ELO); test trong `test/rankings/`
  - Chủ file chung: 2.3 giữ `app_router.dart`
  - Phụ thuộc: sau 1.1
- [x] 2.4 Thông báo: vẽ lại + gộp scope management. Tiêu chí: `flutter test --no-pub test/notification` → exit 0
  - Files: sửa `lib/features/notification/screens/notification_screen.dart`, `lib/providers/notification_provider.dart`, `lib/data/repositories/api/api_notification_repository.dart`; test trong `test/notification/`
  - Phụ thuộc: sau 1.1
- [x] 2.5 Hồ sơ: vẽ lại + sửa kết bạn. Tiêu chí: `flutter test --no-pub test/profile/profile_screen_test.dart` → exit 0
  - Files: sửa `lib/features/profile/screens/profile_screen.dart`; tạo `test/profile/profile_screen_test.dart`
  - Phụ thuộc: sau 1.1
- [x] 2.6 Cài đặt (menu): vẽ lại + đăng xuất gọi `/auth/logout`. Tiêu chí: `flutter test --no-pub test/profile/profile_settings_screen_test.dart` → exit 0
  - Files: sửa `lib/features/profile/screens/profile_settings_screen.dart`, `lib/domain/usecases/auth/clear_session_use_case.dart` hoặc nơi gọi đăng xuất; tạo test
  - Phụ thuộc: sau 1.1
- [x] 2.7 Sửa hồ sơ: vẽ lại + sửa payload. Tiêu chí: `flutter test --no-pub test/profile/edit_profile_payload_test.dart` → exit 0
  - Files: sửa `lib/features/profile/screens/settings_screen.dart`; tạo test
  - Phụ thuộc: sau 1.1
- [x] 2.8 Dashboard: vẽ lại + làm mới cả hồ sơ và xếp hạng. Tiêu chí: `flutter test --no-pub test/dashboard` → exit 0
  - Files: sửa `lib/features/dashboard/screens/dashboard_screen.dart`; test trong `test/dashboard/`
  - Phụ thuộc: sau 1.1

## 3. Kiểm tra cuối

- [ ] 3.1 Sinh l10n, analyze, test liên quan, chụp lại ảnh Android. Tiêu chí: `flutter gen-l10n && flutter analyze --no-pub lib test` → exit 0 và `related-tests` xanh
  - Phụ thuộc: sau 2.1–2.8
