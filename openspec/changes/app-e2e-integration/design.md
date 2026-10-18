# Design

## Context

Đã đọc trên `origin/main` `7732328f`:
- `lib/main.dart:9-64`:
  - Nạp `.env` (là asset, `pubspec.yaml:101-115`).
  - Sentry chỉ bật khi có `--dart-define=SENTRY_DSN`.
  - App chạy `TournamentApp` trong `ProviderScope`.
- `lib/core/services/dio_client.dart:40-75`:
  - Base URL lấy từ `API_BASE_URL`.
  - Trên máy ảo Android, `localhost`/`127.0.0.1` tự đổi thành `10.0.2.2`.
  - Có `APP_API_KEY` thì gửi header `x-app-key`.
- `android/app/src/main/res/xml/network_security_config.xml`: chặn mọi HTTP thường. Đây là **rào cản chính**: máy ảo gọi Backend trên runner qua `http://10.0.2.2:3000`.
- `android/app/build.gradle.kts:3-8` áp plugin Google Services. `google-services.json` bị gitignore (`.gitignore:89-100`). Firebase chỉ khởi tạo trong `PushNotificationService.initialize` và lỗi được bắt (`push_notification_service.dart:37-107`).
- Job `test-fullstack` của `agent-orchestrator` đã có sẵn các bước dựng Postgres, Redis và Backend, tạo `admin1@gmail.com` (ORGANIZER) / `user8@gmail.com`, mật khẩu `123456`, rồi xác thực email bằng SQL. Với `--seed data` thì có thêm ADMIN `vndcsport@gmail.com`.

## Goals / Non-Goals

**Goals:**
- Kịch bản bấm trên app thật, nối Backend thật. Bước gãy đầu tiên hiện rõ trong báo cáo (ảnh chụp + log HTTP của bước API).
- Dùng lại cách dựng môi trường của job `test-fullstack`, không viết lại từ đầu.

**Non-Goals:**
- Không phủ hết mọi màn hình ở bước đầu. Chỉ phủ 7 luồng trong proposal.

## Decisions

- **`flutter test integration_test/<file> -d emulator-5554`**, không dùng `flutter drive`. `flutter test` gọn hơn, không cần `test_driver/`, và chạy được trên máy ảo.
- **Máy ảo:** `reactivecircus/android-emulator-runner@v2` trên `ubuntu-latest` (có KVM), `api-level: 34`, `arch: x86_64`, `target: google_apis`, tắt animation, có cache AVD.
  - *Phương án khác:* Firebase Test Lab không gọi được Backend dựng trên runner, nên loại.
- **Cấu hình mạng riêng bản debug:** Android gộp `src/debug/res/xml/network_security_config.xml` đè lên bản main khi build debug. File này chỉ cho cleartext tới `10.0.2.2` và `localhost`, bản release không đổi.
  - *Phương án khác:* dựng HTTPS tự ký cho Backend trong job thì phức tạp và chậm hơn nhiều.
- **`.env` trong CI:** chép từ `.env.example` rồi đặt `API_BASE_URL=http://10.0.2.2:3000/api/v1`, `APP_API_KEY=` (rỗng). Không chép `.env` thật.
- **Dựng dữ liệu bằng API ngay trong test Dart** (Dio, gọi thẳng Backend), giống bên Web: tên giải và VĐV có hậu tố thời gian nên chạy lại không trùng. Giao diện dùng cho các bước người dùng thật bấm.
- **Tìm widget:** ưu tiên chữ hiển thị lấy từ `lib/l10n/app_vi.arb` (máy ảo để tiếng Việt). Có `Key` sẵn thì dùng `Key`. Chỉ thêm `Key` mới khi không còn cách khác.
- **Báo cáo:** `flutter test --reporter json` (hoặc `expanded`), kèm ảnh khi đỏ qua `IntegrationTestWidgetsFlutterBinding.takeScreenshot`. Ảnh và log upload thành artifact `app-e2e-report`.

## Chưa chắc (xác minh ở task 1, trước khi viết kịch bản)

- Thiếu `google-services.json` thì Gradle build debug có lỗi không. Nếu lỗi, CI phải tạo file giả (project ID giả). Không dùng file thật.
- Màn đăng nhập có bước OTP hay xác thực email không. Tài khoản test đã được xác thực bằng SQL như bên Web.
- Màn chấm điểm trực tiếp trên app cho vai nào (BTC, trọng tài) và gọi API nào.
- App có màn BTC duyệt đơn, ghép cặp, tạo nhánh không. Nếu có thì thêm vào bước 2.

