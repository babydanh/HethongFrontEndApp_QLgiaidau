## Purpose

Phần App của bản đồ hệ thống cho AI: mọi `GoRoute` của App được gắn vào tính năng trong danh mục chung do Backend giữ, được kiểm tự động bằng bộ kiểm của Backend, và có tài liệu sinh cho agent đọc trước khi sửa.

## ADDED Requirements

### Requirement: Mọi route App được gắn vào danh mục

Mọi `GoRoute` trong `lib/core/router/app_router.dart`, với khoá là đường dẫn đầy đủ sau khi ghép path con tương đối với path cha, MUST xuất hiện trong ít nhất một mục gắn của `system-map/<phân-hệ>.yaml` (trong `bindings` hoặc `local_features`), hoặc nằm trong `system-map/pending/*.yaml`. Danh sách pending SHALL chỉ được giảm: mục pending không có ở `git merge-base HEAD origin/main` MUST bị báo `SM017`, trừ lần bootstrap khi mốc đó chưa có `system-map/pending/`.

#### Scenario: Route con được ghép đúng và đã gắn
- **WHEN** `GoRoute(path: 'bracket')` nằm trong route `/organizer/tournaments/:id/manage` và tệp gắn có mục với `route: /organizer/tournaments/:id/manage/bracket`
- **THEN** `node scripts/system-map/run.mjs check` thoát mã 0

#### Scenario: Route mới chưa gắn
- **WHEN** một nhánh thêm `GoRoute(path: '/club/:id/awards')` mà không gắn và không có trong pending
- **THEN** `check` báo `SM001` với khoá route và dòng trong `app_router.dart`, thoát mã 1

#### Scenario: Pending còn route đã gắn
- **WHEN** route `/payments` đã có mục gắn nhưng vẫn còn trong `system-map/pending/thanh-toan.yaml`
- **THEN** `check` báo `SM002` và gợi ý `node scripts/system-map/run.mjs scaffold --prune`, thoát mã 1

### Requirement: Mục gắn trỏ đúng code App và đúng danh mục Backend

Mỗi mục gắn MUST có `route` là khoá `GoRoute` có thật, `file` Dart có thật, `anchor` có mặt trong `file`, tính năng và ô có trong danh mục Backend, và `api` (nếu có) thuộc danh sách `api` của ô đó. `local_features` MUST có id `<phân-hệ>.<slug>` với phân hệ có trong hợp đồng Backend và không trùng id tính năng Backend.

#### Scenario: Mục gắn hợp lệ
- **WHEN** ô `create` của `noi-dung-thi-dau.quan-ly-noi-dung` gắn `lib/features/tournament/widgets/division_editor_sheet.dart` với neo `class DivisionEditorSheet` và `api: POST /tournaments/:id/divisions`
- **THEN** `check` không báo lỗi cho mục này

#### Scenario: Neo mất hoặc tính năng không tồn tại
- **WHEN** lớp bị đổi tên nên file không còn chuỗi neo, hoặc mục gắn trỏ `noi-dung-thi-dau.khong-co`
- **THEN** `check` báo `SM010` kèm file tệp gắn, tính năng, ô và lý do; thoát mã 1

### Requirement: Kiểm App dùng bộ kiểm của Backend

`node scripts/system-map/run.mjs <lệnh>` MUST gọi bộ kiểm trong checkout Backend tìm theo thứ tự: tham số `--backend`, biến môi trường `SYSTEM_MAP_BACKEND`, worktree Backend cùng tên nhánh, checkout chính Backend; MUST in đường dẫn, cách tìm, commit Backend đã dùng; MUST trả nguyên mã thoát; MUST NOT cần package npm hay Dart mới. Khi `SYSTEM_MAP_STRICT_BACKEND=1`, lệnh MUST thoát mã 2 nếu checkout chính Backend lệch `origin/main` (`W103`) hoặc Backend tìm được chưa vào `origin/main` (`W104`).

#### Scenario: Dùng checkout chính khi không có worktree cùng tên
- **WHEN** đang ở worktree App nhánh `x` và không có `HethongBackendApi_QuanlyGiaiDau.worktrees/x`
- **THEN** lệnh dùng `HethongBackendApi_QuanlyGiaiDau` và in `(main, <sha>)`

#### Scenario: Không tìm thấy Backend
- **WHEN** không nguồn nào có `scripts/system-map/cli.mjs`
- **THEN** lệnh in các chỗ đã tìm cùng cách đặt `SYSTEM_MAP_BACKEND`, thoát mã 2 và không ghi file nào

#### Scenario: Cổng gộp dựa trên Backend chưa gộp
- **WHEN** cổng gộp chạy `node scripts/system-map/run.mjs check` với `SYSTEM_MAP_STRICT_BACKEND=1` và `SYSTEM_MAP_BACKEND` trỏ worktree Backend có commit chưa vào `origin/main`
- **THEN** lệnh in `W104`, thoát mã 2 và không gọi bộ kiểm

### Requirement: Tài liệu sinh và router cho agent App

`node scripts/system-map/run.mjs build` SHALL sinh tất định `docs/system-map/README.md`, `docs/system-map/screens.md` (route → dòng router → màn → tính năng/ô → route API), `docs/system-map/subsystems/<id>.md`, `docs/system-map/roadmap.md` và `llms.txt`; `check` MUST báo `SM015` khi file đã commit lệch. `AGENTS.md` MUST có mục "Bản đồ hệ thống" trỏ tới `llms.txt` và `docs/system-map/README.md`.

#### Scenario: Agent mới đọc router
- **WHEN** một session mở trong repo App
- **THEN** `AGENTS.md` có mục "Bản đồ hệ thống" nêu file cần đọc và lệnh kiểm

#### Scenario: Tài liệu cũ
- **WHEN** tệp gắn đổi mà không chạy `build`
- **THEN** `check` báo `SM015` liệt kê file lệch, thoát mã 1

### Requirement: Sửa danh mục không chạy CI Flutter

Push nhánh chỉ thay đổi `system-map/**`, `scripts/system-map/**` hoặc `llms.txt` (cùng các đường dẫn tài liệu đã bỏ qua sẵn) MUST NOT kích hoạt `.github/workflows/ci.yml`.

#### Scenario: Commit chỉ có danh mục
- **WHEN** push nhánh có commit chỉ sửa `system-map/giai-dau.yaml` và `docs/system-map/screens.md`
- **THEN** workflow `CI` không chạy

#### Scenario: Commit có code Dart
- **WHEN** commit sửa thêm một file trong `lib/`
- **THEN** workflow `CI` chạy `flutter analyze` và `flutter test` như hiện nay
