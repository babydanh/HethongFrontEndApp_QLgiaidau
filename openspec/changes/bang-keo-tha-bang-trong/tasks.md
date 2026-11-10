## 1. Bảng trống và khu Chưa xếp

- [x] 1.1 `GroupStageView` hiện thẻ trống cho bảng config chưa có đội, và khu "Chưa xếp" kéo được; màn quản lý truyền danh sách đội chưa xếp. Tiêu chí: `flutter test --no-pub test/features/group_stage_view_test.dart test/features/public_bracket_view_test.dart test/features/organizer_bracket_inline_test.dart` → exit 0 (TC-GROUP-DND-10..12)
  - Files: sửa `lib/features/bracket/widgets/group_stage_view.dart`, `lib/features/bracket/widgets/public_bracket_view.dart`, `lib/features/bracket/screens/bracket_view_screen.dart:742-790`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/features/group_stage_view_test.dart`, `test/features/public_bracket_view_test.dart`, `test/features/organizer_bracket_inline_test.dart`
  - Giao: `GroupStageView(unassignedTeams: List<Standing>)` (mặc định rỗng) · Nhận: `GroupStageConfig.unassignedParticipantIds`, `moveParticipant`
  - Chủ file chung: 1.1 giữ cả các file trên
  - Phụ thuộc: không

## 2. Bỏ icon cài đặt

- [x] 2.1 Bỏ icon `bracket-mgmt-manage` và tham số `onManageDivisions` (bar, màn, hub) cùng key `bracketMgmt_manageTooltip`. Tiêu chí: `flutter test --no-pub test/features/bracket_management_bar_test.dart test/features/bracket_management_bar_compact_test.dart test/features/tournament_management_hub_screen_test.dart` → exit 0 (TC-BRACKET-MGMT-05 đổi thành kiểm không có icon)
  - Files: sửa `lib/features/bracket/widgets/bracket_management_bar.dart`, `lib/features/bracket/screens/bracket_view_screen.dart:57,79,692`, `lib/features/tournament/screens/tournament_management_hub_screen.dart:550`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/features/bracket_management_bar_test.dart`, `test/features/bracket_management_bar_compact_test.dart`, `test/features/tournament_management_hub_screen_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 2.1 chỉ sửa dòng `onManageDivisions` và key tooltip trong các file dùng chung với 1.1
  - Phụ thuộc: sau 1.1

## 3. Kiểm tra cuối

- [x] 3.1 `flutter gen-l10n`, `flutter analyze --no-pub lib/features/bracket lib/features/tournament` và các test trên. Tiêu chí: analyze → exit 0; test → exit 0
  - Files: (không sửa file)
  - Phụ thuộc: sau 2.1
