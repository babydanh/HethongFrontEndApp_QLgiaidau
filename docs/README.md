# Bản đồ tài liệu — App Flutter Quản Lý Giải Đấu

Một câu hỏi, một nơi trả lời. Đọc bảng dưới trước khi mở tài liệu khác; tạo hay đổi vai trò một tài liệu thì sửa bảng này trong cùng commit.

Nhãn:
- **chuẩn**: đọc và làm theo. Repo này chưa có `INSTRUCTIONS.md`; khi hai nguồn chuẩn mâu thuẫn, báo người dùng.
- **tham khảo**: đúng ý tưởng, chi tiết có thể đã lệch code; đối chiếu code trước khi dựa vào.
- **kế hoạch cũ**: ghi ý định tại một thời điểm, KHÔNG phải mô tả hệ thống hiện tại. Không lấy làm sự thật.
- **sự thật (code/cấu hình)**: file code hoặc cấu hình là nguồn đúng nhất; tài liệu không có.

## Muốn biết… thì đọc

| Câu hỏi | File | Nhãn |
|---|---|---|
| State (Riverpod): provider, wiring repository | `lib/providers/` (29/31 file import riverpod), `lib/core/di/` (5 file, ví dụ `repository_providers.dart`), `ProviderScope` trong `lib/main.dart` | sự thật (code) |
| Điều hướng (route) | `lib/core/router/app_router.dart` (`routerProvider`, 95 `GoRoute(`), dùng bởi `MaterialApp.router` trong `lib/app.dart` | sự thật (code) |
| Gọi API Backend: client, base URL | `lib/core/services/dio_client.dart` (đọc `API_BASE_URL` từ `.env`); repository `lib/data/repositories/api/` | sự thật (code) |
| Contract HTTP với Backend (endpoint, field) | Controller ở repo Backend: `D:/Duancanhan/Project_QuanLyGiaiDau/HethongBackendApi_QuanlyGiaiDau/src/modules/<feature>/*.controller.ts` (32 file; đường dẫn tuyệt đối, không dùng `../` vì từ worktree nó trỏ sai) | sự thật (repo Backend) |
| Interface repository (tầng domain) | `lib/domain/repositories/` (20 file); entity `lib/domain/entities/`; usecase `lib/domain/usecases/` | sự thật (code) |
| Model JSON (tầng data) | `lib/data/models/` (30 file) | sự thật (code) |
| Chuỗi hiển thị, đa ngôn ngữ vi/en | `l10n.yaml` (template `lib/l10n/app_vi.arb`), `lib/l10n/app_en.arb` (4400 key mỗi file, khớp tên key); code sinh `lib/l10n/app_localizations*.dart` (không sửa tay) | sự thật (cấu hình + arb) |
| Màn hình và widget của tính năng | `lib/features/<tên>/` (screens, widgets) | sự thật (code) |
| Widget dùng chung, theme, spacing, typography | `lib/core/widgets/`, `lib/core/config/` (`app_theme.dart`, `app_spacing.dart`, `app_typography.dart`) | sự thật (code) |
| Animation, chuyển động | `.github/copilot-instructions.md`, `.agents/skills/flutter-animation/SKILL.md` | chuẩn |
| Phiên bản SDK, dependency | `pubspec.yaml` (Dart ^3.10.3, Flutter >=3.41.0) | sự thật (cấu hình) |
| Lint, analyzer | `analysis_options.yaml` (include `flutter_lints`) | sự thật (cấu hình) |
| Biến môi trường | `.env.example` (mẫu, đã track). `.env` là secret, gitignored: không đọc, không in | sự thật (cấu hình) |
| Test: vị trí, cấu trúc | `test/` (120 file `*_test.dart`); `test/helpers/mock_data.dart` | sự thật (code) |
| Deploy iOS | `.github/workflows/deploy-ios.yml` (chỉ `workflow_dispatch`; ghi `.env` từ secret lúc build) | sự thật (cấu hình) |
| Thiết kế tính năng Xé vé Social | `thiet-ke-xe-ve-social-he-thong-quan-ly-giai-dau.md` | tham khảo |
| Kế hoạch test, test case | `test_docs/` (xem bảng "Bộ tài liệu" bên dưới) | tham khảo / kế hoạch cũ |
| Hành vi hệ thống đã chốt qua OpenSpec | `openspec/specs/` (hiện chưa có spec nào) | chuẩn |
| Việc đang làm / kế hoạch mới | `openspec/changes/<id>/` | chuẩn |
| Luật làm việc cho agent | `AGENTS.md` (gốc repo) | chuẩn |
| Lệnh đã chạy thật và kết quả | mục "Lệnh" dưới đây | chuẩn (ghi theo ngày) |
| Giới thiệu sản phẩm | `README.md` là mẫu mặc định `flutter create`, KHÔNG mô tả app | tham khảo (trống) |

