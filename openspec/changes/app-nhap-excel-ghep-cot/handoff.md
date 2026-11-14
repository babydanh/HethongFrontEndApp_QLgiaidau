# Handoff: App nhập Excel — popup ghép cột + danh sách VĐV sửa được
Cập nhật: 2026-11-14 · bởi: claude (cloud) · nhánh: cloud/danh3-app-nhap-excel-ghep-cot-113202 (từ app-nhap-excel-ghep-cot) · OpenSpec: app-nhap-excel-ghep-cot

## Mục tiêu
**VIỆC CỦA BẠN CHỈ LÀ LẬP KẾ HOẠCH (OpenSpec), KHÔNG VIẾT CODE `lib/`/`test/`.** Viết đủ `proposal.md`, `design.md`, `specs/<capability>/spec.md`, `tasks.md` trong thư mục này, chạy `openspec validate app-nhap-excel-ghep-cot --strict` tới exit 0, commit hẹp, push nhánh, rồi DỪNG chờ người dùng nói "apply". Kế hoạch phải đủ kỹ để một agent khác code từng task không phải hỏi lại: mỗi task có `Files:` là đường dẫn thật đã kiểm trong repo (kèm dòng), `Giao:`/`Nhận:` chữ ký Dart chính xác, `Chủ file chung:`, `Phụ thuộc:`, `Tiêu chí:` = lệnh chạy được + mã thoát (xem skill `company` mục 3, mẫu task).

Màn Nhập Excel của App (`roster_import_sheet.dart`) hiện tự đoán cột bằng luật, người dùng không chỉnh được. Web có bước "Ghép cột" và bảng xem trước sửa được. Cần mang phần đó sang App, giao diện **ít chữ, kiểu mobile**, bản vẽ ở `mockup.html` cùng thư mục (mở bằng trình duyệt; dữ liệu trong đó là giả). Phân loại: Bounded (luồng đã có, không đổi API) nhưng người dùng đòi kế hoạch kỹ nên viết cả `design.md`.

## Trạng thái
- Xong: khảo sát nguồn và kiểm lại từng dòng bàn giao (App, Web, Backend; sai lệch ghi ở `design.md` mục "Đã kiểm lại bản bàn giao"); đủ 4 artifact (`proposal.md`, `design.md`, `specs/app-roster-column-mapping`, `specs/app-roster-editable-list`, `tasks.md`); `openspec validate app-nhap-excel-ghep-cot --strict` exit 0; đã push nhánh.
- KHÔNG viết code `lib/`/`test/`. Chưa chạy được Botkeep (503 lúc làm): ghi "chưa kiểm bằng Botkeep".
- Tiếp theo: DỪNG chờ người dùng nói "apply". Khi apply: làm theo `tasks.md` tuần tự (đợt 1 = nhóm 1–3, đợt 2 = nhóm 4–5; hỏi người dùng làm cả hai hay chỉ đợt 1).
- Phát hiện cần người dùng biết: (1) cờ `layoutChosen` vì `RosterPairLayout.single` đang vừa là "để luật suy" vừa là "đánh đơn"; (2) reader App bỏ vùng gộp ngang nên muốn cảnh báo tiêu đề gộp ô phải ghi thêm `horizontalMerges`; (3) Backend giới hạn `clientRowIndex` 0..499, `sourceRowIndex` ≥ 1 nên dòng thêm tay phải bỏ field nguồn; (4) khi email đổi phải đặt lại liên kết tài khoản, nếu không Backend trả 409.

