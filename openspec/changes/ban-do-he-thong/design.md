# Design: Bản đồ hệ thống — phần App

Bản chuẩn cho phần dùng chung (phương án A và hai phương án bị loại, hợp đồng 18 phân hệ, định dạng YAML, mã lỗi `SM001`–`SM016`, luật sơ đồ Archify, chỗ đặt cổng CI, 5 câu hỏi mở): `V:/Duancanhan/Project_QuanLyGiaiDau/HethongBackendApi_QuanlyGiaiDau.worktrees/ban-do-he-thong/openspec/changes/ban-do-he-thong/design.md` (sau khi gộp: `HethongBackendApi_QuanlyGiaiDau/openspec/changes/ban-do-he-thong/design.md`, rồi `openspec/specs/system-map/spec.md`). File này chỉ ghi phần riêng của App.

## 1. Số đo thật (worktree `ban-do-he-thong`, từ `origin/main` `248fe4ac`)

| Đại lượng | Số |
|---|---|
| `GoRoute(` trong `lib/core/router/app_router.dart` | 99 (một `GoRouter`, không có `ShellRoute`/`StatefulShellRoute`) |
| File `*_screen.dart` / `*_page.dart` | 80, nhiều nhất ở `community` 12, `tournament` 7, `admin` 6 |
| Thư mục `lib/features/*` | 24 |
| Sơ đồ Archify | 0 |
| CI | `.github/workflows/ci.yml` chạy được (repo public): `flutter analyze` + `flutter test` trên push nhánh ≠ `main`, `paths-ignore` hiện có `openspec/**`, `.omp/**`, `docs/**`, `changes/**`, `.lavish/**`, `**/*.md` |

Quy tắc nhận biết App trong hợp đồng Backend (mô phỏng, đã ghép path con với cha): 99/99 route xếp được. Phân bố: `quan-tri` 17, `cong-dong` 17, `tai-khoan` 14, `giai-dau` 13, `tran-dau` 7, `chuoi-giai` 6, `so-do` 5, `dang-ky-vdv` 5, `giai-lite` 5, `thanh-toan` 4, `chat` 2, `giao-luu` 1, `xep-hang` 1, `livestream` 1, `thong-bao` 1; `noi-dung-thi-dau`, `lich-san`, `nen-tang` 0 route (thao tác nằm trong sheet/section).

## 2. Lựa chọn riêng của App

1. **Khoá route = đường dẫn đầy đủ sau khi ghép cha–con.** Ví dụ `GoRoute(path: 'bracket')` nằm trong `/organizer/tournaments/:id/manage` (dòng 436) có khoá `/organizer/tournaments/:id/manage/bracket`. Bộ trích của Backend (task Backend 2.2) phân tích ngoặc để ghép; tệp gắn dùng khoá đầy đủ này.
2. **Gắn theo file + neo.** Như Web: `route` (route chứa), `file` (màn/sheet/section làm thao tác), `anchor` (chuỗi có trong file, ví dụ `class DivisionEditorSheet`), `api` (route Backend App gọi). Không dùng số dòng.
3. **Bộ kiểm chạy bằng Node.** App không có Node trong toolchain chính nhưng đã có `package.json` (gói `sharp`) và Node có sẵn trên máy dev và runner `ubuntu-latest`. `scripts/system-map/run.mjs` không phụ thuộc gói; test bằng `node --test` (không thêm vào `flutter test`). Loại phương án viết bộ kiểm riêng bằng Dart (`dart run`): sẽ là bản thứ hai của cùng luật, phải thêm `yaml` vào `dev_dependencies`.
4. **Định vị Backend** giống Web: `--backend` → `SYSTEM_MAP_BACKEND` → `<gốc dự án>/HethongBackendApi_QuanlyGiaiDau.worktrees/<nhánh hiện tại>` → `<gốc dự án>/HethongBackendApi_QuanlyGiaiDau`; in `system-map: backend = <path> (<via>, <sha>)`; không thấy → exit 2. Worktree con của chuỗi có tên nhánh khác nên brief PHẢI đặt `SYSTEM_MAP_BACKEND`. `run.mjs` in `W103` (checkout chính bẩn, không ở `main` hoặc `HEAD` khác `origin/main`) và `W104` (Backend tìm được chưa vào `origin/main`); `SYSTEM_MAP_STRICT_BACKEND=1` (cổng gộp, CI) đổi chúng thành exit 2. Đường dẫn tuyệt đối thay vì `../` vì từ worktree `../` trỏ sai (đã ghi ở `docs/README.md` dòng 18).
5. **`local_features`** cho route chỉ có ở App: `/` (`SplashScreen`), `/login-loading`, `/scan-qr`, `/intro/:id` nếu không gắn được vào tính năng Backend. `/scan-qr` theo quy tắc `app` thuộc `giai-dau` nên task 3.1 là chủ duy nhất (gắn hoặc làm `local_features` id `giai-dau.<slug>`).

