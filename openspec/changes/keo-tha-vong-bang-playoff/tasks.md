## 1. Vòng bảng: cuộn, đổi thứ tự, thả về Chưa xếp

- [x] 1.1 `GroupStageView` tự cuộn khi kéo, thả vào vị trí trong bảng, thả về "Chưa xếp". Tiêu chí: `flutter test --no-pub test/features/group_stage_view_test.dart` → exit 0 (TC-GROUP-DND-13..15)
  - Files: sửa `lib/features/bracket/widgets/group_stage_view.dart`; test `test/features/group_stage_view_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 1.1 giữ `group_stage_view.dart`
  - Phụ thuộc: không

## 2. Nhãn hạt giống ở Playoff

- [x] 2.1 Thuật toán nhãn, repository `updateSeedOrder`, `PlayoffSeedHost`, nhãn kéo-thả trên bảng playoff, nối vào trang chi tiết và màn quản lý, l10n vi/en. Tiêu chí: `flutter test --no-pub test/features/playoff_seed_labels_test.dart test/features/public_bracket_view_test.dart test/features/playoff_double_elim_view_test.dart` → exit 0 (TC-SEEDLABEL-01..18)
  - Files: tạo `lib/features/bracket/utils/knockout_seed_labels.dart`, `lib/features/bracket/widgets/playoff_seed_labels.dart`; sửa `lib/features/bracket/widgets/playoff_bracket_board.dart`, `playoff_double_elim_view.dart`, `public_bracket_view.dart`, `lib/features/bracket/screens/bracket_view_screen.dart`, `lib/features/tournament/screens/tournament_intro_screen.dart`, `lib/domain/repositories/tournament_repository.dart`, `lib/data/repositories/api/api_tournament_repository.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/features/playoff_seed_labels_test.dart`
  - Giao: `ITournamentRepository.updateSeedOrder(String tournamentId, {required String divisionId, required String stageId, required List<Map<String, dynamic>> slotOrder}) → Future<void>` · Nhận: (không)
  - Chủ file chung: 2.1 giữ các file trên
  - Phụ thuộc: không

## 3. Kiểm tra cuối

- [x] 3.1 `flutter gen-l10n`, `flutter analyze --no-pub lib/features/bracket lib/features/tournament/screens/tournament_intro_screen.dart` và các test trên. Tiêu chí: analyze → exit 0; test → exit 0
  - Files: (không sửa file)
  - Phụ thuộc: sau 2.1
