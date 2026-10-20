## 1. Nền tảng

- [x] 1.1 Thêm `AppConstants.supportsSeeding` trong `lib/core/config/app_constants.dart`. Xong khi: test `AppConstants.supportsSeeding` trong `test/features/tournament/team_seed_visibility_test.dart` pass.
- [x] 1.2 Thêm `bracketType` vào `_OpsDivision` (`lib/features/organizer_ops/screens/organizer_ops_screen.dart`). Xong khi: `flutter analyze --no-pub lib/features/organizer_ops/screens` không có lỗi mới.

## 2. Hiển thị seed

- [x] 2.1 Gate `showSeed` trong `TournamentTeamCard`, `TeamsTab` (tham số `divisions`) và `tournament_intro_screen.dart`. Xong khi: widget test "ẩn seed ở nội dung loại trực tiếp, hiện ở nội dung vòng bảng" pass.
- [x] 2.2 Gate chip seed trong `_OpsParticipantCard` theo `showSeed`. Xong khi: `flutter analyze --no-pub lib/features/organizer_ops/screens` không có lỗi mới.
- [x] 2.3 Gate `showSeed` trong `TournamentTeamSheet`. Xong khi: `flutter analyze --no-pub lib/features/tournament/widgets` không có lỗi mới.

## 3. Quản lý seed và copy

- [x] 3.1 Lọc nội dung vòng bảng + loại trực tiếp trước `_TournamentSeedsSection` trong `tournament_management_divisions_section.dart`. Xong khi: `flutter analyze --no-pub lib/features/tournament/screens` không có lỗi mới.
- [x] 3.2 Sửa copy ở `app_vi.arb` và `app_en.arb` (giữ nguyên key), chạy `flutter gen-l10n`. Xong khi: `flutter gen-l10n` exit 0 và diff `lib/l10n/app_localizations*.dart` chỉ chứa các dòng copy đã đổi.

## 4. Kiểm chứng

- [x] 4.1 `flutter analyze --no-pub lib/core/config lib/features/tournament lib/features/organizer_ops lib/l10n test/features/tournament`. Xong khi: không có lỗi mới so với origin/main. Kết quả: 6 mục info `curly_braces_in_flow_control_structures`, đều ở dòng code cũ của `tournament_management_divisions_section.dart` (58, 60, 724, 773, 780, 788), không có error hay warning.
- [x] 4.2 `flutter test --no-pub test/features/tournament/team_seed_visibility_test.dart` và 10 file test liên quan (intro screen, organizer ops, tournament_teams_inline_layout). Xong khi: pass. Kết quả: All tests passed (+141). Worktree có `.env` tạo từ `.env.example`, gitignored, theo chỉ thị của người dùng.
