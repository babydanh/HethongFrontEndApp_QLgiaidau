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
