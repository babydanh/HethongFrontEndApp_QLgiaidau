# Lỗi app phát hiện bởi E2E App

Ghi lại các lỗi của app (không phải lỗi test) do `integration_test` phát hiện trên cloud. Theo proposal, change này KHÔNG sửa logic app. Test tương ứng được giữ đỏ, không skip để xanh.

## F1. Tài khoản BTC (ORGANIZER) đăng nhập bằng form bị gán role `viewer`

- **Tái hiện**: run `39099166857`, `integration_test/auth_flow_test.dart:52` ("BTC đăng nhập bằng form và có quyền BTC"). Đăng nhập `admin1@gmail.com` trả HTTP 200 (`POST /auth/mobile/login`), test kỳ vọng `UserRole.organizer`, thực tế `UserRole.viewer`.
- **Nguyên nhân (đọc code)**:
  - `lib/providers/auth_provider.dart:366-375`, hàm `_mapSessionRole`, chỉ nhận `ADMIN`/`admin` và `REFEREE`/`referee`. `ORGANIZER` rơi về `UserRole.viewer`.
  - `lib/data/repositories/api/api_auth_repository.dart:193,202` lấy `user.roles` dạng chuỗi.
  - Backend `src/modules/auth/auth.repository.ts:34` trả `roleName` dạng chuỗi (`ORGANIZER`). [INFERENCE] response login chứa `ORGANIZER`; log CI chỉ có `response_bytes`, chưa xác nhận nội dung.
- **Phạm vi ảnh hưởng**:
  - Màn tạo giải nhanh (`create_public_quick_tournament_screen.dart:328-330`) kiểm `userProfile.role`, không kiểm `AuthState.role`. Luồng tạo giải không bị chặn bởi lỗi này.
  - Ảnh hưởng tới `AuthState.role` (`isOrganizer`, `canScore` tại `auth_provider.dart:51-56`) chưa được kiểm trên app. [INFERENCE] các chỗ dùng `AuthState` cho quyền BTC sẽ thấy `viewer`.
- **Trạng thái**: đã sửa ở change `fix-organizer-role-mapping`, commit `dcb750f7` (nhánh `app-e2e-integration-20261017`). `AuthNotifier.mapSessionRole` (`lib/providers/auth_provider.dart:366-376`) ưu tiên ADMIN > REFEREE > ORGANIZER. Chờ cloud xác nhận `integration_test/auth_flow_test.dart:52` xanh (task 1.3 của change đó). Task 4.1 (phần BTC) chỉ tick khi có run id.

## F2. Kiểm quyền BTC chỉ dựa vào trường `role` đơn

- **Tái hiện**: run `39107055615` (ref `142dad4c`) và `39108355255` (ref `dbdd7fdd`), `integration_test/organizer_flow_test.dart` ("BTC tạo giải nhanh…"). Test bấm "Tạo giải nhanh" rồi bị đẩy khỏi màn tạo giải trước khi nhập form: `Bad state: No element` ở bước cuộn tới "Thêm nội dung".
- **Nguyên nhân (đọc code)**:
  - `create_public_quick_tournament_screen.dart` `_verifyOrganizerPermission` (~328-329) và `_submit` (~494-495) kiểm `role == 'ORGANIZER'`/`'ADMIN'` trên trường `role` đơn.
  - `profile_screen.dart:626-627` (nhãn vai trò hồ sơ) làm tương tự.
  - Backend `src/modules/users/users.repository.ts:392,725` đặt `role: rolesList[0] || 'PLAYER'`; `users.service.ts:59` đặt `PLAYER` đứng đầu. Một BTC có thể có `role = PLAYER` và `roles` chứa `ORGANIZER`. [INFERENCE] suy từ code; chưa đo body `/users/profile`. Dialog chặn (`showOrganizerRequiredDialog`) làm màn đóng là [INFERENCE] từ log, chưa đo nội dung dialog.
- **Sửa**: dùng `UserProfile.hasRole` (kiểm mảng `roles`, `lib/domain/entities/user.dart:98-101`) ở 3 chỗ tạo giải và ở nhãn hồ sơ. Unit test: `test/domain/user_profile_role_test.dart`.
- **Trạng thái**: đã sửa trong working tree, chờ commit và cloud xác nhận (run chưa có).

## F3. ListTile nằm trong Container có nền gây assertion Material

- **Tái hiện**: run `39108355255`, log `%TEMP%/cloud-test-39108355255-117618971826.log` quanh dòng 3729-3760 (07:51:42, trong ca BTC). Lỗi debug "ListTile background color or ink splashes may be invisible ... wrapped in a DecoratedBox that has a background color", báo 2 lần.
- **Nguyên nhân (đọc code)**: `create_public_quick_tournament_screen.dart` bọc `SwitchListTile`/`ExpansionTile` bằng `Container(decoration: BoxDecoration(color: colors.bgSurface, border: colors.border))` ở 3 chỗ: khối phí tham gia (~1516), "Cài đặt nâng cao" (~1997), khối tuỳ chọn trong sheet "Thêm nội dung" (~2534). `ExpansionTile` có `tilePadding` `symmetric(horizontal: 12)`, khớp `contentPadding (12,0,12,0)` trong thông báo.
- **Sửa**: đổi 3 `Container` có decoration thành `Material(color, shape: RoundedRectangleBorder(...))` để Material nằm ngay trên ListTile. Màu nền và viền giữ nguyên.
- **Trạng thái**: đã sửa trong working tree, chờ commit và cloud xác nhận (run chưa có).
