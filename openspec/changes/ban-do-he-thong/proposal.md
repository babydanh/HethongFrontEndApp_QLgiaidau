## Why

Agent vào repo App không có chỗ trả lời "tính năng X ở màn nào, sheet nào, gọi route API nào, thuộc phân hệ nào". App có 99 `GoRoute(` trong `lib/core/router/app_router.dart` (nhiều route con dùng đường dẫn tương đối, ví dụ `bracket` dưới `/organizer/tournaments/:id/manage`), 80 file `*_screen.dart`/`*_page.dart`, 24 thư mục `lib/features/*`; nhiều thao tác nằm trong sheet/section chứ không có route riêng (tạo nội dung thi đấu = `lib/features/tournament/widgets/division_editor_sheet.dart`). Bản đồ API `~/.omp/api-map/` nằm ngoài repo và không có phân hệ/vai trò.

Change này là phần App của "bản đồ hệ thống cho AI"; hợp đồng phân hệ, danh mục tính năng và bộ kiểm nằm ở repo Backend (change `ban-do-he-thong` của Backend).

## What Changes

- Thêm **tệp gắn App** `system-map/<phân-hệ>.yaml`: gắn ô CRUD/thao tác của tính năng (id do Backend định nghĩa) vào route `GoRoute` + file Dart + chuỗi neo + route API App gọi; `local_features` cho tính năng chỉ có ở App (splash, màn chờ đăng nhập, quét QR…).
- Thêm **danh sách chờ có chốt chặn** `system-map/pending/<phân-hệ>.yaml` cho route chưa gắn (chỉ được giảm).
- Thêm **script định vị** `scripts/system-map/run.mjs` (Node, không phụ thuộc gói) gọi `scripts/system-map/cli.mjs` của Backend với `--surface app`; lệnh: `node scripts/system-map/run.mjs <check|build|scaffold|show>`.
- **Tự sinh** `docs/system-map/` (mục lục, bản đồ màn: route → màn → tính năng → API, trang từng phân hệ cột App, roadmap) và `llms.txt`.
- Thêm mục "Bản đồ hệ thống" vào `AGENTS.md`, thêm dòng vào `docs/README.md`.
- Thêm `system-map/**`, `scripts/system-map/**`, `llms.txt` vào `paths-ignore` của `.github/workflows/ci.yml` (sửa danh mục không chạy lại `flutter analyze` + `flutter test` 30 phút).

### Out of scope (KHÔNG làm)

- Không sửa `lib/`, `test/`, `pubspec.yaml`, `pubspec.lock`, file `.arb`; không thêm package Dart hay npm.
- Không vẽ sơ đồ Archify riêng cho App (sơ đồ bắt buộc của tính năng nằm ở Backend; App chưa có sơ đồ nào).
- Không thêm bước kiểm bản đồ vào `ci.yml` (App public nhưng bộ kiểm cần checkout Backend private, App không có secret đọc Backend).
- Không đụng 7 file `generated_plugin_registrant`/`generated_plugins` đang bị `flutter pub get` sửa sẵn trong worktree (không phải của change này).

## Capabilities

### New Capabilities

- `system-map-app`: tệp gắn route/màn App vào tính năng của danh mục chung, kiểm qua bộ kiểm của Backend, tài liệu sinh cho AI và router trong `AGENTS.md`.

### Modified Capabilities

(không có)

## Impact

- File mới: `system-map/*.yaml`, `system-map/pending/*.yaml`, `scripts/system-map/run.mjs`, `scripts/system-map/run.test.mjs`, `docs/system-map/**` (sinh), `llms.txt` (sinh).
- File sửa: `AGENTS.md`, `docs/README.md`, `.github/workflows/ci.yml` (`paths-ignore`).
- Repo khác: Backend `HethongBackendApi_QuanlyGiaiDau` change `ban-do-he-thong` (hợp đồng `system-map/subsystems.yaml`, danh mục `system-map/features/*.yaml`, bộ kiểm `scripts/system-map/cli.mjs`); khoá nối là chuỗi route API như `POST /tournaments/:id/divisions`. Không đổi endpoint/field nào. Web `HethongFrontEndWeb_QLgiaidau` change `ban-do-he-thong` làm phần tương tự cho trang Next.js.
- Cổng: `merge-lane.py` (máy) và target `system-map` của `agent-orchestrator` (cloud) chạy `check --surface app`.
