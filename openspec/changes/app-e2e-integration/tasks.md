# Tasks

## 1. Xác minh trước khi viết

- [x] 1.1 Build debug không có `google-services.json` có lỗi không (đọc `android/app/build.gradle.kts`, chạy thử trên cloud ở task 3.1). Xong khi: biết cần hay không cần file giả trong CI. Bằng chứng: plugin áp dụng ở module app (`android/app/build.gradle.kts:7`, khai báo `apply false` tại `android/settings.gradle.kts:24`); bước 10b tạo file giả tại `test-runner.yml:726-731`; theo báo cáo lane, run `39098328267` lỗi thiếu google-services khi chưa có file giả (chưa đọc lại log trong lượt này). Kết luận: CI cần file giả.
- [x] 1.2 Màn đăng nhập (`login_register_screen.dart`) có bước OTP hay xác thực email không. Màn chấm điểm trực tiếp cho vai nào. App có màn BTC duyệt, ghép, tạo nhánh không. Xong khi: có `file:dòng` cho từng ý. Bằng chứng: phụ lục mục A trong `design.md`.
- [x] 1.3 Lập bảng chữ hiển thị (key trong `app_vi.arb`) và `Key` dùng để tìm widget cho 7 luồng. Xong khi: mỗi bước có một cách tìm widget có nguồn. Bằng chứng: phụ lục mục B trong `design.md`.

## 2. Hạ tầng trong repo App

- [x] 2.1 `android/app/src/debug/res/xml/network_security_config.xml` chỉ cho cleartext tới `10.0.2.2` và `localhost`; `android/app/src/debug/AndroidManifest.xml` trỏ tới file này. Xong khi: build release không chứa ngoại lệ này (kiểm bằng `aapt dump xmltree` trên APK release, hoặc đọc manifest đã gộp). Bằng chứng: step `13b` của run `39111478956` (ref `46c2d691`) success, kiểm manifest và resource release đã gộp (`android/app/src/main/AndroidManifest.xml:12` trỏ tới config main không có `10.0.2.2`/`localhost`).
- [ ] 2.2 `integration_test/support/backend_api.dart`: đăng nhập, tạo giải, ADMIN duyệt, nhập danh sách, duyệt đơn, tạo nhánh, chấm điểm. Mỗi lỗi in mã HTTP và 300 ký tự body. Xong khi: `dart analyze integration_test` sạch.

## 3. Workflow cloud (repo agent-orchestrator) và script máy

- [x] 3.1 Job `test-app-e2e` (target `app-e2e`):
  - checkout Backend + App;
  - Postgres + Redis + Backend như `test-fullstack`, tạo tài khoản test;
  - Flutter 3.47.x;
  - tạo `.env` từ `.env.example` (chỉ đổi `API_BASE_URL`, `APP_API_KEY`);
  - `reactivecircus/android-emulator-runner` (API 34, x86_64);
  - `flutter test integration_test/<specs>`;
  - upload artifact `app-e2e-report`.

  Xong khi: chạy một test khói (mở app, thấy màn đăng nhập) và có kết quả.
  Bằng chứng: run `39109977504` (ref `8b166f5b`) đã chạy job; smoke_test PASS trước khi auth chạy.
- [ ] 3.2 `cloud-test-runner.py run --target app-e2e --app-ref <nhánh> [--backend-ref] [--specs integration_test/a_test.dart ...] [--seed data]`. Cập nhật skill `cloud-test-runner`. Xong khi: lệnh dispatch được và in tóm tắt.

## 4. Kịch bản

- [x] 4.1 `integration_test/auth_flow_test.dart`: đăng nhập VĐV và BTC bằng form. Xong khi: xanh trên cloud. Bằng chứng: run `39111478956` (ref `46c2d691`), auth_flow_test kết thúc `+3` không lỗi (VĐV viewer và BTC organizer đều PASS, log dòng 3577). Lần trước run `39109977504` cũng PASS hai ca này.
- [ ] 4.2 `integration_test/tournament_player_flow_test.dart`: danh sách → chi tiết → đăng ký đơn → được duyệt; đăng ký đôi + mời đồng đội; xem nhánh và lịch; nhập tỉ số một trận; nhà vô địch. Xong khi: chạy trên cloud, mỗi ca đỏ có nguyên nhân rõ (lỗi test thì sửa, tối đa 3 vòng; lỗi app thì ghi lại).
- [ ] 4.3 `integration_test/organizer_flow_test.dart`: BTC tạo giải nhanh trên app, mở trang quản lý; thêm duyệt, ghép, tạo nhánh nếu task 1.2 thấy app có. Xong khi: như 4.2.

## 5. Kiểm cuối

- [ ] 5.1 `docs/README.md`: thêm lệnh chạy E2E App và kết quả thật. Xong khi: có lệnh và run id.
- [x] 5.2 `flutter analyze --no-pub integration_test` sạch và `flutter test --no-pub` các test widget liên quan không đỏ thêm (chạy trên cloud target `app`). Xong khi: có run id. Bằng chứng: run `39111514104` (target `app`, ref `46c2d691`): job "Test Flutter App (Dart Analyze & Widget)" success; step `13c` "Phân tích tĩnh integration_test" của run `39111478956` success.
