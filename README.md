# Sporto — App Flutter (Quản lý giải đấu)

Ứng dụng di động (iOS/Android) của nền tảng quản lý giải đấu thể thao phong trào **Sporto**: đăng ký giải, xem lịch và kết quả, chấm điểm trận (Pickleball, Cầu lông, Tennis, Bóng đá), xem trực tiếp, CLB, kèo giao lưu, chat, thông báo.

| Hệ thống | Repo | Vai trò |
|---|---|---|
| Backend API | `babydanh/HethongBackendApi_QuanlyGiaiDau` | NestJS: toàn bộ nghiệp vụ và dữ liệu |
| Web | `babydanh/HethongFrontEndWeb_QLgiaidau` | Next.js: trang công khai + bảng điều khiển |
| **App** (repo này) | `babydanh/HethongFrontEndApp_QLgiaidau` | Flutter: iOS/Android |
| Orchestrator | `babydanh/agent-orchestrator` | GitHub Actions: test cloud, deploy, quét bảo mật |

- Package: `app_quanly_giaidau` · Dart `^3.10.3`, Flutter `>=3.41.0` (CI dùng 3.47.4)
- Hai ngôn ngữ: Tiếng Việt (mẫu) và English.

## Công nghệ

| Mảng | Dùng |
|---|---|
| State | Riverpod 3 (`flutter_riverpod`) |
| Điều hướng | `go_router` 17 (một `GoRouter` ở `lib/core/router/app_router.dart`) |
| Gọi API | Dio qua `DioClient` (`lib/core/services/dio_client.dart`) |
| Realtime | `socket_io_client` (tỉ số trực tiếp, chat) |
| Đăng nhập | Email, Google, Apple (`google_sign_in`, `sign_in_with_apple`) |
| Thông báo đẩy | Firebase (`firebase_core`, `firebase_messaging`) |
| Đa ngôn ngữ | `flutter_localizations` + ARB (`lib/l10n/app_vi.arb`, `app_en.arb`) |
| Cấu hình | `flutter_dotenv` (`.env`) |
| Test | `flutter_test`, `mocktail`, `integration_test` |

## Cài đặt

### Yêu cầu
- Flutter stable (đúng phiên bản trong `pubspec.yaml`), Android Studio hoặc Xcode (iOS cần macOS)
- Backend API đang chạy (local hoặc staging)
- File Firebase của riêng bạn: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` (không commit)

### Các bước

```bash
# 1. Lấy code
git clone https://github.com/babydanh/HethongFrontEndApp_QLgiaidau.git
cd HethongFrontEndApp_QLgiaidau
flutter pub get

# 2. Tạo file .env ở gốc repo (xem bảng bên dưới; repo có sẵn file mẫu .env.example)

# 3. Sinh code đa ngôn ngữ (khi đổi file .arb)
flutter gen-l10n

# 4. Chạy trên máy/emulator đang kết nối
flutter run
```

### Biến môi trường (`.env`, không commit)

| Biến | Dùng cho |
|---|---|
| `API_BASE_URL` | Địa chỉ Backend, ví dụ `https://staging.sporto.asia/api/v1`; Socket.IO cũng suy ra từ đây |
| `APP_API_KEY` | Khoá gọi API |
| `WEB_BASE_URL`, `FRONTEND_URL` | Địa chỉ Web (tạo liên kết chia sẻ) |
| `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID` | Đăng nhập Google |
| `OSM_TILE_URL` | Nguồn ô bản đồ |

Tham số build tuỳ chọn (`--dart-define`): `SENTRY_DSN`, `APP_RELEASE`.

`.env` là secret: không đọc, không in, không commit. Worktree mới không có `.env`; xin file từ người quản trị.

---

## Lệnh thường dùng

| Việc | Lệnh |
|---|---|
| Chạy app | `flutter run` |
| Test một file | `flutter test --no-pub test/<đường dẫn>_test.dart` |
| Phân tích tĩnh một thư mục | `flutter analyze --no-pub lib/<thư mục>` |
| Sinh l10n | `flutter gen-l10n` (không sửa tay `lib/l10n/app_localizations*.dart`) |
| Format file đã sửa | `dart format <file>` (chỉ file của mình) |

