# Bản đồ vấn đề: quản lý VĐV App so với web

Nguồn đối chiếu (đã đọc):
- Web: `src/features/tournaments/api.ts`; `.../manage/components/AddAthleteModal.tsx`; `.../roster-import/RosterImportModal.tsx`, `rosterImportDraft.ts`, `RosterPreviewTable.tsx`, `rosterLayout.ts`; `src/utils/exportTournament.ts` (alias cột, mẫu, email pattern).
- Backend: `HethongBackendApi_QuanlyGiaiDau/src/modules/tournaments/dto/roster-import-batch.dto.ts`, `validation/roster-import-batch.ts`.

## Khoảng trống App so với web
1. Thêm VĐV: app chỉ chọn 1 ứng viên; web chọn tối đa 25 và thêm TUẦN TỰ (vòng `for` trên cây web được phép; lỗi đầu tiên dừng vòng, báo added/failed/unattempted; lỗi duyệt sau thêm đếm riêng).
2. Thiếu tìm theo email (`/add-athletes/search`) và nhóm nguồn `EMAIL`.
3. Thiếu chế độ cặp đôi (`/add-athletes/pairs`) cho division DOUBLES/MIXED_DOUBLES (web: `canUsePairMode`).
4. Khách không có email (`/add-athletes/direct` thiếu `email`).
5. Thiếu toàn bộ nhập Excel: đọc file, nhận diện cột, preview server, chọn tài khoản, commit có idempotency.
6. Thiếu nút tải mẫu Excel.

## Nguồn sự thật
- Hành vi thêm VĐV và nhập Excel: web. Lỗi local và alias cột: web `exportTournament.ts` và `rosterImportDraft.ts`.
- Validate server: backend (`roster-import-batch.ts`). Server quyết định PLAYER2_REQUIRED / PLAYER2_NOT_ALLOWED vì phụ thuộc loại division.

## Rủi ro chính
- Commit lặp sau lỗi mạng tạo bản ghi trùng → cần idempotency key ổn định theo nội dung.
- Gỡ liên kết tài khoản bị auto-link lại → cần trạng thái riêng `unlinked`.
- Parser sai số elo (web dùng `parseFloat`: "1,250" → 1) → tách dấu phân nghìn.
- Token "да" (tiếng Nga) trong web → không đưa vào code app (xem plan, quyết định P1).
