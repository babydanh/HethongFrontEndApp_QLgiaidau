# Handoff: App nhập Excel — popup ghép cột (ĐỢT 1)
Cập nhật: 2026-11-14 · bởi: claude · nhánh: app-ghep-cot-dot1 (từ cloud/danh3-app-nhap-excel-ghep-cot-113202) · OpenSpec: app-nhap-excel-ghep-cot

## Mục tiêu
**NGƯỜI DÙNG ĐÃ NÓI "APPLY": VIẾT CODE ĐỢT 1 THEO `tasks.md`.** Đợt 1 = nhóm 1–3, tức task 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 3.1, 3.2. **KHÔNG làm nhóm 4–5 (đợt 2: danh sách thẻ, chi tiết sửa được, tách `roster_import_sheet.dart` 4.1).** Xong đợt 1 thì popup `Ghép cột` mở được từ màn Nhập Excel, người dùng chỉnh cột/hàng tiêu đề/cách ghép cặp, bấm `Xong` thì dòng được đọc lại; phần còn lại của màn Nhập Excel (xem trước, kiểm tra trên máy chủ, nhập) giữ nguyên hành vi.

Đọc theo thứ tự: `proposal.md` → `design.md` (đặc biệt mục "Đã kiểm lại bản bàn giao", D2, D7, D10) → `specs/app-roster-column-mapping/spec.md` → `tasks.md` (mục "Ghi chú chung" + nhóm 1–3). Bản vẽ giao diện: `mockup.html` cùng thư mục (mở bằng trình duyệt; khung 2 và 5 là popup; dữ liệu giả). Đừng làm theo khung 1 phần nút `Tiếp tục` (D10: không có nút đó).

## Trạng thái
- Xong: kế hoạch OpenSpec đủ 4 artifact, `openspec validate app-nhap-excel-ghep-cot --strict` exit 0 (PR #29, nhánh `cloud/danh3-app-nhap-excel-ghep-cot-113202`).
- Đang dở: chưa có dòng code nào; `tasks.md` còn 0/16 `[x]`.
- Tiếp theo: làm TUẦN TỰ 1.1 → 1.2 → 1.3 → 1.4 → 2.1 → 2.2 → 3.1 → 3.2 trong MỘT worktree (các task chung file `roster_excel_parser.dart`, `roster_layout.dart`, `roster_import_sheet.dart`, không chia agent). Mỗi task: viết test đỏ trước (chạy thấy đỏ đúng lý do), code tối thiểu cho xanh, chạy đúng lệnh ở `Tiêu chí`, rồi mới đổi `- [ ]` thành `- [x]`, commit hẹp. Task 3.2 là cổng đợt 1.

## Quyết định của người dùng cho lần apply này
- Làm **đợt 1 trước**, đợt 2 sau (người dùng nói "apply", không chọn khác → theo đề xuất).
- `Xóa cặp` / `+ Thêm VĐV` thuộc đợt 2: chưa làm.
- Không có nút `Tiếp tục` (D10).
- **Không đổi Backend/Web/hợp đồng API.** Email/tài khoản Sporto: dùng nguyên `POST /tournaments/{id}/roster-import-batches/preview` (đã trả `status` + `accountCandidates`); popup ghép cột KHÔNG tự tìm tài khoản; sau `Xong`, luồng preview hiện có chạy như cũ (xem D7).
- Giao diện ít chữ, icon SVG, vùng chạm ≥ 44 dp, màu từ `context.colors`/`AppTheme` (không hardcode), đúng cả chế độ tối.
- Không thêm package. Chuỗi mới có đủ cả `app_vi.arb` và `app_en.arb`, rồi `flutter gen-l10n`, commit cả `app_localizations*.dart` sinh ra, không sửa tay.
- Không nhét chữ che lỗi ("Chưa xác định"…) vào chỗ thiếu dữ liệu.

## Cách chạy và kiểm (máy cloud)
- Thay `flutter` bằng `cloud-flutter` (cùng tham số) như `Ghi chú chung` của `tasks.md`. Chỉ chạy test của file liên quan, `flutter analyze --no-pub` đúng thư mục đã sửa. Không chạy cả bộ test, không E2E tại máy.
- Fixture Excel DỰNG GIẢ (`workbookFrom`/`workbookBytes`, `fakeName`, `fakePhone`); tuyệt đối không dùng file Excel thật hay dữ liệu người thật.
- Không đọc/in/copy `.env*`, secret.

## Git
- Commit tiếng Việt `type(scope): ...`, mỗi task một commit (hoặc gộp task liền nhau cùng file), thêm `(openspec: app-nhap-excel-ghep-cot)`. KHÔNG `Co-Authored-By`. `git add <đúng file>`, không `git add .`/`-A`.
- Push nhánh `cloud/...` của bạn, cập nhật PR. **KHÔNG lên `main`**: người dùng/phiên local sẽ gộp qua `merge-lane.py` sau khi kiểm.
- Khi xong hoặc dừng: cập nhật lại file này (Trạng thái + Đã thử), chạy `cloud-xong`.

## Đã thử
| Cách | Kết quả | Vì sao / bằng chứng |
|---|---|---|
| Lập kế hoạch trên máy cloud `danh3` | thành công | 16 task, validate `--strict` exit 0 |
| Bố cục popup y hệt Web | bỏ | Người dùng: nhìn không hiểu, muốn ít chữ; chọn bố cục theo từng cột Excel + chip |

## Ràng buộc đang có
- Chỉ đợt 1; không đụng nhóm 4–5 (nguồn: người dùng + `tasks.md`).
- Không đổi Backend/Web/API (nguồn: người dùng).
- Không đổi hành vi phần còn lại của màn Nhập Excel; test hiện có của `roster_*` phải giữ xanh.

## Ràng buộc thay đổi lần này
- Thêm: "đợt 1 apply"; không nút `Tiếp tục`; không lên `main`.
- Bỏ: "chỉ lập kế hoạch, không code" (đã hết hiệu lực).

## Câu hỏi còn mở
- Đợt 2 (danh sách thẻ + chi tiết sửa được, kể cả `Xóa cặp`/`+ Thêm VĐV`): làm sau khi đợt 1 xong và được người dùng duyệt.
