## 3. App: Đơn/Đôi mặc định Đôi + chọn Thể thức Bracket (chuỗi tuần tự, một worktree `social-the-thuc-bracket-app`)

Quy ước (AGENTS.md của App): chuỗi hiển thị có key ở cả `app_vi.arb` và `app_en.arb` rồi `flutter gen-l10n`, không sửa tay `app_localizations*.dart`; gọi API qua `lib/data/repositories/api/api_*.dart`; không thêm package. Test một file: `flutter test --no-pub <file>`; phân tích tĩnh chỉ trên thư mục đã sửa. Worktree mới thiếu `.env`: nếu test cần thì dùng `copy-local-env.py`, không đọc nội dung.

- [x] 3.1 Model, repository và gọi API tạo bracket. Tiêu chí: `flutter test --no-pub test/data/api_social_session_bracket_test.dart` → exit 0
  - Files: tạo `lib/data/models/social_bracket_model.dart`; sửa `lib/data/models/social_session_model.dart` (thêm `bracketTournamentId`); sửa `lib/domain/repositories/social_session_repository.dart`; sửa `lib/data/repositories/api/api_social_session_repository.dart`; tạo `test/data/api_social_session_bracket_test.dart` (theo mẫu `test/data/api_club_match_session_standalone_owner_test.dart`)
  - Giao: `class SocialBracketResult { final String tournamentId; final String bracketType; final String matchType; final int participantCount; factory SocialBracketResult.fromJson(Map<String, dynamic> json); }`; `SocialSessionModel.bracketTournamentId: String?` (đọc từ khoá `bracketTournamentId`, thiếu thì `null`); `Future<SocialBracketResult> ISocialSessionRepository.createBracket(String sessionId, {required String bracketType, required String matchType, required List<String> participantUserIds})` (POST `/social-sessions/{sessionId}/bracket`, bóc `data`; 409 có `tournamentId` thì ném `SocialBracketExistsException(String tournamentId)` khai báo trong `social_bracket_model.dart`) · Nhận: hợp đồng Backend 1.4 (route, body, response, mã lỗi); đối chiếu `openapi.json` mới
  - Chủ file chung: 3.1 giữ `social_session_model.dart`, `social_session_repository.dart`, `api_social_session_repository.dart`
  - Phụ thuộc: sau Backend 1.4
  - Test (viết trước, đỏ): TC-SOCIAL-BRACKET-APP-01 parse 201; 02 body gửi đúng ba khoá; 03 409 ném `SocialBracketExistsException` mang `tournamentId`; 04 `SocialSessionModel` thiếu `bracketTournamentId` ra `null`

- [x] 3.2 Chuỗi hiển thị vi/en. Tiêu chí: `flutter gen-l10n` → exit 0 và `grep -c "socialBracket_" lib/l10n/app_vi.arb lib/l10n/app_en.arb` hai file cùng số dòng
  - Files: sửa `lib/l10n/app_vi.arb` (cạnh `club_createMatchStandalone`, dòng ~13); sửa `lib/l10n/app_en.arb`
  - Giao: key `socialBracket_formatLabel`, `socialBracket_formatSingle`, `socialBracket_formatBracket`, `socialBracket_matchSingles`, `socialBracket_matchDoubles`, `socialBracket_typeSingleElimination`, `socialBracket_typeDoubleElimination`, `socialBracket_typeRoundRobin`, `socialBracket_typeGroupKnockout`, `socialBracket_players`, `socialBracket_selectAll`, `socialBracket_needMore` (tham số `count`), `socialBracket_submit`, `socialBracket_view`, `socialBracket_error` · Nhận: (không)
  - Chủ file chung: 3.2 giữ hai file `.arb`
  - Phụ thuộc: không

- [x] 3.3 Logic thuần và form Bracket. Tiêu chí: `flutter test --no-pub test/features/social/social_bracket_rules_test.dart` → exit 0 và `flutter analyze --no-pub lib/features/social/widgets/match_tab` → exit 0
  - Files: tạo `lib/features/social/widgets/match_tab/social_bracket_rules.dart`; tạo `lib/features/social/widgets/match_tab/social_bracket_form.dart`; tạo `test/features/social/social_bracket_rules_test.dart`
  - Giao: `const List<String> socialBracketTypes = ['SINGLE_ELIMINATION', 'DOUBLE_ELIMINATION', 'ROUND_ROBIN', 'GROUP_STAGE_KNOCKOUT']`; `bool canSubmitBracket({required String matchType, required int selectedCount, required bool busy})` (singles ≥ 2; doubles ≥ 4 và chẵn); `class SocialBracketForm extends ConsumerStatefulWidget { const SocialBracketForm({super.key, required this.sessionId, required this.members, required this.matchType, required this.onDone}); final String sessionId; final List<CommunityMemberModel> members; final String matchType; final void Function(String tournamentId) onDone; }` (cờ `_busy` chặn bấm đúp; bắt `SocialBracketExistsException` thì gọi `onDone` với id cũ; lỗi khác hiện SnackBar thông báo của server) · Nhận: 3.1 (`createBracket`, `SocialBracketExistsException`), 3.2 (key l10n)
  - Chủ file chung: 3.3 giữ ba file mới
  - Phụ thuộc: sau 3.1, 3.2
  - Test (viết trước, đỏ): TC-SOCIAL-BRACKET-APP-05 singles 2 hợp lệ, 1 không; 06 doubles 4 hợp lệ, 3 và 5 không; 07 `busy` chặn; 08 bốn loại bracket đúng tên khoá Backend

