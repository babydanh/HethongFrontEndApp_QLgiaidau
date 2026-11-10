## Context

- Hộp thoại `ClubStandaloneMatchDialog` hiện bắt buộc 2v2 (`_canSubmit` đòi 2/2) và gửi `matchType: sideAList.length == 1 ? 'SINGLES' : 'DOUBLES'`, tức Đơn không bao giờ tạo được. Dialog dùng chung cho kèo CLB (`communityId`) và kèo cá nhân (`socialSessionId`, chủ kèo mới được tạo).
- `SocialMatchTab` đã lọc người tham gia đã duyệt, bỏ khách (`isGuest`) và đổi sang `CommunityMemberModel` (`_preselectedMembers`), đúng danh sách cần cho bracket.
- Route mở giải đã có `/tournaments/:id` (`lib/core/router/app_router.dart:512`).

## Decisions

1. **Bracket nằm trong cùng hộp thoại**, tách thành widget `SocialBracketForm` ở file mới để dialog (806 dòng) không phình thêm và để dễ test.
2. **Quyền hiện Thể thức**: tham số mới `allowBracket` (mặc định `false`) của `ClubStandaloneMatchDialog.show`; `SocialMatchTab` truyền `_owner.isPersonalSession`. Luồng CLB không truyền nên không đổi.
3. **Đơn/Đôi**: state `_matchType` (`'SINGLES' | 'DOUBLES'`, mặc định `'DOUBLES'`), đổi loại thì xoá hai đội đã chọn; `_canSubmit` so với số người mong đợi (1 hoặc 2 mỗi bên).
4. **Điều hướng sau khi tạo**: bắt `GoRouter.of(context)` trước khi đóng dialog, rồi `router.push('/tournaments/$id')`; 409 có `tournamentId` thì đi tới id cũ.
5. **Logic thuần** (`canSubmitBracket`, `bracketTypes`) để ở `social_bracket_rules.dart`, kiểm bằng test không cần widget.

## Risks / Assumptions

- **Va chạm file**: lane `tran-dau-buoi-ca-nhan-app` đang sửa `club_standalone_match_dialog.dart` và `social_match_tab.dart` (nhiều đoạn). Trước khi apply: `git fetch`; nếu lane đó đã vào `main` thì rebase nhánh này lên; nếu chưa thì giữ phần sửa ở hai file này nhỏ nhất có thể (phần lớn code nằm trong file mới) và báo người dùng thứ tự gộp.
- Ngưỡng tối thiểu phía App là thận trọng (Đơn ≥ 2, Đôi ≥ 4 và chẵn); Backend là nguồn quyết định, lỗi 400 hiện nguyên thông báo.
- Tạo giải Lite đòi email đã xác minh nên chủ kèo chưa xác minh sẽ nhận 403; hiện thông báo của server.
- Route `/tournaments/:id` giả định mở đúng màn giải Lite vừa tạo; kiểm trên máy thật sau khi Backend lên staging.
- Mọi phép đo giao diện máy thật qua app chung `app-run.py`, không dựng `flutter run` riêng.