Ví dụ tệp gắn (trích code thật):

```yaml
# system-map/noi-dung-thi-dau.yaml
subsystem: noi-dung-thi-dau
bindings:
  noi-dung-thi-dau.quan-ly-noi-dung:
    create:
      - route: /organizer/tournaments/:id/manage          # app_router.dart:436
        file: lib/features/tournament/widgets/division_editor_sheet.dart
        anchor: class DivisionEditorSheet                  # dòng 209; gọi createDivision ở dòng 1694
        api: POST /tournaments/:id/divisions
    update:
      - route: /organizer/tournaments/:id/manage
        file: lib/features/tournament/widgets/division_editor_sheet.dart
        anchor: .updateDivision(_divisionId                # dòng 1690
        api: PATCH /tournaments/divisions/:divisionId
    delete:
      - route: /organizer/tournaments/:id/manage
        file: lib/features/tournament/screens/tournament_management_divisions_section.dart
        anchor: _deleteDivision(division)                  # dòng 172
        api: DELETE /tournaments/divisions/:divisionId
```

Tệp gắn không bắt buộc đủ 4 ô: ô Backend chưa có màn App hiện là `W101` trong `roadmap.md` (mức đỏ/cảnh báo theo câu hỏi mở số 1 của Backend).

## 3. Tài liệu sinh của App

`node scripts/system-map/run.mjs build` ghi, không sửa tay:
- `docs/system-map/README.md`: phân hệ → số route, số mục gắn, độ phủ thao tác Backend có màn App.
- `docs/system-map/screens.md`: **bản đồ màn** — mỗi khoá route → dòng trong `app_router.dart` → tên màn trong `builder` → tính năng/ô gắn vào → route API.
- `docs/system-map/subsystems/<id>.md`: bảng CRUD của từng tính năng với cột App.
- `docs/system-map/roadmap.md`: route còn trong pending, ô Backend chưa có màn App (`W101`).
- `llms.txt`: tóm tắt App, link các file trên, link `llms.txt` Backend/Web bằng đường dẫn tuyệt đối checkout chính.

## 4. Cổng

- `merge-lane.py` (máy): `SYSTEM_MAP_STRICT_BACKEND=1 node scripts/system-map/run.mjs check` (`run.mjs` tự thêm `--surface app`) — tự chạy nếu chủ dự án chọn 5A (câu hỏi mở Backend), nếu không thì ghi vào lệnh `--check` mẫu trong `AGENTS.md` (`--check "python C:/Users/GIGABYTE/.omp/scripts/openspec-gate.py && node scripts/system-map/run.mjs check"`).
- Cloud: target `system-map` của `agent-orchestrator` chạy `check --surface app` với `app_ref` (task Backend 6.2).
- `ci.yml`: không thêm bước kiểm (thiếu quyền đọc Backend private); thêm `system-map/**`, `scripts/system-map/**`, `llms.txt` vào `paths-ignore` để commit chỉ sửa danh mục không tốn 30 phút Flutter.

## 5. Phụ thuộc chéo repo

- App 1.1 cần giao diện CLI Backend 2.6 (test dùng `cli.mjs` giả nên làm song song được).
- App 2.1 (scaffold) cần Backend 1.2 (quy tắc `app`) + Backend 2.6.
- App 3.x cần Backend 3.x cùng nhóm.
- App 4.1 (`llms.txt` trỏ `llms.txt` Backend) cần Backend 5.1.
- Worktree con (3.x) đặt `SYSTEM_MAP_BACKEND` trỏ worktree Backend của phiên.
- Thứ tự gộp: Backend trước, App sau; cổng gộp App với `SYSTEM_MAP_STRICT_BACKEND=1` dừng (exit 2) nếu Backend dùng làm hợp đồng chưa vào `origin/main`.

## 6. Câu hỏi mở

Dùng chung 5 câu ở `design.md` Backend mục 11. Câu 1 (ô có API mà App chưa có màn: đỏ hay roadmap) và câu 5 (cổng ở máy) ảnh hưởng trực tiếp repo này. Không có câu hỏi riêng của App.