- [x] 3.4 Hộp thoại: Đơn/Đôi mặc định Đôi và Thể thức. Tiêu chí: `flutter analyze --no-pub lib/features/community/widgets` → exit 0 và `flutter test --no-pub test/data/api_club_match_session_standalone_owner_test.dart` → exit 0 (không vỡ test cũ)
  - Files: sửa `lib/features/community/widgets/club_standalone_match_dialog.dart:15-60` (tham số `allowBracket`), `:149-154` (`_canSubmit` theo `_matchType`), `:176` (`matchType: _matchType`), `:271-` (chèn bộ chọn Đơn/Đôi và Thể thức, nhúng `SocialBracketForm`)
  - Giao: `ClubStandaloneMatchDialog.show(..., bool allowBracket = false)`; hộp thoại gửi `matchType` đúng lựa chọn, đổi loại thì xoá hai đội; ở chế độ Bracket thành công thì `Navigator.pop` rồi `router.push('/tournaments/$id')` với `GoRouter` bắt trước khi đóng · Nhận: 3.3 (`SocialBracketForm`, `canSubmitBracket`), 3.2 (key l10n)
  - Chủ file chung: 3.4 giữ `club_standalone_match_dialog.dart`. Va chạm với lane `tran-dau-buoi-ca-nhan-app`: xem `design.md`, `git fetch` và rebase trước khi sửa
  - Phụ thuộc: sau 3.3

- [x] 3.5 Màn Trận đấu của kèo: bật Bracket cho chủ kèo cá nhân và nút Xem bracket. Tiêu chí: `flutter analyze --no-pub lib/features/social` → exit 0
  - Files: sửa `lib/features/social/widgets/match_tab/social_match_tab.dart:30-42` (thêm `bracketTournamentId`), `:150-157` (truyền `allowBracket: _owner.isPersonalSession`) và vùng hiển thị danh sách trận (nút Xem bracket); sửa `lib/features/social/screens/social_detail_screen.dart:362` (truyền `bracketTournamentId: session.bracketTournamentId`)
  - Giao: `SocialMatchTab({ ..., String? bracketTournamentId })`; nút "Xem bracket" gọi `context.push('/tournaments/$bracketTournamentId')` khi có giá trị · Nhận: 3.4 (`allowBracket`), 3.1 (`bracketTournamentId`), 3.2 (key `socialBracket_view`)
  - Chủ file chung: 3.5 giữ `social_match_tab.dart` và `social_detail_screen.dart`. Cùng cảnh báo va chạm lane `tran-dau-buoi-ca-nhan-app`
  - Phụ thuộc: sau 3.4

- [x] 3.6 Kiểm tra cuối. Tiêu chí: `flutter analyze --no-pub lib/features/social lib/features/community/widgets lib/data lib/domain` → exit 0; `flutter test --no-pub test/data/api_social_session_bracket_test.dart test/features/social/social_bracket_rules_test.dart test/data/api_club_match_session_standalone_owner_test.dart` → exit 0; CI `ci.yml` xanh sau khi đẩy nhánh
  - Files: (không sửa file)
  - Giao: (không) · Nhận: toàn bộ 3.1 đến 3.5
  - Chủ file chung: không
  - Phụ thuộc: sau 3.1 đến 3.5. Sau khi Backend lên staging, kiểm tay trên máy thật qua app chung `app-run.py`: mặc định Đôi, tạo bracket, mở được màn giải

  - Ghi chú sai lệch so với plan: thêm khoá l10n phụ; thêm `onBracketCreated`; Đơn/Đôi mặc định Đôi áp cho mọi nơi gọi hộp thoại; thêm `_refreshSession`; thêm test TC-09..13; `flutter analyze` cả thư mục còn lỗi cũ không thuộc phạm vi (exit 1), file đổi sạch; nhánh dựng từ origin/main.
