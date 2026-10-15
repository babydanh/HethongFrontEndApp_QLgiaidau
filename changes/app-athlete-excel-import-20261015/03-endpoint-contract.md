# 03 - Hợp đồng endpoint và wire

Nguồn đối chiếu (2026-10-15), chỉ dùng cây được phép:
- Web: `D:/Duancanhan/Project_QuanLyGiaiDau/HethongFrontEndWeb_QLgiaidau/src`. KHÔNG dùng `HethongFrontEndWeb_QLgiaidau-main` (khác: cây `-main` có `Promise.allSettled` ở thêm VĐV, cây được phép là vòng `for` tuần tự).
- Backend: `D:/Duancanhan/Project_QuanLyGiaiDau/HethongBackendApi_QuanlyGiaiDau/src/modules/tournaments/` (`dto/roster-import.dto.ts`, `dto/roster-import-batch.dto.ts`, `validation/roster-import-batch.ts`).

## 1. Thêm VĐV (`AddAthleteModal.tsx`, `api.ts` 1442-1508)

| Việc | Route | Body / query | Ghi chú |
|---|---|---|---|
| Ứng viên CLB/bạn bè | GET `/tournaments/{id}/add-athletes/candidates` | `source` FRIENDS\|CLUB, `q?`, `limit?`, `participantId?` | → `{items: AddAthleteCandidate[]}` |
| Tìm tài khoản | POST `/add-athletes/search` | `{name?, email?, participantId?}` | → `{items: AddAthleteSearchCandidate[]}` có `email`, `sources` |
| Thêm 1 ứng viên | POST `/add-athletes/candidates` | `{source, userId, tournamentDivisionId?, participantId?, role?}` | → `participantId`. Bóng đá: `tournamentDivisionId` = undefined, gửi `participantId` + `role` |
| Thêm khách | POST `/add-athletes/direct` | `{name, email?, tournamentDivisionId?}` | web: `name` rỗng thì lấy phần trước `@` của email |
| Thêm cặp | POST `/add-athletes/pairs` | `{source, tournamentDivisionId, userIds[]}` | → `{pairs: AddedAthletePair[]}` |
| Duyệt sau thêm | PATCH participant status `COMPLETE` | qua `updateParticipantStatus` | chỉ khi `canAutoApprove` |

Hành vi web đã đọc:
- Thêm nhiều ứng viên chạy TUẦN TỰ (vòng `for`, `AddAthleteModal.tsx` 495-507). Lỗi đầu tiên dừng vòng, báo `addedCount` và `unattemptedCount`. KHÔNG song song.
- Lỗi duyệt sau thêm (`approveAddedParticipant` nuốt lỗi, trả `false`) đếm riêng `approvalFailureCount`, KHÔNG dừng vòng.
- Khách: email tuỳ chọn. Thành công thì xoá ô tìm kiếm và đóng form.
- Tìm theo email chỉ gọi khi chuỗi có `@`.
- Giới hạn chọn ứng viên: `CANDIDATE_LIMIT = 25` (`AddAthleteModal.tsx` ~55). Debounce tìm kiếm `SEARCH_DEBOUNCE_MS = 250` (~58).

## 2. Import Excel (roster batch)

| Việc | Route | Ghi chú |
|---|---|---|
| Preview | POST `/tournaments/{id}/roster-import-batches/preview` | body = `RosterImportBatchRequest`, trả `RosterImportBatchPreview` |
| Commit | POST `/tournaments/{id}/roster-import-batches` + header `Idempotency-Key` | body như preview; trả `{importedCount, replayed, message?}` |

Body: `{ groups: [ { divisionId: string|null, participants: [item] } ] }`
- `groups` 1..500; `participants` mỗi group 1..500.
- `clientRowIndex` 0..499, duy nhất trên toàn workbook -> tối đa 500 dòng. Web chặn bằng `MAX_BATCH_PARTICIPANTS = 500` (`RosterImportModal.tsx` 75, 288: `workbookLimitExceeded = includedRows.length > 500`).
- `divisionId` null khi giải không có nội dung (division) nào khớp.

