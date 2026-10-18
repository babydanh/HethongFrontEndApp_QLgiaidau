# Proposal

## Why

E2E App (change `app-e2e-integration`, run `39099166857`, `integration_test/auth_flow_test.dart:52`) phát hiện lỗi F1: tài khoản BTC đăng nhập bằng form (`admin1@gmail.com`) trả HTTP 200 nhưng `AuthState.role` là `UserRole.viewer`, không phải `UserRole.organizer`.

Nguyên nhân nằm ở app:
- `lib/providers/auth_provider.dart` (hàm `_mapSessionRole`, trước khi sửa dòng 366-375) chỉ nhận `ADMIN` và `REFEREE`. `ORGANIZER` rơi về `viewer`.
- Backend trả `roles` là mảng tên vai trò: `src/modules/auth/auth.repository.ts:25-35` (`findUserRoles`), enum `src/common/constants/enums.ts` (PLAYER, REFEREE, ORGANIZER, MODERATOR, ADMIN).

Hệ quả: `AuthState.isOrganizer` và `canScore` (`auth_provider.dart:51-59`) luôn sai với BTC đăng nhập bằng form.

## What Changes

- `lib/providers/auth_provider.dart`: thay `_mapSessionRole` (private) bằng `static UserRole mapSessionRole(AuthSession session)` trên `AuthNotifier`. Hàm đọc `session.roles` qua `parseRole` (không phân biệt hoa thường) và ưu tiên ADMIN > REFEREE > ORGANIZER > viewer. PLAYER, MODERATOR hoặc danh sách rỗng → viewer (app không có vai trò riêng cho các loại này).
- `test/providers/auth_state_test.dart`: thêm group `AuthNotifier.mapSessionRole` (6 test): ORGANIZER, chữ thường, ADMIN/REFEREE, PLAYER/MODERATOR/rỗng → viewer, nhiều vai trò cùng lúc, BTC có `isOrganizer` và `canScore`.

### Out of scope (KHÔNG làm)

- Không sửa `getTournamentRoute` (`lib/core/utils/navigation_helpers.dart:4-11`): BTC đi tới `/home` như trước. Ghi nhận là khoảng trống có sẵn cho luồng token, không thuộc lỗi F1.
- Không sửa Backend hay Web.

## Capabilities

### New Capabilities

(không có)

### Modified Capabilities

(không có: `openspec/specs/` không có capability về vai trò đăng nhập. Đây là sửa lỗi để khớp hợp đồng Backend, hành vi được khoá bằng unit test.)

## Impact

- Repo App: `lib/providers/auth_provider.dart`, `test/providers/auth_state_test.dart`.
- Chỗ dùng `isOrganizer`/`canScore` của `AuthState` đổi kết quả cho BTC (đã đọc, không sửa):
  - `lib/features/match/screens/live_score_screen.dart:642,676` (màn chấm điểm);
  - `lib/features/match/widgets/official_score_modal.dart:754`;
  - `lib/features/match/widgets/pickleball_court_panel.dart:80`;
  - `lib/features/tournament/screens/tournament_intro_screen.dart:494-496` (hiện khối quản lý).
- Các màn hồ sơ và tài chính (`profile_screen.dart`, `create_public_quick_tournament_screen.dart`, `tournament_management_finance_section.dart`) đọc `profile.roles` của hồ sơ, không đọc `AuthState`: không đổi.
- `lib/core/router/app_router.dart:149-163`: `/referee*` nay cho phép BTC vào (trước đây chặn `viewer`). Rủi ro cần kiểm khi chạy E2E.
- Backend, Web: không đổi.