## Điều đã xác minh trong code (nguồn: `origin/main` lúc bàn giao)
**Web (tham chiếu hành vi, repo `HethongFrontEndWeb_QLgiaidau`, thư mục `src/app/organizer/tournaments/[id]/manage/components/roster-import/`):**
- `RosterColumnMappingStep.tsx`: tiêu đề "Ghép cột · {sheet}"; ô số "Hàng tiêu đề"; chọn cách ghép cặp (`SINGLE | COLUMNS | SAME_CELL | CONSECUTIVE_ROWS`, thêm "ký tự ngăn cách" khi `SAME_CELL`); hiện sẵn VĐV 1 (tên, email, SĐT), thi đôi thêm VĐV 2; còn lại gập trong "Cột khác"; 3 dòng đầu để đối chiếu; "Xong" cần ít nhất một trong tên VĐV 1 / tên đội / email VĐV 1.
- `rosterImportDraft.ts`: `ROSTER_COLUMN_SLOTS` có 12 slot (`pairCode, teamName, player1Name/Email/Phone, player2Name/Email/Phone, divisionName, isPaid, elo, notes`). `rosterNoteColumns`: cột không ghép vào slot nào → **vào Ghi chú dạng `Tên cột: giá trị`, nối bằng ` · `**, cắt ở `ROSTER_NOTES_MAX`; TRỪ cột số thứ tự (`stt, tt, so tt, so thu tu, no, no., #`) bị bỏ, và cột nhạy cảm (ngày/năm sinh, CCCD/CMND, hộ chiếu, địa chỉ, mã số thuế…, xem `SENSITIVE_HEADER_WORDS`) **không lưu kể cả vào ghi chú**, có thông báo. Ô trống không ghi.
- `RosterPreviewTable.tsx`: sửa trực tiếp tên đội/VĐV 1/VĐV 2, email, SĐT (cột chỉ hiện khi file có dữ liệu), tích "Đã đóng", popup Ghi chú (textarea + trường tuỳ chỉnh của giải), popup chọn tài khoản theo email chính xác, popup lý do lỗi/cảnh báo (đỏ/vàng), nút xóa dòng, nút thêm VĐV. Nội dung thi đấu chọn ở cấp nhóm, không sửa theo dòng.
- Chuỗi: namespace `RosterImport` trong `messages/vi.json` (`slots.*`, `noColumn`, `headerRow`, `pairLayout*`, `otherColumns`, `sampleTitle`, `doneMapping`, `identityColumnRequired`, `notesFromColumns`, `sensitiveColumnsSkipped`…).

**App (repo này):**
- `lib/features/organizer_ops/utils/roster_excel_parser.dart`: `enum RosterSlot` (đúng 12 slot như Web), `class RosterColumnMapping(Map<RosterSlot,int>)` (cột A = 0), `detectRosterColumnMapping(List<String> headers)` (dòng ~460), `_indexHeaders` (~622), `_sensitiveHeaderWords` (~633), logic notes (~829–836, cắt `rosterNotesMax` ~986). **Tức là luật STT/nhạy cảm/ghi chú ĐÃ port sẵn; popup chỉ cần cho người dùng sửa `RosterColumnMapping`.**
- `lib/features/organizer_ops/utils/roster_layout.dart`: `RosterReading` có `headerRowIndex`, `mapping`, `layout` (`RosterPairLayout`), `separator`, `fromAi`; `RosterReading.parse(RosterColumnMapping)` (dòng ~58) đã nhận ánh xạ từ ngoài; `readSheetByRules` (~72); `assembleRosterRows` (~95). Có thêm đường hỏi AI về bố cục (`domain/entities/roster_layout.dart`, `RosterLayoutResponse`, `_LayoutStatus`). Kế hoạch phải nói rõ popup tương tác thế nào với kết quả AI (người dùng sửa thì ưu tiên bản sửa).
- `lib/core/services/roster_excel_reader.dart`: `readRosterWorkbook(Uint8List)` → `List<RosterGridSheet>` (gồm `mergedRegions`).
- `lib/features/organizer_ops/screens/roster_import_sheet.dart` (rất dài, >1700 dòng): `_DraftRow`, `_DraftGroup`, `_PlayerLink` (`auto | unlinked | linked(userId)`), `_Plan`, `_RosterImportSheetState` (~364), gọi `readRosterWorkbook` (~538), gọi preview (~889), ô chọn tài khoản `DropdownButton` (~1690–1740). Kế hoạch phải ĐỀ XUẤT tách file (ghép cột, thẻ cặp, chi tiết) thay vì phình thêm file này; ghi dòng cụ thể sẽ cắt.
- Chuỗi: `lib/l10n/app_vi.arb` + `app_en.arb`, các key `rosterImport*` (~dòng 6529–6567 của vi); key mới phải có cả hai rồi `flutter gen-l10n`; không sửa tay `app_localizations*.dart`.