Item (`RosterImportBatchItemDto` = `RosterImportItemDto` bỏ `player1Email`, rồi thêm lại `player1Email?`):
- Bắt buộc: `clientRowIndex`, `teamName` (string KHÔNG rỗng; backend `IsString`; web fallback `player1Name`), `player1Name`, `source` (`EXCEL`).
- Web luôn gửi: `isPaid` (bool), `autoApprove` (bool), `entryType` (`REGULAR` | `WILD_CARD_REQUEST`; backend bỏ qua, chỉ giữ để client cũ không bị 400), `customResponses` (object).
- Tuỳ chọn, bỏ khi rỗng: `player1Email` (lowercase), `player1Phone`, `player2Name`, `player2Email` (lowercase), `player2Phone`, `elo` (bỏ khi null).
- `sourceRowIndex` (>= 1, <= 1048576), `sourceSheetName` (<= 31 ký tự).
- `confirmedPlayer1UserId`, `confirmedPlayer2UserId`: UUID, CHỈ gửi khi đã liên kết (xem mục 3).
- `customResponses` = `{...cột tuỳ chỉnh, sourceFileName (<= 31 ký tự, nếu có), sourceRowIndex, sourceSheetName, notes (trim, bỏ khi rỗng)}` (`rosterImportDraft.ts` 224-258).

Commit (`RosterImportModal.tsx` 776-810):
- Chặn nếu `capacityShortfall` hoặc group nào `!divisionMatched`.
- Body commit = preview request lọc theo dòng eligible; bỏ group rỗng.
- Idempotency: web `roster:<tournamentId>:<sha256(JSON.stringify(request))>` (`fingerprintRequest` ~139). App: `roster:<tournamentId>:<sha256(JSON chuẩn hoá, sort key)>`, đã cài ở data layer.
- Web gửi thêm `notifyLinkedAccounts: true`; backend bỏ qua (deprecated trong `roster-import-batch.dto.ts`). App KHÔNG gửi.

Preview (entity app `RosterImportBatchPreview.fromJson` đã khớp):
- Row: `clientRowIndex`, `rowIndex`, `sourceRowIndex?`, `sourceSheetName?`, `player1Email`, `player2Email`, `status[]`, `isEligible`, `capacityDelta`, `customResponses`, `customResponseError?`, `accountCandidates{player1[], player2[]}`, `confirmedPlayer1UserId`, `confirmedPlayer2UserId`.
- Group: `divisionId`, `divisionName`, `divisionMatched`, `rows[]`, `requestedTeamSlots`, `capacityRemaining`, `capacityRemainingAfterBatch`, `capacityFits`.
- Mã server (`api.ts` 861-871): FOUND, NOT_FOUND, INVALID_EMAIL, MISSING_EMAIL, MISSING_NAME, DUPLICATE_IN_FILE, DUPLICATE_IN_TOURNAMENT, PLAYER2_REQUIRED, PLAYER2_NOT_ALLOWED, DIVISION_UNKNOWN.

## 3. Mã trạng thái local và quy tắc chặn

Local (`rosterImportDraft.ts` `revalidateLocally` 182-222):
- `MISSING_NAME`: thiếu cả tên VĐV 1 và email VĐV 1.
- `MISSING_EMAIL`: VĐV 1 không có email. KHÔNG chặn.
- `INVALID_EMAIL`: email VĐV 1 hoặc VĐV 2 không khớp `ROSTER_EMAIL_PATTERN` (`exportTournament.ts` 171).
- `PLAYER2_REQUIRED`: giải đôi, VĐV 2 không có tên và email nhưng có SĐT (đúng theo web).
- `PLAYER2_NOT_ALLOWED`: giải đơn mà có dữ liệu VĐV 2.
- `DUPLICATE_IN_FILE`: email trùng giữa các dòng (xét cả email VĐV 1 và VĐV 2).
- KHÔNG thêm `PLAYER2_INCOMPLETE`.

Tập chặn (`BLOCKING_ROW_STATUSES`, `rosterImportDraft.ts` 72-82): `INVALID_EMAIL`, `MISSING_NAME`, `DUPLICATE_IN_FILE`, `DUPLICATE_IN_TOURNAMENT`, `PLAYER2_REQUIRED`, `PLAYER2_NOT_ALLOWED`, `DIVISION_UNKNOWN`. `MISSING_EMAIL` cố ý KHÔNG chặn (để đăng ký ngoại tuyến vẫn import được, đồng bộ với backend).

Eligibility (`resolveRosterRowStates` 383-411): `isEligible = server.isEligible && customResponseError == null && không có mã local/server nào trong tập chặn`. Chỉ dòng eligible đi vào commit.

