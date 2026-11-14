# Handoff: App nhập Excel — danh sách VĐV sửa được (ĐỢT 2)
Cập nhật: 2026-11-14 · bởi: claude · nhánh: app-ghep-cot-dot2 (từ origin/main c9c5f187) · OpenSpec: app-nhap-excel-ghep-cot

## Mục tiêu
**NGƯỜI DÙNG ĐÃ NÓI "TIẾP ĐI LÀM HẾT": VIẾT CODE ĐỢT 2 THEO `tasks.md`.** Đợt 2 = nhóm 4 và 5: task 4.1, 4.6, 4.2, 4.3, 4.4, 4.5, 4.7, 5.1. Kết quả: màn Nhập Excel có danh sách VĐV dạng thẻ theo cặp (trạng thái ✓/!/✕, nút `+ Thêm VĐV`), chạm thẻ mở chi tiết sửa được (tên, SĐT, email, đã đóng phí, ghi chú, tài khoản Sporto tự liên kết) giống Web, có `Xóa cặp` (kèm hoàn tác). Sửa email xong thì xem trước chạy lại trên máy chủ.

Đọc theo thứ tự: `proposal.md` → `design.md` (đặc biệt "Đã kiểm lại bản bàn giao", D7 email/tài khoản, D10) → `specs/app-roster-editable-list/spec.md` → `tasks.md` (mục "Ghi chú chung" + nhóm 4–5). Bản vẽ: `mockup.html` (khung 3 danh sách, khung 4 chi tiết, khung 5 lỗi; dữ liệu giả).

## Trạng thái
- Xong và ĐÃ LÊN MAIN: đợt 1 (task 1.1–3.2), commit `c9c5f187`; popup `Ghép cột` chạy được. `tasks.md` đã đánh `[x]` 8 task đó.
- Đang dở: chưa có dòng code đợt 2; `tasks.md` còn 8/16 `[ ]`.
- Thứ tự làm TUẦN TỰ trong MỘT worktree (chung file `roster_import_sheet.dart`): **4.1 → 4.6 → 4.2 → 4.3 → 4.4 → 4.5 → 4.7 → 5.1**. 4.1 (tách file, không đổi hành vi) làm trước, test hiện có phải xanh. 5.1 là cổng cuối.
- Mỗi task: viết test đỏ trước (chạy thấy đỏ đúng lý do), code tối thiểu cho xanh, chạy đúng lệnh ở `Tiêu chí`, rồi mới đổi `- [ ]` thành `- [x]`, commit hẹp.

## Quyết định của người dùng cho lần này
- Làm hết đợt 2, gồm `Xóa cặp` và `+ Thêm VĐV` (câu hỏi mở trong `design.md`: lấy phương án đề xuất của `design.md`, KHÔNG cắt).
- Không đổi Backend/Web/hợp đồng API. Email/tài khoản Sporto: dùng nguyên `POST /tournaments/{id}/roster-import-batches/preview` (đã trả `status` + `accountCandidates`); sau khi sửa dòng, gọi lại preview như luồng hiện có (D7). Không tự tìm tài khoản ở client.
- Giao diện ít chữ, icon SVG, vùng chạm ≥ 44 dp, màu từ `context.colors`/`AppTheme`, đúng chế độ tối, không tràn chữ ở 360 dp.
- Không thêm package. Chuỗi mới đủ cả `app_vi.arb` và `app_en.arb`, rồi `flutter gen-l10n`, commit cả `app_localizations*.dart` sinh ra, không sửa tay.
- Không nhét chữ che lỗi ("Chưa xác định"…) vào chỗ thiếu dữ liệu.
- `roster_import_sheet.dart` đã dài: task 4.1 tách ra file mới, không để file vượt trần 800 dòng thêm.

## Cách chạy và kiểm (máy cloud)
- Thay `flutter` bằng `cloud-flutter` (cùng tham số). Chỉ chạy test của file liên quan; `flutter analyze --no-pub` đúng thư mục đã sửa. Không chạy cả bộ test, không E2E tại máy.
- Fixture Excel DỰNG GIẢ (`workbookFrom`/`workbookBytes`, `fakeName`, `fakePhone`); không dùng file Excel thật hay dữ liệu người thật. Dùng lại `roster_mapping_fixture.dart` của đợt 1.
- Không đọc/in/copy `.env*`, secret.

## Git
- Commit tiếng Việt `type(scope): ...`, mỗi task một commit, thêm `(openspec: app-nhap-excel-ghep-cot)`. KHÔNG `Co-Authored-By`. `git add <đúng file>`, không `git add .`/`-A`.
- Push nhánh `cloud/...` của bạn. **KHÔNG lên `main`**: phiên local gộp qua `merge-lane.py` sau khi kiểm.
- Khi xong hoặc dừng: cập nhật lại file này (Trạng thái + Đã thử), chạy `cloud-xong`.

## Đã thử
| Cách | Kết quả | Vì sao / bằng chứng |
|---|---|---|
| Đợt 1 (nhóm 1–3) trên máy `danh1` | thành công | 8 task `[x]`, 101 test xanh, cloud đầy đủ xanh, lên main `c9c5f187` |
| Bố cục popup y hệt Web | bỏ | Người dùng: nhìn không hiểu, muốn ít chữ |
| Gộp đợt 1 cùng thư mục `openspec/changes/<id>/` | bị chặn | Có tiến trình tạo lại file nháp trong checkout main, `safe-push-check` chặn; đợt 1 đã đưa code lên mà không kèm thư mục này |

## Ràng buộc đang có
- Không đổi Backend/Web/API (nguồn: người dùng).
- Test hiện có của `roster_*` và popup đợt 1 phải giữ xanh.
- Phần trong `openspec/changes/app-nhap-excel-ghep-cot/` KHÔNG tự đưa lên main trong lượt gộp đợt 2 nếu `merge-lane` còn bị chặn: báo phiên local, đừng ép.

## Ràng buộc thay đổi lần này
- Thêm: đợt 2 apply; làm cả `Xóa cặp`/`+ Thêm VĐV`.
- Bỏ: "chỉ đợt 1" (đã hết hiệu lực).

## Câu hỏi còn mở
- Không. Gặp ngã rẽ thì chọn phương án đề xuất trong `design.md` và ghi vào "Đã thử".