Thêm chuỗi mới: thêm key vào **cả** `app_vi.arb` và `app_en.arb`, rồi `flutter gen-l10n`.

## Test ở đâu

| Loại | Chạy ở đâu | Cách chạy |
|---|---|---|
| Unit và widget (`test/`, hơn 500 file) | Máy local, chỉ file liên quan | `flutter test --no-pub <file>` |
| CI của repo (`ci.yml`): `flutter analyze` + `flutter test` đầy đủ | GitHub Actions, tự chạy trên mọi push nhánh khác `main` (bỏ qua push chỉ có tài liệu) | Tự động |
| Cả bộ test + analyze trên cloud | `agent-orchestrator` → `test-runner.yml`, target `app` | `cloud-test-runner.py run --target app --branch <nhánh>` |
| E2E `integration_test/` (Android emulator API 34 + Backend, Postgres, Redis thật) | `test-runner.yml`, target `app-e2e` | `cloud-test-runner.py run --target app-e2e --app-ref <nhánh> --specs integration_test/<tên>_test.dart` |

- Không chạy bộ test đầy đủ hoặc E2E trên máy local (máy yếu): đẩy lên cloud như trên.
- `cloud-test-runner.py` nằm ở `~/.omp/scripts/` của máy phát triển. Đọc lỗi: `cloud-test-runner.py summary <run_id|last>`.
- Test chấm điểm, bracket, luồng người dùng: `integration_test/` có các hành trình `*_journey_test.dart`; bản đồ độ phủ ở `integration_test/COVERAGE.md`.
- Tài khoản E2E là tài khoản giả (seed CI), không dùng dữ liệu thật.

## Deploy ở đâu

- **Không có deploy production tự động.** Đẩy `main` chỉ đưa code lên GitHub (CI chạy analyze/test), không phát hành gì.
- **iOS / App Store**: chạy **bằng tay** workflow `deploy-ios.yml` (`workflow_dispatch`, runner macOS): `flutter analyze` → `flutter build ipa` → ký và đẩy lên App Store Connect, tuỳ chọn gửi duyệt Apple Review (`submit_for_review`). Cần secret App Store Connect, chứng chỉ ký và `GOOGLE_SERVICE_INFO_PLIST` trong repo secrets.
  ```bash
  gh workflow run deploy-ios.yml -R babydanh/HethongFrontEndApp_QLgiaidau -f build_number=<số build> -f submit_for_review=false
  ```
- **Android**: repo chưa có workflow phát hành tự động; build bản AAB bằng `flutter build appbundle` rồi đưa lên Google Play Console.
- **Backend mà App gọi tới** được deploy qua `agent-orchestrator` (staging `staging.sporto.asia`, production `sporto.asia`); App không tự deploy Backend/Web. Cách dùng bộ điều phối: xem README của [agent-orchestrator](https://github.com/babydanh/agent-orchestrator).
- Đưa code vào `main` của App: `merge-lane.py <worktree> --check "<kiểm tra>" --push` (rebase + kiểm tra + đẩy).

---

## Cấu trúc thư mục

```text
lib/
  main.dart, app.dart
  core/          # router, di, services (dio, socket), config (theme), widgets chung
  domain/        # entities, repositories (interface), usecases
  data/          # models JSON, repositories/api/ (gọi Backend)
  providers/     # Riverpod providers
  features/      # theo tính năng: auth, tournament, bracket, match, live, community, chat, ...
  l10n/          # app_vi.arb, app_en.arb (+ code sinh)
test/            # unit + widget test
integration_test/# E2E trên emulator
docs/            # bản đồ tài liệu (docs/README.md)
openspec/        # kế hoạch thay đổi (openspec/changes/<id>/)
```

## Quy ước khi đóng góp

- Làm trong **worktree riêng**: `git-wt switch -c <ten-viec> --base origin/main --no-cd -y`.
- Kế hoạch và thay đổi lớn viết trong `openspec/changes/<id>/`.
- Không thêm package khi không được yêu cầu.
- Đọc `AGENTS.md`, `CLAUDE.md` và `docs/README.md` trước khi sửa; animation/chuyển động đọc thêm `.agents/skills/flutter-animation/SKILL.md`.
