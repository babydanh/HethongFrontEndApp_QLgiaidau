# Proposal

## Why

App chưa có E2E nào chạy với Backend thật. Phần đang có:
- Thư mục `test/` có khoảng 120 file unit/widget test dùng API giả (`test/support/fake_api_adapter.dart`).
- Job `test-app` trên cloud (`agent-orchestrator/.github/workflows/test-runner.yml:465-495`) chỉ chạy `flutter analyze` và `flutter test`.
- `origin/main` không có thư mục `integration_test/`.

Ngày 17/10/2026, E2E của Web (change `e2e-tournament-lifecycle` bên repo Web) đã bắt được 7 lỗi app khi chạy hệ thống thật, trong đó có lỗi làm giải không kết thúc được. Người dùng yêu cầu App cũng có E2E tương tự: một máy Android ảo bấm qua các màn hình của app thật, nối với Backend và Postgres thật trên GitHub Actions.

## What Changes

- **Thư mục `integration_test/` mới** (package `integration_test` đã có trong `pubspec.yaml`). Kịch bản chạy trên app thật (`TournamentApp` + `ProviderScope`), gọi Backend thật qua `http://10.0.2.2:3000/api/v1`. Bước đầu gồm:
  1. Đăng nhập bằng form, cả VĐV (`user8@gmail.com`) và BTC (`admin1@gmail.com`).
  2. Trang chủ → danh sách giải → chi tiết một giải công khai. Giải được dựng sẵn bằng API và đã được ADMIN duyệt.
  3. VĐV đăng ký nội dung đơn trên app → BTC duyệt (bằng API) → app hiện trạng thái đã duyệt.
  4. VĐV đăng ký nội dung đôi, mời đồng đội; đồng đội chấp nhận bằng API → app hiện cặp đủ.
  5. BTC tạo nhánh (bằng API) → app hiện nhánh đấu và lịch.
  6. Nhập tỉ số một trận trên app (màn chấm điểm trực tiếp, nếu tài khoản có quyền). Chơi hết bằng API → app hiện nhà vô địch.
  7. BTC trên app: tạo giải nhanh, mở trang quản lý giải.
- **Helper Dart gọi Backend để dựng dữ liệu** (`integration_test/support/`). Tương đương `test/e2e/support/lifecycle-api.ts` bên Web: đăng nhập lấy token, tạo giải, ADMIN duyệt, nhập danh sách, duyệt đơn, tạo nhánh, chấm điểm.
- **Cấu hình mạng riêng bản debug** `android/app/src/debug/res/xml/network_security_config.xml`: chỉ cho HTTP thường tới `10.0.2.2` và `localhost`. Bản release giữ nguyên, vẫn chặn cleartext (`android/app/src/main/res/xml/network_security_config.xml`).
- **Workflow cloud (repo `agent-orchestrator`, ngoài repo này):** thêm target `app-e2e`. Job dựng Postgres + Redis + Backend như job `test-fullstack`, bật máy ảo Android (API 34, x86_64) bằng `reactivecircus/android-emulator-runner`, rồi chạy `flutter test integration_test/...`. `~/.omp/scripts/cloud-test-runner.py` nhận `--target app-e2e --app-ref <nhánh>`.

### Out of scope (KHÔNG làm)

- Không chạy iOS, không dùng Firebase Test Lab.
- Không sửa logic app. Ngoại lệ:
  - cấu hình mạng riêng bản debug ở trên;
  - thêm `Key` cho widget, **chỉ khi** không tìm được bằng chữ hiển thị ổn định. Mỗi `Key` thêm vào phải ghi vào tasks.
- Không sửa 7 lỗi app mà E2E Web đã phát hiện (danh sách ở `openspec/changes/e2e-tournament-lifecycle/findings.md` bên repo Web). Nếu E2E App gặp lại chúng thì để đỏ đúng chỗ.
- Không đưa E2E App vào cổng gộp tự động (`merge-lane.py`) ở bước này. Chỉ chạy khi gọi tay.
- Không chạy E2E ở máy (theo `AGENTS.md`: test nặng chạy trên cloud).

## Capabilities

### New Capabilities

(không có: hạ tầng test, `skip_specs: true`)

### Modified Capabilities

(không có)

## Impact

- **Repo này:**
  - `integration_test/` (mới);
  - `android/app/src/debug/res/xml/network_security_config.xml` (mới) và `android/app/src/debug/AndroidManifest.xml` (trỏ tới file đó);
  - `docs/README.md` (thêm lệnh chạy E2E App).
- **Repo `agent-orchestrator`:** `.github/workflows/test-runner.yml` thêm job `test-app-e2e`. Push repo này không deploy gì.
- **Script máy:** `~/.omp/scripts/cloud-test-runner.py` thêm target `app-e2e`.
- **Backend:** không sửa. Dùng các route sau:
  - `/auth/mobile/login`, `/tournaments/lite`, `/admin/tournaments/:id/approve`;
  - `/tournaments/:id/roster-import`, `/tournaments/:id/participants/:participantId`;
  - `/tournaments/:id/generate-bracket`, `/matches`, `/matches/:id/score`.
  - `APP_API_KEY`: Backend chỉ bắt buộc ở production (`app-key.guard.ts:53-68`). Job test để trống nên không cần khoá thật.
- **Web:** không ảnh hưởng.
- **Thời gian chạy:** [INFERENCE] khoảng 20–30 phút mỗi lượt (máy ảo Android khởi động 3–5 phút, build APK debug 5–8 phút). 0 token AI.
