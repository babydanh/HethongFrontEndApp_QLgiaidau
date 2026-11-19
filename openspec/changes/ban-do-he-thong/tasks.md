# Tasks

Quy ước: lệnh chạy ở gốc worktree App `V:/Duancanhan/Project_QuanLyGiaiDau/HethongFrontEndApp_QLgiaidau.worktrees/ban-do-he-thong`. "Backend x.y" là task trong `HethongBackendApi_QuanlyGiaiDau.worktrees/ban-do-he-thong/openspec/changes/ban-do-he-thong/tasks.md`; Backend gộp trước App. Change không sửa `lib/`, `test/`, `pubspec.*`, `.arb`.

Chuỗi song song (`Files:` không trùng):
- Đầu: 1.1 (script định vị) · 4.2 (CI paths-ignore) — độc lập nhau.
- Sau 1.1 + Backend 1.2/2.6: 2.1 (scaffold) → bốn chuỗi song song 3.1 · 3.2 · 3.3 · 3.4 (mỗi chuỗi chờ Backend 3.x cùng nhóm).
- Cuối: 4.1 → 5.1.

Brief cho worktree con (3.x do `git-wt` tạo với tên nhánh khác `ban-do-he-thong`) PHẢI đặt `SYSTEM_MAP_BACKEND=<worktree Backend của phiên>`; thiếu thì `run.mjs` rơi về checkout chính và in `W103`/`W104`. Lệnh `check` trong Tiêu chí trước 4.1 dùng `--no-docs` (`docs/system-map/**` chỉ có từ 4.1).

## 0. Rà soát

- [ ] 0.1 Cross-check by a fresh-context reviewer. Tiêu chí: no open P0/P1
  - Kết quả:

## 1. Hợp đồng gọi bộ kiểm

- [ ] 1.1 Viết `scripts/system-map/run.mjs` (Node, không phụ thuộc gói): định vị Backend theo thứ tự `--backend` → `SYSTEM_MAP_BACKEND` → `<gốc dự án>/HethongBackendApi_QuanlyGiaiDau.worktrees/<nhánh hiện tại>` → `<gốc dự án>/HethongBackendApi_QuanlyGiaiDau` (gốc dự án suy từ `git rev-parse --git-common-dir`), in `system-map: backend = <path> (<via>, <sha>)`, gọi `process.execPath <backend>/scripts/system-map/cli.mjs <lệnh> --surface app --root <app> --backend <backend> …` bằng argv (không shell), trả nguyên mã thoát; không tìm thấy → exit 2. Cảnh báo `W103` khi dùng checkout chính mà nó bẩn, không ở `main` hoặc `HEAD` khác `origin/main`; `W104` khi Backend từ `--backend`/env/cùng tên nhánh có `HEAD` chưa là tổ tiên của `origin/main`; `SYSTEM_MAP_STRICT_BACKEND=1` đổi hai cảnh báo này thành exit 2 trước khi gọi CLI. Tiêu chí: `node --test scripts/system-map/run.test.mjs` → exit 0 (ca: thứ tự ưu tiên 4 nguồn trên thư mục giả; nguồn thiếu `cli.mjs` bị bỏ qua; không nguồn nào → `null` và exit 2; mã thoát 1 của `cli.mjs` giả được trả nguyên; repo git giả: checkout chính sau `origin/main` → in `W103`, cùng cảnh đó với `SYSTEM_MAP_STRICT_BACKEND=1` → exit 2 và không gọi CLI; worktree có commit chưa vào `origin/main` → `W104`)
  - Files: tạo `scripts/system-map/run.mjs`, `scripts/system-map/run.test.mjs`
  - Giao: `findBackend(appRoot: string, env: Record<string, string | undefined>, argv: string[]): { path: string, via: 'flag' | 'env' | 'sibling' | 'main', warnings: ('W103' | 'W104')[] } | null` · lệnh `node scripts/system-map/run.mjs <check|build|scaffold|show> [--only …] [--no-diagrams] [--no-docs] [--prune] [--json]` cho 2.1–5.1 và Backend 6.3
  - Nhận: giao diện CLI Backend 2.6 `node scripts/system-map/cli.mjs <check|build|scaffold|show> --surface app --root <repo> --backend <path> [...]`, exit 0/1/2
  - Chủ file chung: (không)
  - Phụ thuộc: sau 0.1