## Risks / Trade-offs

- [Máy ảo chậm hoặc lúc chạy lúc không] → tắt animation, mỗi bước chờ có giới hạn thời gian rõ ràng, có cache AVD. Chạy tay, không đưa vào cổng gộp.
- [Tìm widget theo chữ thì vỡ khi đổi câu chữ] → dùng chuỗi lấy từ `app_vi.arb`. Nếu đổi chữ thì test đỏ kèm tên key.
- [Thời gian 20–30 phút] → chỉ chạy khi cần hoặc theo lịch đêm, không chạy mỗi lần gộp.

## Phụ lục: ánh xạ finder cho 7 luồng (task 1.2, 1.3)

Nguồn: đọc `lib/` và `integration_test/` tại `8b166f5b`. `arb` = `lib/l10n/app_vi.arb`.

### A. Hành vi và màn hình (task 1.2)

- OTP/xác minh email ở màn đăng nhập: không có. Màn gọi trực tiếp đăng nhập/đăng ký rồi chuyển `/login-loading` (`lib/features/auth/screens/login_register_screen.dart:62-77`). API xác minh có tồn tại nhưng không nằm trong luồng màn hình (`lib/data/repositories/api/api_auth_repository.dart:135-156`).
- Chấm điểm trực tiếp: `canScore` cho `admin`, `referee`, `organizer` (`lib/providers/auth_provider.dart:13-16, 41-49`); `viewer` không. Ngoại lệ: trận Super Lite cho người đã đăng nhập (`lib/features/match/screens/live_score_screen.dart:639-642`).
- BTC duyệt đơn: không có màn trong luồng đã đọc; test duyệt bằng API (`integration_test/tournament_player_flow_test.dart:128-131`). Kết luận chỉ trong phạm vi các màn đã đọc.
- Ghép đôi: chỉ có ở đăng ký của VĐV (`integration_test/tournament_player_flow_test.dart:258-300`); không xác định được màn BTC ghép đôi.
- Tạo nhánh: có màn bốc thăm BTC với `Bốc thăm tự động` và `Lưu & Bắt đầu giải` (`integration_test/organizer_flow_test.dart:168-181`).

### B. Finder theo luồng (task 1.3)

| Bước | Text / Key | Nguồn | Finder trong test |
|---|---|---|---|
| 1 Smoke | Địa chỉ Email; Đăng nhập | `emailLabel` (arb:68), `loginButton` (arb:71) | `integration_test/smoke_test.dart:20, 26` |
| 2 Đăng nhập VĐV | Địa chỉ Email | arb:68 | `integration_test/auth_flow_test.dart:20, 33-35` (`loginWithForm` trong `support/app_driver.dart`) |
| 3 Đăng nhập BTC | Địa chỉ Email | arb:68 | `integration_test/auth_flow_test.dart:43-47, 55-57` |
| 4 Đăng ký đơn → duyệt → nhánh/lịch → vô địch | Giải đấu (arb:55); Đăng ký ngay (arb:77); Chờ duyệt (arb:844); Lịch thi đấu (arb:436) | arb | `integration_test/tournament_player_flow_test.dart:57-96, 109-173`; duyệt và bốc thăm qua API `:128-135` |
| 5 Đăng ký đôi, mời đồng đội | Tiếp theo (arb:876); Tên đội (arb:861); Mời sau (arb:865); Nhập email hoặc SĐT đồng đội (arb:875); Sao chép link mời (arb:881); mô tả mời (arb:879) | arb | `integration_test/tournament_player_flow_test.dart:219-308` |
| 6 BTC tạo giải, thêm VĐV, bốc thăm | Thời gian bắt đầu *, Thêm nội dung, Tạo giải nhanh (literal, chưa đối chiếu được key arb); Bốc thăm tự động, Lưu & Bắt đầu giải (literal); Key `organizer-ops-add-athlete`, `add-athlete-sheet`, `add-athlete-direct-name`, `add-athlete-direct-email`, `add-athlete-direct-submit` | literal/Key | `integration_test/organizer_flow_test.dart:42-181` |
| 7 VĐV nhập điểm | Ngoài phạm vi: không có flow nhập điểm cho VĐV (xem mục A) | — | — |

Giới hạn: các literal chưa đối chiếu được với key arb được ghi rõ; không khẳng định là hardcoded trong widget.
