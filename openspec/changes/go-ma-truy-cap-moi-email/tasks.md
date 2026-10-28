## 1. Hàm thuần dòng phân quyền

- [x] 1.1 Viết test đỏ rồi hàm `buildPermissionRows` gộp staff + referee thành dòng thống nhất, gán hành động theo trạng thái. Tiêu chí: `flutter test --no-pub test/features/tournament/utils/permission_rows_test.dart` → exit 0 (test phải đỏ trước khi có hàm)
  - Files: tạo `lib/features/tournament/utils/permission_rows.dart`; test `test/features/tournament/utils/permission_rows_test.dart`
  - Giao: `enum RefereeAction { none, revoke, resend }`; `class PermissionRow { String name; String email; String userId; String role; String? status; String? refereeId; RefereeAction action; }`; `List<PermissionRow> buildPermissionRows(List<Map<String, dynamic>> staff, List<Map<String, dynamic>> referees)` · Nhận: (không)
  - Chủ file chung: 1.1 giữ cả hai file
  - Phụ thuộc: (không)
  - Ca test: `INVITED → revoke`, `DECLINED → resend`, `ACCEPTED → none`, trạng thái lạ → `none`; dòng staff lấy `role` `CO_ORGANIZER`/`SPECTATOR`, dòng referee có `role = REFEREE`; danh sách rỗng → rỗng; map thiếu tên → tên rỗng không ném lỗi

## 2. Chuỗi hiển thị

- [x] 2.1 Thêm key mới vào cả hai ARB (khối "Mời qua email", chip lọc Tất cả, nút Gửi lại, Thu hồi, hỏi xác nhận Gửi lại/Thu hồi, thông báo đã gửi lại/đã thu hồi), rồi sinh lại. Tiêu chí: `flutter gen-l10n` → exit 0 và `flutter analyze --no-pub lib/l10n` → exit 0
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; sinh `lib/l10n/app_localizations*.dart` (không sửa tay)
  - Giao: các getter l10n mới cho 3.1 · Nhận: (không)
  - Chủ file chung: 2.1 giữ cả hai ARB
  - Phụ thuộc: (không)

## 3. Màn Phân quyền mời qua email

- [x] 3.1 Viết widget test đỏ rồi làm lại `_TournamentPermissions`: một ô email + chọn vai trò, danh sách có chip lọc, dòng trọng tài có Gửi lại/Thu hồi có xác nhận, chống bấm đúp, lỗi API không lộ chi tiết. Tiêu chí: `flutter test --no-pub test/features/tournament/permissions_invite_section_test.dart` → exit 0 (đỏ trước) và `flutter analyze --no-pub lib/features/tournament` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_people_section.dart:395-814` (khối `_TournamentPermissions`, `_PersonRow` ~1080); test `test/features/tournament/permissions_invite_section_test.dart`
  - Giao: (không) · Nhận: `buildPermissionRows`/`PermissionRow` từ 1.1, getter l10n từ 2.1
  - Chủ file chung: 3.1 giữ `tournament_management_people_section.dart`
  - Phụ thuộc: sau 1.1, 2.1
  - Ca test: mời trọng tài gọi `addReferee` đúng một lần; email sai không gọi API; Gửi lại gọi `addReferee` cùng email; Thu hồi gọi `removeReferee` đúng `refereeId`; dòng `ACCEPTED` không có hai nút; repository ném lỗi thì danh sách giữ nguyên và nút mở lại; viewport 320 không overflow

## 4. Gỡ màn Mã truy cập

- [x] 4.1 Xoá màn, notifier, route, mục menu, `presenceCountProvider` và test dựng màn token; sửa test overflow giữ lại ca bốc thăm. Tiêu chí: `flutter analyze --no-pub lib/features/tournament lib/core/router lib/providers` → exit 0 và `flutter test --no-pub test/features/mobile_row_overflow_test.dart` → exit 0
  - Files: xoá `lib/features/tournament/screens/token_management_screen.dart`, `lib/providers/token_management_notifier.dart`; sửa `lib/core/router/app_router.dart` (import dòng 23, route ~330-336 và ~462-470), `lib/features/tournament/screens/tournament_management_section_screen.dart` (enum dòng 37, nhánh 107-110), `lib/features/tournament/screens/tournament_management_hub_screen.dart` (import dòng 13, danh sách 63, nhánh 527-532, chi tiết 825-830), `lib/providers/query_providers.dart` (khối `presenceCountProvider` ~128), `test/features/mobile_row_overflow_test.dart` (bỏ `_TokenNotifier`, import token, ca đầu)
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 4.1 giữ `app_router.dart`, hub screen, section screen; không đụng `people_section.dart` (của 3.1) và không đụng ARB (của 2.1)
  - Phụ thuộc: độc lập với 1.1–3.1, nhưng làm sau 3.1 để một lượt analyze bắt hết
  - Trước khi xoá: ripwire `uses` cho `presenceCountProvider` (phải chỉ còn `token_management_screen.dart`); sau khi sửa: `edit_check`; `ITokenRepository`/`TokenModel` KHÔNG xoá

## 5. Kiểm tổng

- [ ] 5.1 Typecheck và chạy đúng các test liên quan do ripwire `affected` chọn; `git diff -U0` giải thích mọi dòng xoá; `flutter-reviewer` không còn P0/P1. Tiêu chí: `flutter analyze --no-pub lib/features/tournament lib/core/router lib/providers lib/l10n` → exit 0 và `flutter test --no-pub` trên các file `affected` chọn → exit 0
  - Files: (không sửa mới)
  - Phụ thuộc: sau 3.1, 4.1