## 4. Liên kết tài khoản (tri-state, phía client)
- `undecided`: chưa chọn. Tự liên kết khi `exactEmailAccountCandidates(email, candidates)` đúng 1 kết quả (`applyDefaultAccountLinks` 337-366). Khớp email chính xác sau trim+lowercase. Tên KHÔNG liên kết.
- `unlinked`: người dùng chọn không liên kết. Không gửi, không tự liên kết lại.
- `linked(userId)`: gửi `confirmedPlayerNUserId`.
- Wire: web bỏ cả `null` lẫn `undefined` khỏi request (`buildRosterImportBatchRequest` 302-307). Khác biệt chỉ nằm trong draft.
- Đổi email sau khi liên kết: quyết định của app (web không có quy tắc này trong phạm vi đã đọc) -> đưa về `undecided`.

## 5. Parser cột và dòng (web `exportTournament.ts`, `rosterImportDraft.ts`)
- Slot: `ROSTER_COLUMN_SLOTS` (254-267, gồm `entryType`, `isPaid`, `notes`). Đọc trực tiếp lại khi port, không tự thêm slot.
- Alias: `ROSTER_COLUMN_ALIASES` (278-386). Port nguyên văn, không thêm alias.
- Chuẩn hoá header: `normalizeHeader` (388-392: NFD, bỏ dấu, lowercase).
- Quét header: `ROSTER_HEADER_SCAN_ROWS = 10` dòng đầu mỗi sheet (499). Chấm điểm và `ROSTER_REQUIRED_MATCH_SLOTS` phá hoà (502-601). Sheet không có header -> bỏ qua, báo lỗi.
- Giới hạn mỗi sheet: `MAX_ROSTER_ROWS_PER_SHEET = 5000` (496). Giới hạn batch: 500 dòng tổng (mục 2).
- `mergedOverHeader`: web cờ hoá khi merged cell đè lên dòng header (có thể lệch cột). Port cờ này.
- `buildRosterDraftRows` (`rosterImportDraft.ts` 127-179):
  - Bỏ dòng trống: không có `player1Name`, `player2Name`, `teamName`, `player1Email`, `player1Phone`, `player2Phone`.
  - `teamName` = cột teamName; nếu rỗng: `player2Name ? "p1 / p2" : p1`.
  - `elo`: web dùng `parseFloat` (làm "1,250" thành 1). App khác có chủ đích: tách dấu phân nghìn theo regex `^\d{1,3}([.,\s]\d{3})+$`; không parse được -> null.
  - `entryType`: sau normalize có `wild` hoặc `dac cach` -> `WILD_CARD_REQUEST`, còn lại `REGULAR` (`parseRosterEntryType`).
  - `isPaid` (`parseRosterPaidFlag`): TRUE = {yes, true, paid, 1, co, da thanh toan}; FALSE = {no, false, unpaid, 0, chua}; khác -> `defaultPaid`. Web còn một token tiếng Nga; app không đưa vào, giữ VI/EN.
  - `rowIndex = sheetIndex * 5000 + index` (`rosterRowIndexOffset` 413-415). Đây là khoá draft, KHÁC `clientRowIndex` (khoá wire).
  - `sourceRowIndex = rowNumbers[index] ?? headerRow + index + 1`.

## 6. Mẫu Excel (`exportTournament.ts` 21-181)
- Vi: `Mau_Danh_Sach_VDV_Dang_Ky.xlsx`, sheet `Mau_Dang_Ky`. En: `Registration_List_Template.xlsx`, sheet `Registration template`.
- Header vi: `ROSTER_TEMPLATE_COPY.vi.headers` (94-108). Dòng mẫu: `rows` (109-). App dựng cùng header và cùng dữ liệu mẫu.
- Mẫu cần có email cho mọi VĐV (comment web 26-27).

## 7. Điểm lệch có chủ đích so với web
| Điểm | Web | App | Lý do |
|---|---|---|---|
| Elo "1,250" | 1 | 1250 | Web làm sai dữ liệu |
| Token paid tiếng Nga | có | không | Ngoài phạm vi VI/EN của app |
| Thêm nhiều VĐV | tuần tự | tuần tự | Đúng web (không phải lệch) |
| `notifyLinkedAccounts` | gửi | không gửi | Backend bỏ qua |