## Liên kết Gmail/email với tài khoản Sporto — QUYẾT ĐỊNH CỦA NGƯỜI DÙNG
Người dùng nói: logic khớp email với tài khoản đã có trong Sporto **đã đầy đủ ở Backend, chỉ cần gọi vào cho kỹ**. Vì vậy:
- **Không đổi Backend, không đổi Web, không đổi hợp đồng API.** Không tự tìm tài khoản ở phía App.
- Dùng đúng `POST /tournaments/{id}/roster-import-batches/preview` (`lib/data/repositories/api/api_tournament_management_repository.dart` ~379) và commit `/roster-import-batches` kèm `Idempotency-Key` (~394–406). Phản hồi preview đã có `status` (vd `FOUND`, `NOT_FOUND`, `INVALID_EMAIL`…) và `accountCandidates.player1/player2` → `RosterImportBatchPreviewRow.player1Candidates/player2Candidates` (`lib/domain/entities/roster_import.dart` ~104–181). Backend: `src/modules/tournaments/repositories/tournament-import.repository.ts` `findRosterBatchAccountCandidates` (~219), dùng ở ~1611 (chỉ đọc để hiểu, không sửa).
- Kế hoạch phải trả lời bằng bằng chứng từ code: (a) khi nào App gọi preview (sau "Xong" ghép cột? sau mỗi lần sửa email?), cần debounce/huỷ request cũ thế nào để mạng rớt, timeout, bấm đúp, đổi email liên tục không sinh kết quả cũ đè kết quả mới; (b) khi người dùng SỬA email trong chi tiết thì preview chạy lại ra sao và `_PlayerLink` giữ/đặt lại thế nào; (c) email sai định dạng, trùng trong file, trùng trong giải xử lý ở đâu (client hay chỉ hiện mã server); (d) thẻ danh sách hiển thị `FOUND/NOT_FOUND` thế nào (icon, không thêm chữ dài); (e) commit gửi lại đúng lựa chọn tài khoản của người dùng.
- Nếu đọc code thấy Backend KHÔNG đủ cho một ý nào ở trên: ghi vào "Câu hỏi còn mở", không tự thiết kế đổi Backend.

## Quyết định giao diện đã chốt (nguồn: người dùng, qua mockup)
1. **Ít chữ nhất có thể** (phong cách "ui ux pro max"), như Web. Icon SVG, không emoji. Vùng chạm ≥ 44 dp. Bám `AppTheme`/token sẵn có, tự đúng chế độ tối; không hardcode màu từng màn.
2. **Popup "Ghép cột"** = bottom sheet cao gần hết màn, mở từ màn Nhập Excel (nút `Ghép cột`). Đầu sheet một dòng chọn cách ghép cặp (4 kiểu). Thân sheet = **danh sách theo cột Excel**: mỗi dòng có tên cột + một giá trị mẫu mờ + nhãn ngắn bên phải (`Tên`, `SĐT`, `Email`, `Tên VĐV 2`, `Đội`, `Mã cặp`, `Nội dung`, `Đã đóng phí`, `ELO`, `Ghi chú`). Chạm dòng → hàng chip để chọn. Mỗi trường chỉ một cột: gán cột khác thì cột cũ về `Ghi chú`. Cột không ghép = `Ghi chú` (viền đứt). Cột STT và cột nhạy cảm: khóa, không chạm được (nhạy cảm có ổ khóa + "Không lưu"). KHÔNG có "Bỏ qua" (Web không có). Chân sheet: số dòng + nút `Xong`; thiếu cả tên VĐV 1/tên đội/email thì chữ đỏ, nút mờ.
3. **Danh sách VĐV sau "Xong"**: mỗi cặp một thẻ (chữ cái đầu, 2 VĐV tên + SĐT mờ, vạch ngăn, tròn trạng thái ✓ xanh / ! vàng / ✕ đỏ), chân trang `đủ điều kiện/tổng` và nút `Nhập N VĐV`. Nút `+` trên thanh tiêu đề để thêm VĐV.
4. **Chi tiết một cặp** (chạm thẻ → bottom sheet): dải lý do (vàng/đỏ) nếu có; mỗi VĐV có ô tên, ô SĐT, ô Email, nút tài khoản (`Tự liên kết / Không liên kết / chọn tài khoản`, lấy từ ô chọn tài khoản có sẵn); ô tích `Đã đóng phí`; ô Ghi chú (textarea chứa nguyên chuỗi `Tên cột: giá trị · …`); nút `Xóa cặp` và `Xong`. Không có ô Nội dung/ELO theo dòng (Web chọn nội dung ở cấp nhóm).
5. Văn bản dùng chuỗi tiếng Việt của Web (`RosterImport`) khi có sẵn, rút gọn cho mobile; mọi chuỗi thêm cả vi và en.

