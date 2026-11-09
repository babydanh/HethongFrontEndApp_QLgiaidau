# Tasks

## 1. Điều chỉnh dialog CLB để nhận danh sách người chọn trước (tham số tùy chọn)

- [x] 1.1 Thêm tham số tùy chọn `preselectedMembers` (mặc định `null` = hành vi cũ tự load toàn bộ CLB) vào `ClubStandaloneMatchDialog`. Tiêu chí: `flutter analyze --no-pub lib/features/community/widgets/club_standalone_match_dialog.dart` exit 0
  - Files: sửa `lib/features/community/widgets/club_standalone_match_dialog.dart` (constructor + nơi load danh sách thành viên, giữ nguyên `_cycleMemberTeam`/`_canSubmit`)
  - Giao: `ClubStandaloneMatchDialog({..., List<ClubMember>? preselectedMembers})` cho 3.1 — Nhận: không
  - Chủ file chung: 1.1 giữ file này
  - Phụ thuộc: không

## 2. Widget tab Trận đấu mới

- [x] 2.1 Tạo widget danh sách trận theo `communityId` + nút "Tạo trận đấu", trạng thái rỗng khi chưa có trận hoặc chưa đủ người tham gia đã duyệt. Tiêu chí: `flutter analyze --no-pub lib/features/social/widgets/match_tab` exit 0
  - Files: tạo `lib/features/social/widgets/match_tab/social_match_tab.dart`
  - Giao: `SocialMatchTab({required String communityId, required List<SocialParticipant> approvedParticipants})` cho 3.1 — Nhận: `api_club_match_session_repository.dart` (đọc, không sửa chữ ký có sẵn)
  - Chủ file chung: 2.1 giữ file này
  - Phụ thuộc: sau 1.1

- [x] 2.2 Nối nút "Tạo trận đấu" trong `social_match_tab.dart` mở `ClubStandaloneMatchDialog(preselectedMembers: approvedParticipants)`, và nút nhập kết quả mở `ClubStandaloneMatchResultDialog`. Tiêu chí: `flutter analyze --no-pub lib/features/social/widgets/match_tab` exit 0
  - Files: sửa `lib/features/social/widgets/match_tab/social_match_tab.dart`
  - Giao: không — Nhận: `ClubStandaloneMatchDialog` từ 1.1
  - Chủ file chung: 2.2 tiếp tục giữ file này
  - Phụ thuộc: sau 2.1

## 3. Gắn tab vào màn chi tiết buổi Social

- [x] 3.1 Thêm tab "Trận đấu" vào `TabController` của `social_detail_screen.dart`, chỉ hiện khi `session.communityId` khác rỗng, đặt sau tab Người tham gia. Tiêu chí: `flutter analyze --no-pub lib/features/social/screens/social_detail_screen.dart` exit 0
  - Files: sửa `lib/features/social/screens/social_detail_screen.dart:233-354` (khai báo tab length + `TabBarView` children)
  - Giao: không — Nhận: `SocialMatchTab` từ 2.2
  - Chủ file chung: 3.1 giữ `social_detail_screen.dart`
  - Phụ thuộc: sau 2.2

## 4. i18n

- [x] 4.1 Thêm key cho nhãn tab, nút tạo trận, trạng thái rỗng, lỗi chưa đủ người/hòa điểm. Tiêu chí: `flutter gen-l10n` exit 0, không lệch key giữa 2 file
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`
  - Giao: không — Nhận: không
  - Chủ file chung: 4.1 giữ 2 file này
  - Phụ thuộc: song song được với nhóm 1-3

## 5. Test

- [x] 5.1 Widget test: tab Trận đấu ẩn/hiện đúng theo `communityId`, trạng thái rỗng khi thiếu người tham gia đã duyệt. Tiêu chí: `flutter test --no-pub test/features/social/social_match_tab_test.dart` exit 0
  - Files: tạo `test/features/social/social_match_tab_test.dart`
  - Giao: không — Nhận: không
  - Chủ file chung: 5.1 giữ file test này
  - Phụ thuộc: sau 3.1

## 6. Kiểm tra tổng thể trước khi báo xong

- [x] 6.1 Typecheck + test liên quan toàn bộ thay đổi. Tiêu chí: `flutter analyze --no-pub lib/features/social lib/features/community/widgets/club_standalone_match_dialog.dart && flutter test --no-pub test/features/social/social_match_tab_test.dart` tất cả exit 0
  - Files: không tạo/sửa file mới
  - Giao: không — Nhận: không
  - Chủ file chung: không
  - Phụ thuộc: sau tất cả nhóm 1-5

## Workflow follow-up

- CI (`.github/workflows/ci.yml`) tự chạy `flutter analyze` + full `flutter test` trên nhánh này khi push, `.env` tự copy từ `.env.example` — không cần chạy full suite ở máy.
- Review theo vai trò (`reviewer`, `flutter-reviewer`) trước khi gộp qua `merge-lane.py <worktree> --check "python C:/Users/GIGABYTE/.omp/scripts/openspec-gate.py"`.
- Archive change này (`openspec archive them-tab-tao-tran-trong-social`) sau khi đã gộp vào `main`.
- Worktree này chưa có `.env`: nếu cần chạy `flutter test` cục bộ (không chỉ chờ CI), phải hỏi người dùng trước khi copy/chạy, theo luật boundary `.env` của repo.
