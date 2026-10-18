# Tasks

## 1. Sửa và kiểm

- [x] 1.1 `lib/providers/auth_provider.dart`: thay `_mapSessionRole` bằng `AuthNotifier.mapSessionRole` (dòng 366-376), ORGANIZER → `UserRole.organizer`. Xong khi: code có trong commit `dcb750f7` (nhánh `app-e2e-integration-20261017`).
- [x] 1.2 `test/providers/auth_state_test.dart` (dòng 83-121): 6 unit test cho `mapSessionRole`. Xong khi: target `app` trên cloud (`flutter analyze` + `flutter test`) xanh, có run id. Bằng chứng: run `39103144929` (sha orchestrator `5238b12`), job "Test Flutter App (Dart Analyze & Widget)" success, 4.8 phút.
- [x] 1.3 Kiểm BTC đăng nhập form: `integration_test/auth_flow_test.dart:52` xanh trên cloud `app-e2e`. Xong khi: có run id. Bằng chứng: run `39109977504` (ref `8b166f5b`), auth BTC PASS; kết quả tổng `+3` không có lỗi sau smoke và auth VĐV (log `%TEMP%/cloud-test-39109977504-117623812320.log`, dòng tearDownAll `+3`). Chạy lại trên ref `46c2d691` xem run mới ở ghi chú tiếp theo.
- [x] 1.4 `openspec/changes/app-e2e-integration/findings.md` ghi F1 đã sửa ở change này, kèm hash commit. Xong khi: có hash. Bằng chứng: `findings.md` mục F1, dòng 15, hash `dcb750f7`.
