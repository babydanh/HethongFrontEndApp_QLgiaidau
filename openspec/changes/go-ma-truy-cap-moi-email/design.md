## Context

App đã nối đủ API: `ITournamentManagementRepository` có `getStaff/addStaff/removeStaff/getReferees/addReferee/removeReferee` (`api_tournament_management_repository.dart:165-196`). `_TournamentPermissions` (`tournament_management_people_section.dart:395-814`) dùng hai khối rời. Không cần Backend/API mới.

## Decisions

- **D1 Giữ nguyên repository, chỉ đổi UI.** Gửi lại = gọi lại `addReferee(id, email)` (Web `handleReinvite` làm y hệt). Không thêm route, không thêm phương thức repository.
- **D2 Một ô email + chọn vai trò.** `_staffRole` mở rộng thành giá trị `CO_ORGANIZER | REFEREE | SPECTATOR`; `REFEREE` rẽ sang `addReferee`, còn lại `addStaff`. Gộp hai `TextEditingController` thành một và dùng chung một cờ `_isBusy`.
- **D3 Danh sách gộp trong State.** Hai `Future` giữ nguyên, ghép bằng `Future.wait`; bộ lọc vai trò là biến State cục bộ (không lưu, không Riverpod, giống cách `ResultsTab` chọn vòng).
- **D4 Hàm thuần cho dòng hiển thị.** Tách `lib/features/tournament/utils/permission_rows.dart` (`buildPermissionRows`, `PermissionRow`) nhận hai danh sách `Map` và trả danh sách dòng thống nhất kèm `refereeActions` (`none | revoke | resend`), để test không cần dựng widget. Hành động theo `status`: `INVITED → revoke`, `DECLINED → resend`, còn lại `none`.
- **D5 Gỡ token theo vết gọi.** `TournamentManagementSection.tokens` bị xoá khỏi enum nên các `switch` thành exhaustive tự bắt sót; `ITokenRepository`, `TokenModel`, `ApiTokenRepository` giữ vì `auth_provider.dart:385`, `validate_invite_token_use_case.dart`, `delete_tournament_use_case.dart` còn dùng.
- **D6 Trạng thái chỉ ba giá trị.** Nhãn trạng thái lấy từ `tournaments.schema.ts:379`; giá trị lạ rơi vào nhãn "Khác" sẵn có (`tournamentManagementStatusOther`) chứ không đoán.

## Rejected

- Đổi hẳn sang một API mời hợp nhất ở Backend: đụng hợp đồng, ngoài phạm vi.
- Thêm trạng thái "Hết hạn": không có trong nguồn sự thật.
- Xoá luôn `ITokenRepository`/`TokenModel`: còn người dùng khác, sẽ phá luồng nhập mã.

## Risks

- Backend `DELETE /referees/:refereeId` tên là `revokeRefereeInvite`; App hiện cho xoá cả dòng `ACCEPTED`. Thu hẹp còn `INVITED` theo Web nên không mất khả năng nào Web có [SUY LUẬN: chưa chạy thử với dữ liệu thật].
- Đồng tổ chức ngoài trang đầu của workspace phân trang: không liên quan thay đổi này.