## Quy ước thật trong code

- State: Riverpod 3 (`flutter_riverpod ^3.3.1`). Provider nằm ở `lib/providers/` và `lib/core/di/`; `lib/core/di/repository_providers.dart` gắn interface tầng domain với implementation tầng data.
- Route: một `GoRouter` (`routerProvider`) trong `lib/core/router/app_router.dart`; không có router thứ hai.
- Gọi API: repository `lib/data/repositories/api/` nhận `DioClient` và gọi `_dioClient.dio.get/patch...` trực tiếp (ví dụ `ApiTournamentRepository`). `DioClient` đổi `localhost`/`127.0.0.1` thành `10.0.2.2` trên Android.
- i18n: `l10n.yaml` (`arb-dir: lib/l10n`, template `app_vi.arb`, class `AppLocalizations`). Thêm chuỗi = thêm key vào cả `app_vi.arb` và `app_en.arb`, rồi `flutter gen-l10n`; file sinh đã nằm trong git.
- Kiểm i18n (đã kiểm: file tồn tại; CHƯA chạy): `scripts/check_equal_arb_values.py` liệt kê key có giá trị EN = VI (dấu hiệu chưa dịch); `scripts/audit_l10n_literals.py` tìm chuỗi hardcode trong code.
- Test: `flutter_test`, `mocktail`; E2E `integration_test` (4 kịch bản chạy trên CI) xem mục "E2E App (integration_test)" bên dưới.
- Không có tài liệu kiến trúc trong repo. Muốn biết tầng nào làm gì, đọc `lib/core`, `lib/domain`, `lib/data`, `lib/features`, `lib/providers`.
- Nạp ngữ cảnh (đã kiểm): omp nạp file ngữ cảnh theo độ sâu thư mục; ở cùng độ sâu, provider ưu tiên cao hơn thắng. `.github/copilot-instructions.md` (provider `github`) thắng `AGENTS.md` gốc (provider `agents-md`), nên khi có cả hai thì `AGENTS.md` bị bỏ qua (đã kiểm: thư mục thử và worktree App). Repo này đặt `.omp/config.yml` với `disabledExtensions: [context-file:project:copilot-instructions.md]`: chỉ file đó bị loại trước khi chọn, `AGENTS.md` giành lại vị trí; provider `github` vẫn đóng góp phần khác. Hệ quả: copilot-instructions không còn tự nạp; đọc nó khi làm animation.
- Tham chiếu cũ cần biết: `D:/Duancanhan/Project_QuanLyGiaiDau/AGENTS.md` (cấp dự án) mục 10 nhắc một file `api_service.dart` trong `lib/data/`; file này KHÔNG tồn tại trong repo (kiểm bằng `git ls-files`).

## E2E App (integration_test)

