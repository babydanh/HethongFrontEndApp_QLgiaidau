## Why

Người dùng chốt 2026-10-28 (xem trang Lavish `quan-ly-giai-ui-audit`, màn 13): hệ thống không còn "mã truy cập" (token) cho vai trò trong giải, chỉ mời qua email như Web. App vẫn có màn "Mã truy cập" (`TokenManagementScreen`) cho phép tạo/làm mới mã theo vai trò, và màn "Phân quyền" là hai khối rời (nhân sự, trọng tài) mỗi khối một ô email, trọng tài không có "Gửi lại" khi bị từ chối và "Thu hồi" chỉ là nút xoá chung. Web (`PermissionsTab.tsx`) gom một chỗ: ô email + chọn vai trò, danh sách theo vai trò, trọng tài có trạng thái Đã mời/Đã nhận/Đã từ chối, Gửi lại khi bị từ chối, Thu hồi khi còn chờ.

## What Changes

- **Gỡ** màn "Mã truy cập" khỏi App: file `token_management_screen.dart`, notifier `token_management_notifier.dart`, `presenceCountProvider`, hai route `tokens` trong `app_router.dart`, mục `TournamentManagementSection.tokens` (menu hub, section screen), test dựng màn đó.
- **Giữ** `ITokenRepository`/`TokenModel` và luồng nhập mã mời đăng ký (auth/`ValidateInviteTokenUseCase`, `DeleteTournamentUseCase`) vì không thuộc màn quản lý này.
- **Làm lại** màn "Phân quyền" theo Web: một khối "Mời qua email" (ô email + chọn vai trò Đồng tổ chức / Trọng tài / Khán giả + một nút Gửi lời mời), dưới là danh sách theo vai trò (chip lọc). Trọng tài hiện trạng thái Đã mời / Đã nhận / Đã từ chối; Đã từ chối có **Gửi lại**, Đã mời có **Thu hồi**, cả hai hỏi xác nhận. Nhân sự (đồng tổ chức, khán giả) giữ nút gỡ có xác nhận như hiện nay.
- Chuỗi mới vào `app_vi.arb` + `app_en.arb`, chạy `flutter gen-l10n`.

## Capabilities

### New Capabilities
- `app-permissions-invite`: Màn Phân quyền mời nhân sự và trọng tài qua email, hiển thị trạng thái lời mời và thao tác Gửi lại / Thu hồi như Web.

### Modified Capabilities
- (không có spec nào đang ghi nhận màn Mã truy cập; việc gỡ được nêu ở "What Changes" và kiểm bằng tasks)

## Impact

- App Flutter: `lib/features/tournament/screens/tournament_management_people_section.dart` (khối `_TournamentPermissions`, `_PersonRow`), `tournament_management_section_screen.dart`, `tournament_management_hub_screen.dart`, `lib/core/router/app_router.dart`, `lib/providers/query_providers.dart`, `lib/l10n/*.arb`, `test/features/mobile_row_overflow_test.dart`; xoá `token_management_screen.dart`, `token_management_notifier.dart`.
- Backend: không đổi. App dùng lại `GET/POST/DELETE /tournaments/:id/staff`, `GET/POST/DELETE /tournaments/:id/referees` đã có và Web đang gọi; Gửi lại = `POST /referees` cùng email (đúng như `handleReinvite` của Web).
- Web: không đổi.

## Out of scope

- Xoá phía Backend (bảng/route token vai trò, `regenerate-invite`): việc riêng, cần OpenSpec Backend + `/security-review`; chưa kiểm luồng trọng tài/khán giả vào bằng link có mã còn dùng token hay không [SUY LUẬN: gỡ UI App không làm hỏng Backend].
- Chế độ "Mã mời" ở màn Đăng ký (mã mời đăng ký giải, khác token vai trò): giữ nguyên, chờ anh quyết giữ hay bỏ.
- Trạng thái "Hết hạn" cho lời mời: không có ở Web lẫn Backend (cột `status` chỉ `INVITED | ACCEPTED | DECLINED`, `tournaments.schema.ts:379`), nên màn thiết kế trên Lavish phải bỏ chip này, không thêm trạng thái ngoài nguồn sự thật.
- Dọn khoá l10n `manageTokens`, `manageTokensSubtitle` (không còn dùng sau khi gỡ): để lượt dọn riêng, tránh nhiễu diff file sinh.
