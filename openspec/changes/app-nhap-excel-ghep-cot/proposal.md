## Why

Màn Nhập Excel của App (`roster_import_sheet.dart`) tự đoán cột bằng luật (và AI khi luật không đủ tin) nhưng người dùng không chỉnh được gì. File thật của người tổ chức thường có tiêu đề gộp ngang ở dòng 1, tiêu đề cột thật ở dòng 2, cặp đôi nằm trên hai dòng liền nhau gộp ô STT/xác nhận, cột "Đơn vị công tác", "Size áo", "Ngày sinh" lẫn với cột VĐV. Khi đoán sai (thiếu cột tên, nhầm cột SĐT) App chỉ báo "không có dòng nào đủ điều kiện" và người dùng phải sang Web.

Web đã có bước "Ghép cột" và bảng xem trước sửa được (`RosterColumnMappingStep.tsx`, `RosterPreviewTable.tsx`). Cần mang hai việc đó sang App, giao diện ít chữ kiểu mobile (bản vẽ: `mockup.html` cùng thư mục).

## What Changes

Chia hai đợt, đợt 1 làm và phát hành được riêng:

**Đợt 1: popup Ghép cột**
- Nút `Ghép cột` trên màn Nhập Excel mở một bottom sheet cao gần hết màn: một dòng chọn cách ghép cặp (4 kiểu, thêm ô ký tự ngăn cách khi "Hai VĐV một ô"), ô số "Hàng tiêu đề", rồi danh sách theo cột Excel (tên cột, một giá trị mẫu, nhãn ngắn của trường đang ghép). Chạm dòng thì hiện hàng chip để chọn trường.
- Mỗi trường chỉ một cột; gán cột khác thì cột cũ về `Ghi chú`. Cột không ghép là `Ghi chú` (viền đứt). Cột STT và cột nhạy cảm (ngày sinh, CCCD, địa chỉ...) bị khóa, không chạm được.
- `Xong` cần ít nhất một trong tên VĐV 1 / tên đội / email VĐV 1 và ít nhất một dòng đọc được. Bấm `Xong` thì đọc lại các dòng, kiểm tra cục bộ, gọi lại preview server.
- Người dùng sửa thì bản sửa thắng bản AI (câu trả lời AI đến muộn bị bỏ).
- Đổi "Hàng tiêu đề" đọc lại tiêu đề và mẫu, dò lại ánh xạ; tiêu đề đang nằm trong ô gộp ngang thì hiện cảnh báo lệch cột.
- Sheet bị bỏ qua vì không dò được dòng tiêu đề (`rosterImportNoSheetHeader`) cứu được bằng popup này.

**Đợt 2: danh sách VĐV sửa được**
- Mỗi cặp một thẻ (chữ cái đầu, hai VĐV tên + SĐT mờ, tròn trạng thái ✓ xanh / ! vàng / ✕ đỏ), thay `_rowCard`. Chân trang `đủ điều kiện/tổng` và nút `Nhập N VĐV` giữ nguyên.
- Chạm thẻ mở bottom sheet chi tiết: dải lý do (vàng/đỏ), mỗi VĐV có ô tên, SĐT, email, nút tài khoản (`Tự liên kết / Không liên kết / chọn tài khoản`, lấy từ ô chọn tài khoản hiện có), ô tích `Đã đóng phí`, ô Ghi chú (textarea), nút `Xóa cặp` và `Xong`.
- Nút `+` trên thanh tiêu đề thêm một cặp tay; `Xóa cặp` có hoàn tác.
- Tách `roster_import_sheet.dart` (1746 dòng) thành các file nhỏ trước khi thêm tính năng đợt 2.

Gmail/email với tài khoản Sporto: **không tự khớp ở App**. App chỉ gọi lại `POST /tournaments/{id}/roster-import-batches/preview` và hiện `status` / `accountCandidates` Backend trả về (xem `design.md`, mục "Email và tài khoản").

## Out of scope

- Không đổi Backend, Web, hợp đồng API. Không thêm endpoint, không thêm field.
- Không map cột vào "trường tuỳ chỉnh của giải" (Web có `customMapping`/`registrationForm`; App chưa có và `RosterImportBatchItem.customResponses` chỉ mang `notes`).
- Không có chip "Bỏ qua" cho cột (Web không có; cột không ghép mặc định vào Ghi chú).
- Không chọn Nội dung / ELO theo từng dòng ở chi tiết (Web chọn nội dung ở cấp nhóm).
- Không thêm package. Không đổi luật dò cột, luật ghép cặp, bước xác nhận tạo nội dung thiếu.
- Không đọc/ghi file Excel thật của người dùng; test dựng fixture giả.
- Không chạy E2E tại máy (E2E nếu cần chạy trên cloud runner, change này không thêm spec E2E).

## Capabilities

### New Capabilities
- `app-roster-column-mapping`: popup Ghép cột (đợt 1).
- `app-roster-editable-list`: danh sách VĐV dạng thẻ và chi tiết sửa được, thêm/xóa cặp (đợt 2).

### Modified Capabilities

Không có (`openspec/specs/` chưa có spec nào về nhập Excel).

## Impact

- Repo ảnh hưởng: chỉ App (repo này). Backend API và Web không đổi; chỉ đọc làm bằng chứng:
  - Web: `src/app/[locale]/organizer/tournaments/[id]/manage/components/roster-import/{RosterColumnMappingStep,RosterPreviewTable,rosterImportDraft}.tsx|ts`, `src/utils/exportTournament.ts` (`mergedOverHeader`, dòng ~971).
  - Backend: `src/modules/tournaments/repositories/tournament-import.repository.ts` (`findRosterBatchAccountCandidates` dòng 219, dùng ở 1611), `dto/roster-import-batch.dto.ts` (`clientRowIndex` 0..499, `sourceRowIndex` ≥ 1, `sourceSheetName` ≤ 31 ký tự), `validation/roster-import-batch.ts` (`resolveConfirmedRosterUserId`, dòng 141).
- Endpoint dùng lại: `POST /tournaments/{id}/roster-import-batches/preview`, `POST /tournaments/{id}/roster-import-batches` kèm `Idempotency-Key`.
- File App sửa/tạo: xem `tasks.md` (mỗi task có `Files:`).
- Chuỗi mới: `lib/l10n/app_vi.arb` + `app_en.arb`, tiền tố `rosterMap*` (đợt 1) và `rosterList*` (đợt 2), rồi `flutter gen-l10n`.