- Vị trí: `integration_test/` gồm `smoke_test.dart`, `auth_flow_test.dart`, `tournament_player_flow_test.dart`, `organizer_flow_test.dart`. Helper dùng chung ở `integration_test/support/` (`app_driver.dart`, `backend_api.dart`).
- Chạy trên Android emulator API 34 (x86_64) với Backend, Postgres và Redis thật. Job CI: `test-app-e2e` trong `.github/workflows/test-runner.yml` của repo `agent-orchestrator`, dispatch qua skill `cloud-test-runner` với target `app-e2e`. Lệnh dispatch: `python C:/Users/GIGABYTE/.omp/scripts/cloud-test-runner.py run --target app-e2e --app-ref <nhánh> [--specs integration_test/<file>_test.dart ...]` (bỏ `--specs` = chạy toàn bộ `integration_test`).
- Chạy local (cần emulator và Backend đang chạy sẵn): `flutter test integration_test/smoke_test.dart -d emulator-5554`. URL Backend đổi bằng `--dart-define=E2E_API_BASE_URL=...` (mặc định `http://10.0.2.2:3000/api/v1`).
- Cleartext HTTP chỉ bật ở bản debug, tới `10.0.2.2` và `localhost` (`android/app/src/debug/res/xml/network_security_config.xml`). Bản release không có ngoại lệ này; job CI kiểm ở bước 13b bằng manifest release đã gộp và `android/app/src/main/res/xml/network_security_config.xml`.
- Tài khoản seed chỉ dùng cho CI (`backend_api.dart`). Kết quả từng lượt và lỗi app đã biết: `openspec/changes/app-e2e-integration/tasks.md` và `findings.md`.
- Kết quả thật, head app `606a9506`, orchestrator `932f3a6`:
  - `--target app-e2e` đầy đủ, run `39129778085`: job `success` 16,9 phút; `+6: All tests passed!`; bước 13a, 13b (manifest release) và 13c (phân tích tĩnh `integration_test`) đều `success`.
  - `--target app-e2e`, head `d77ac38b`, run `39134290417`: job `success` 17,1 phút; `+6: All tests passed!`; log không có `PATCH /tournaments`, `status=400` hay `EXCEPTION CAUGHT`.
  - `--target app` nhánh feature `app-e2e-integration-20261017`, head `d77ac38b`, run `39134286473`: job `success`, `1132 tests passed, 2 skipped`, hai ca `auto_draw_save_bracket_test` pass. Run `39133359232` (head `c45893a1`) đỏ hai ca này vì lỗi bơm frame của test, đã sửa ở `d77ac38b`. Run `39129778378` và `39132420590` chạy nhánh `main` (`--app-ref` không có tác dụng với target `app`, `test-runner.yml:554`), không dùng làm bằng chứng cho nhánh feature.
  - Bước 13 (emulator và test) của run `39129778085`: boot emulator 105 s, `flutter test` 529 s, trong đó Gradle `assembleDebug` cộng dồn 403 s.
  - Cache NDK/CMake (bước 10d và 13a) chưa được hưởng ở lần nào. Entry `Linux-android-ndk-cmake-c1d57…` có trên `main` (tạo 11:27:34Z, sau bước 13a của run `39122493011`), nhưng run `39128960821` và `39129778085` đều báo restore `not found` và save `Unable to reserve cache`. Bước 13a tốn 35–60 s mỗi run mà không lưu được. Nguyên nhân chưa xác định.

## Lệnh (đã chạy thật, 2026-10-15, worktree `agent-standard` từ `origin/main` `1274c57`)

| Lệnh | Kết quả | Ghi chú |
|---|---|---|
| `flutter test --no-pub test/core/utils/elo_tier_test.dart` (worktree mới, không có `.env`) | exit 1: `No file or variants found for asset: .env.` | `pubspec.yaml` khai báo `.env` làm asset; `.env` gitignored nên worktree không có |
| Cùng lệnh, sau khi tạm `cp .env.example .env` rồi xóa `.env` | exit 1: `+0 -9`, 9/9 test fail | LỖI CÓ SẴN: `resolveEloTier` trả `TS`, `HTA`, `LTC`…; test kỳ vọng `S`, `A`, `C`… Không liên quan thay đổi tài liệu |
| `flutter analyze --no-pub lib/core/utils` | exit 0, "No issues found!" (73,2 giây) | |
| `flutter gen-l10n` | exit 0; `git status` sạch sau lệnh, file sinh khớp `.arb` | CLI in cảnh báo: có `l10n.yaml` nên tham số dòng lệnh bị bỏ qua |
| So khớp key `app_vi.arb` / `app_en.arb` (python, đọc JSON) | exit 0: 4400 key mỗi file, 0 key lệch | chỉ kiểm tên key, không kiểm chất lượng bản dịch |
| `openspec validate --all --strict` | exit 0, 1 change đạt | `agent-docs-map` có `skip_specs: true` |
| `python C:/Users/GIGABYTE/.omp/scripts/openspec-gate.py` | exit 0 | "validate strict ok, không change nào còn task dở" |
| `omp -p --no-session "KHÔNG gọi tool, KHÔNG đọc file… LOADED"` chạy trong worktree | exit 0; liệt kê `~/.omp/agent/AGENTS.md` và `AGENTS.md` của worktree, không có copilot | Sau khi thêm `.omp/config.yml` (`disabledExtensions: context-file:project:copilot-instructions.md`). Trước đó chỉ nạp `.github/copilot-instructions.md`, không nạp `AGENTS.md` |
| `omp -p --no-session` liệt kê tool `mcp__dart_*` trong worktree | exit 0; 23 tool | Đếm từ danh sách tool trong system prompt, chưa gọi tool dart nào |
| `flutter analyze` toàn repo; chạy toàn bộ `test/` | CHƯA CHẠY | Không thử trong lượt này vì nặng; theo skill `cloud-test-runner` |