## Việc kế hoạch PHẢI làm rõ (đừng bỏ)
- **Thiết kế dữ liệu/trạng thái**: popup sửa một bản sao `RosterReading`/`RosterColumnMapping` hay giữ trạng thái riêng; đổi "Hàng tiêu đề" thì đọc lại tiêu đề, đọc lại mẫu, reset ánh xạ thế nào; ô gộp ở dòng tiêu đề (file mẫu có tiêu đề dòng 1 gộp ngang, hàng tiêu đề thật ở dòng 2 → cảnh báo lệch cột như `mergedHeaderWarning` của Web).
- **Ghép cặp `CONSECUTIVE_ROWS`** (hai dòng liền nhau là một cặp, ô STT và ô xác nhận gộp theo cặp): xác nhận App đã hỗ trợ (`RosterPairLayout`, `applyPairLayout`) và test hiện có; thiếu thì ghi thành task riêng.
- **Sửa dòng**: dữ liệu sửa ở chi tiết lưu ở đâu (`_DraftRow.parsed` bất biến, có `copyWith`), kiểm tra cục bộ (`localStatus`, `_localBlockingCodes`) chạy lại thế nào, xóa/thêm dòng ảnh hưởng `clientRowIndex` (duy nhất toàn workbook) và `_DraftGroup` ra sao, hoàn tác có cần không.
- **Phạm vi 2 đợt?** Người dùng chưa chốt: làm ghép cột + sửa trong danh sách cùng đợt, hay ghép cột trước. Hãy tách task theo hướng làm được RIÊNG ghép cột trước (đợt 1) rồi mới tới danh sách/chi tiết sửa được (đợt 2), ghi rõ phụ thuộc, để người dùng chọn.
- **Rủi ro mạng/race**: preview đang chạy mà người dùng sửa tiếp; bấm `Nhập` hai lần (idempotency đã có, chỉ ra cách giữ); file lớn (`rosterImportTooManyRows`); mảng rỗng; sheet không có tiêu đề.
- **Kiểm thử**: mỗi task có test ID (`TC-ROSTERMAP-01…`, `TC-ROSTERLIST-01…`, `TC-ROSTERDETAIL-01…`), widget test cho bottom sheet bằng `flutter test --no-pub <file>` (máy cloud tự cài Flutter qua `cloud-flutter test <file>`); fixture Excel DỰNG GIẢ trong test (tên, SĐT, email giả; không dùng file thật). E2E (nếu có) ghi spec + chạy trên cloud runner, không chạy tại máy.

## Đã thử
| Cách | Kết quả | Vì sao / bằng chứng |
|---|---|---|
| Mockup 1: bố cục y hệt Web (nhiều ô dropdown theo từng trường, nhiều chữ giải thích) | bỏ | Người dùng: "nhìn chả hiểu gì cả", muốn ít chữ như Web |
| Mockup 2: theo từng cột Excel + chip chọn, ít chữ | chọn | Người dùng xem tiếp và hỏi thêm danh sách/chi tiết |
| Chip "Bỏ qua" cho cột | bỏ | Web không có; cột không ghép mặc định vào Ghi chú |
| Chi tiết chỉ xem + chip ghi chú | bỏ | Web cho sửa; đổi thành ô nhập + textarea Ghi chú |

## Ràng buộc đang có
- Chỉ lập kế hoạch; dừng chờ "apply" (nguồn: AGENTS.md của repo + người dùng).
- Không đổi Backend/Web/hợp đồng API (nguồn: người dùng).
- Không thêm package (nguồn: AGENTS.md App). Excel đã có (`excel` package) qua `readRosterWorkbook`.
- Không đọc/in/copy `.env*`, secret. Không dùng dữ liệu thật của người dùng (file Excel thật có tên/SĐT, không nằm trong repo; chỉ mô tả bố cục: 9 cột, tiêu đề gộp dòng 1, cặp 2 dòng liền nhau gộp ô STT/xác nhận).
- Không nhét chữ che lỗi kiểu "Chưa xác định" vào chỗ thiếu dữ liệu; thiếu thì hiện trạng thái thật (nguồn: người dùng, bài học trước).
- Commit tiếng Việt `type(scope): …`, KHÔNG `Co-Authored-By`, `git add <đúng file>`, không `git add .`/`-A`.
- Không push `main`. Push nhánh `cloud/...` của bạn. Test nặng/E2E chạy trên cloud runner.

## Ràng buộc thay đổi lần này
- Thêm: toàn bộ danh sách trên (bàn giao lần đầu).
- Bỏ: không có.

## Câu hỏi còn mở
- Làm popup ghép cột + sửa trong danh sách cùng một đợt hay ghép cột trước? (`tasks.md` tách nhóm 1–3 và 4–5 để cả hai cách đều được)
- `Xóa cặp` và `+ Thêm VĐV`: giữ trong đợt 2 (task 4.5, cắt được) hay bỏ? Chi phí nêu ở `design.md` D8.
- Không làm nút `Tiếp tục` ở khung 1 của mockup (đọc xong hiện danh sách luôn): xác nhận.
- Backend: không có ý nào thiếu cho khớp email/tài khoản (bằng chứng ở `design.md` D7); không có mục nào cần đổi Backend.