## 2. Danh sách chờ

- [ ] 2.1 Chạy `node scripts/system-map/run.mjs scaffold` (Backend worktree cùng tên nhánh đã có 1.2 + 2.6) để sinh `system-map/pending/<phân-hệ>.yaml` cho 99 route App theo quy tắc `app` của hợp đồng. Tiêu chí: `node scripts/system-map/run.mjs check --no-diagrams --no-docs` → exit 0 và tổng số mục `screen:` trong `system-map/pending/*.yaml` = 99
  - Files: tạo `system-map/pending/*.yaml` (một file mỗi phân hệ có route, `_chua-xep.yaml` nếu có)
  - Giao: pending ban đầu cho 3.1–3.4 · Nhận: lệnh của 1.1; hợp đồng Backend 1.2
  - Chủ file chung: 2.1 tạo; từ 3.x mỗi task chỉ sửa file pending của phân hệ mình
  - Phụ thuộc: sau 1.1, Backend 1.2, Backend 2.6

## 3. Gắn route và màn (4 chuỗi song song)

- [ ] 3.1 Nhóm A — `giai-dau`, `noi-dung-thi-dau`, `dang-ky-vdv`, `giai-lite`, `chuoi-giai`: gắn route/màn/sheet (kể cả `DivisionEditorSheet`, `TournamentManagementDispatcher` ở `/organizer/tournaments/:id/manage`, `/register/:id*`, `/lite*`, `/series*`, `/scan-qr` — quy tắc `app` xếp vào `giai-dau` nên 3.1 là chủ duy nhất) vào ô CRUD/`actions` của tính năng Backend; route chỉ có ở App thành `local_features`; xoá route đã gắn khỏi pending. Tiêu chí: `node scripts/system-map/run.mjs check --only giai-dau,noi-dung-thi-dau,dang-ky-vdv,giai-lite,chuoi-giai --no-diagrams --no-docs` → exit 0 và 5 file pending tương ứng không còn mục `screen:`
  - Files: tạo `system-map/{giai-dau,noi-dung-thi-dau,dang-ky-vdv,giai-lite,chuoi-giai}.yaml`; sửa `system-map/pending/{giai-dau,noi-dung-thi-dau,dang-ky-vdv,giai-lite,chuoi-giai}.yaml`
  - Giao: (không) · Nhận: id tính năng + ô CRUD của Backend 3.1
  - Chủ file chung: (không)
  - Phụ thuộc: sau 2.1, Backend 3.1

- [ ] 3.2 Nhóm B — `so-do`, `lich-san`, `tran-dau`, `xep-hang` (`…/bracket`, `…/swiss-pairing/:divisionId`, `…/draw`, `/live/:matchId`, `/referee`, `/viewer`, `/matches`, `/rankings`, `/profile/elo`). Tiêu chí: như 3.1 với `--only so-do,lich-san,tran-dau,xep-hang` → exit 0, 4 file pending không còn `screen:`
  - Files: tạo `system-map/{so-do,lich-san,tran-dau,xep-hang}.yaml`; sửa `system-map/pending/{so-do,lich-san,tran-dau,xep-hang}.yaml`
  - Giao: (không) · Nhận: Backend 3.2
  - Chủ file chung: (không)
  - Phụ thuộc: sau 2.1, Backend 3.2

- [ ] 3.3 Nhóm C — `cong-dong`, `giao-luu`, `chat`, `thong-bao` (`/club*`, `/clubs/:id`, `/communities/:id`, `/football-teams`, `/social/:id`, `/chat`, `/notifications`). Tiêu chí: như 3.1 với `--only cong-dong,giao-luu,chat,thong-bao` → exit 0, 4 file pending không còn `screen:`
  - Files: tạo `system-map/{cong-dong,giao-luu,chat,thong-bao}.yaml`; sửa `system-map/pending/{cong-dong,giao-luu,chat,thong-bao}.yaml`
  - Giao: (không) · Nhận: Backend 3.3
  - Chủ file chung: (không)
  - Phụ thuộc: sau 2.1, Backend 3.3