`flutter pub get` (hook của worktree) đã đổi 7 phiên bản trong `pubspec.lock` đã commit (15 dòng) và ghi lại 7 file `generated_plugin_registrant`/`generated_plugins` của Linux, macOS, Windows. Thay đổi bị hoàn lại trong worktree, không commit.

## Đã biết lệch (chưa sửa; ghi để không lặp lại)

- `test/core/utils/elo_tier_test.dart`: 9/9 test đỏ trên `origin/main` (xem bảng Lệnh).
- `pubspec.lock` trên `origin/main` không khớp kết quả `flutter pub get` hiện tại (7 phiên bản).
- Hai file rỗng (0 byte) được track với đường dẫn lạ: `flutter/.claude/skills` và `HethongFrontEndApp_QLgiaidau/patch_server_terminal.ps1`. Không phải tài liệu, không dùng làm nguồn.
- Ở gốc có 27 file scratch dạng dotfile/script được track (ví dụ `.scan_l10n.py`, `.repair_arb_tail.ps1`, `.l10n-hardcoded-scan.json`, `.untranslated-messages.json`). Không phải tài liệu; không dựa vào.
- Thư mục `changes/` (1 file `.png`: `changes/search-compact-tournament-cards-20260927/evidence/`) có vẻ là dấu vết của quy trình cũ (`new-change.ps1` của workflow cấp dự án; suy luận từ tên thư mục). Giữ làm lưu trữ.

## Bộ tài liệu `.md` đang được git theo dõi (82 file)

| Đường dẫn (gom theo thư mục khi lớn) | Số file | Nhãn | Ghi chú |
|---|---|---|---|
| `README.md` | 1 | tham khảo | Mẫu mặc định Flutter, không mô tả app |
| `thiet-ke-xe-ve-social-he-thong-quan-ly-giai-dau.md` | 1 | tham khảo | Thiết kế đề xuất tính năng Xé vé Social, 854 dòng, sửa 2026-09-28; đối chiếu code trước khi dựa vào |
| `.github/copilot-instructions.md` | 1 | chuẩn | Luật cho animation/motion. Tham chiếu tới `.github` và `.agents` của workspace cha, ngoài repo này |
| `.agents/skills/flutter-animation/SKILL.md` | 1 | chuẩn | Skill animation, đọc trước khi sửa animation |
| `.agents/skills/` (65 file còn lại) | 65 | tham khảo | Bộ skill dùng chung (debugging, plan, review, superpowers…), không phải luật của dự án này |
| `.hermes/plans/` (2 file) | 2 | kế hoạch cũ | `2026-07-27-app-lite-manager-plan.md` (sửa 2026-07-28), `2026-08-15_233600-community-social-parity-flutter.md` (sửa 2026-08-16). Không lấy làm mô tả hệ thống |
| `.hermes/chat-parity-audit.md` | 1 | kế hoạch cũ | Ghi chú đối chiếu chat với Web, 2026-08-16, 6 dòng |
| `test_docs/flutter-test-plan.md` | 1 | kế hoạch cũ | Kế hoạch test, sửa 2026-07-14, 881 dòng |
| `test_docs/testcases-*.md` (4 file) | 4 | tham khảo | Test case sửa 2026-07-14: Auth/Payment/Notification, Bracket/Match/Ranking, Community/Referee/Admin, Home/Dashboard/Upload. Cùng thư mục có `testcases.json`, `testcases.xlsx`, `update-results.py` (không phải md) |
| `assets/icons/README.md`, `assets/images/README.md`, `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` | 3 | tham khảo | Ghi chú thư mục 4 dòng |
| `AGENTS.md`, `docs/README.md` | 2 | chuẩn | Luật cho agent và chính bản đồ này (ở gốc repo và `docs/`) |

## Ghi tài liệu mới ở đâu

- Kế hoạch hoặc spec cho một thay đổi: `openspec/changes/<id>/` qua `/opsx-propose`. KHÔNG tạo `*_PLAN.md`, `*_SPEC.md` trong `docs/`, ở gốc repo, hay ở thư mục cha của repo. Không tạo kế hoạch mới trong `.hermes/`.
- Kiến thức lâu dài về app: sửa đúng nguồn (code, `.arb`, `pubspec.yaml`), hoặc sửa tài liệu có nhãn chuẩn/tham khảo tương ứng ở bảng trên, rồi cập nhật nhãn.
- Kiểm tài liệu lệch code: ripwire `doc_drift` với `path` = gốc repo. Chỉ kiểm anchor; kết quả là "cần xem", không kết luận tài liệu sai.