- [ ] 3.4 Nhóm D — `tai-khoan`, `thanh-toan`, `livestream`, `quan-tri`, `nen-tang` (`/`, `/login*`, `/profile*`, `/user(s)/:id`, `/payment*`, `/live/device-pairing/:communityId`, `/admin*`; `/scan-qr` do 3.1 giữ). Tiêu chí: như 3.1 với `--only tai-khoan,thanh-toan,livestream,quan-tri,nen-tang` → exit 0, 5 file pending không còn `screen:`, `system-map/pending/_chua-xep.yaml` rỗng hoặc không tồn tại
  - Files: tạo `system-map/{tai-khoan,thanh-toan,livestream,quan-tri,nen-tang}.yaml`; sửa `system-map/pending/{tai-khoan,thanh-toan,livestream,quan-tri,nen-tang,_chua-xep}.yaml`
  - Giao: (không) · Nhận: Backend 3.4
  - Chủ file chung: (không)
  - Phụ thuộc: sau 2.1, Backend 3.4

## 4. Router, tài liệu sinh, CI

- [ ] 4.1 Thêm mục "Bản đồ hệ thống" vào `AGENTS.md` (≤ 6 dòng: đọc `llms.txt`/`docs/system-map/README.md` trước khi sửa tính năng; thêm `GoRoute` thì sửa `system-map/<phân-hệ>.yaml` cùng commit; `node scripts/system-map/run.mjs check`; `node scripts/system-map/run.mjs show <id>`; nếu chủ dự án chọn 5B thì đổi lệnh `--check` mẫu thành `"python C:/Users/GIGABYTE/.omp/scripts/openspec-gate.py && node scripts/system-map/run.mjs check"`); thêm dòng vào bảng `docs/README.md`; chạy `node scripts/system-map/run.mjs build`. Tiêu chí: `node scripts/system-map/run.mjs check` → exit 0 và `git diff --exit-code -- docs/system-map llms.txt` sau lần `build` thứ hai → exit 0
  - Files: tạo `docs/system-map/README.md`, `docs/system-map/screens.md`, `docs/system-map/subsystems/*.md`, `docs/system-map/roadmap.md`, `llms.txt`; sửa `AGENTS.md`, `docs/README.md`
  - Giao: (không) · Nhận: tệp gắn 3.1–3.4, `llms.txt` Backend 5.1
  - Chủ file chung: 4.1 giữ `AGENTS.md`, `docs/README.md`, `docs/system-map/**`, `llms.txt`
  - Phụ thuộc: sau 3.1, 3.2, 3.3, 3.4, Backend 5.1

- [ ] 4.2 Thêm `'system-map/**'`, `'scripts/system-map/**'`, `'llms.txt'` vào `paths-ignore` của `.github/workflows/ci.yml` (dòng 6). Tiêu chí: `node -e "const s=require('fs').readFileSync('.github/workflows/ci.yml','utf8');const l=s.split('\n').find(x=>x.includes('paths-ignore'));process.exit(['system-map/**','scripts/system-map/**','llms.txt'].every(p=>l.includes(\"'\"+p+\"'\"))?0:1)"` → exit 0
  - Files: sửa `.github/workflows/ci.yml:6`
  - Giao/Nhận: (không)
  - Chủ file chung: 4.2 giữ `.github/workflows/ci.yml`
  - Phụ thuộc: sau 0.1

## 5. Kiểm cuối

- [ ] 5.1 Kiểm không đổi Dart + test liên quan + cổng bản đồ (+ cloud). Tiêu chí: `git diff --stat origin/main -- lib test pubspec.yaml pubspec.lock` rỗng (không sửa thư mục Dart nào nên không có thư mục cần `flutter analyze`; nếu có file Dart bị sửa thì chạy `flutter analyze --no-pub <thư mục đó>` → exit 0); `node --test scripts/system-map/run.test.mjs` → exit 0; `node scripts/system-map/run.mjs check` → exit 0 (Backend cùng nhánh chưa gộp nên `W104` là cảnh báo đúng; không đặt `SYSTEM_MAP_STRICT_BACKEND`); target cloud `python C:/Users/GIGABYTE/.omp/scripts/cloud-test-runner.py run --target system-map --backend-ref ban-do-he-thong --web-ref ban-do-he-thong --app-ref ban-do-he-thong` → exit 0 (chạy trên cloud, sau Backend 6.2)
  - Files: (không sửa)
  - Giao/Nhận: (không)
  - Chủ file chung: (không)
  - Phụ thuộc: sau 4.1, 4.2, Backend 6.2
