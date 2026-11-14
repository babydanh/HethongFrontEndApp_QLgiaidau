## Phân loại

Bounded (luồng đã có, không đổi API) nhưng người dùng đòi kế hoạch kỹ nên có `design.md`. Mọi số dòng dưới đây đã đọc lại trên nhánh này (cơ sở `origin/main` lúc bàn giao) và trên `main` của Backend/Web ngày 2026-11-14.

## Đã kiểm lại bản bàn giao

Đúng: `RosterSlot` 12 giá trị; `RosterColumnMapping(Map<RosterSlot,int>)`; `detectRosterColumnMapping` dòng 460; `_indexHeaders` 622; `_sensitiveHeaderWords` 633; ghi chú ở `parseRosterSheet` 829–836; `RosterReading.parse` roster_layout.dart:58; `readSheetByRules` :72; `assembleRosterRows` :95; `_RosterImportSheetState` :364; `readRosterWorkbook` gọi :538; preview gọi :889; `DropdownButton` tài khoản :1711; repository preview `api_tournament_management_repository.dart` :371–384 và commit :386–406; Backend `findRosterBatchAccountCandidates` :219, dùng :1611; mockup đúng 5 khung.

Sai/cần sửa so với bàn giao:
1. Đường Web đúng là `src/app/[locale]/organizer/...` (bàn giao thiếu `[locale]`).
2. `RosterGridSheet.mergedRegions` chỉ giữ vùng gộp qua ≥ 2 dòng (`roster_excel_reader.dart:98–103`, bỏ gộp ngang một dòng). Web tính `mergedOverHeader` từ mọi vùng gộp phủ dòng tiêu đề (`exportTournament.ts:971`). Muốn cảnh báo lệch cột như Web thì App phải ghi thêm vùng gộp ngang: task 1.2.
3. `RosterPairLayout.single` đang mang hai nghĩa: "AI/luật không chỉ định, để luật suy" (`roster_layout.dart:105–106`) và "đánh đơn". Người dùng chọn "Đánh đơn" thì `assembleRosterRows` lại tự suy ra `columns`/`sameCell`. Cần cờ `layoutChosen` trên `RosterReading`: task 1.3.
4. Bàn giao nói "luật STT/nhạy cảm/ghi chú đã port sẵn": đúng, nhưng `_indexHeaders`, `_sensitiveHeaderWords`, `_localErrors` đều private; popup và chi tiết cần dùng, nên export (task 1.1 và 4.2).
5. Bàn giao nói `copyWith` của `RosterParsedRow` đủ cho sửa dòng: thiếu. Không thể xóa trống `player1Name/Email/Phone` (chỉ có cờ `clear` cho VĐV 2, elo, notes, team). Task 4.2.
6. Backend giới hạn `clientRowIndex` 0..499, `sourceRowIndex` ≥ 1, `sourceSheetName` ≤ 31 ký tự, mảng ≤ 500 (`roster-import-batch.dto.ts`). Dòng thêm tay không có dòng nguồn nên phải bỏ hai field nguồn: hiện `_itemFor` (`roster_import_sheet.dart:801–839`) luôn gửi `parsed.sourceRowIndex`.

## Quyết định

### D1. Hai đợt, tách file trước khi làm đợt 2
Đợt 1 (nhóm 1–3 trong `tasks.md`) làm và phát hành riêng, chỉ thêm một nút và một handler vào `roster_import_sheet.dart` (khoảng +60 dòng). Đợt 2 (nhóm 4–5) bắt đầu bằng task 4.1: tách `roster_import_sheet.dart` (1746 dòng) theo cắt dưới đây, không đổi hành vi.

| Cắt | Dòng hiện tại | Sang file |
|---|---|---|
| `_maxBatchParticipants`, `_localBlockingCodes`, `_serverBlockingCodes`, `_unlinkedValue`, `_emailPattern` | 19–47 | `roster_import_draft.dart` (công khai) |
| `_foldName`, `_divisionLabelMatches`, `_inferMatchType`, `_inferGender`, `_accentBases` | 49–135 | `roster_division_match.dart` (thuần Dart, có test) |
| `_LinkChoice`, `_PlayerLink`, `_DivisionTarget`, `_DraftRow`, `_DraftGroup`, `_ParsedWorkbook`, `_RowCandidates`, `_Plan` | 137–229 (không gồm `_LayoutStatus` 195) | `roster_import_draft.dart` |
| `_localStatusOf`, `_isRowEligible`, `_duplicateRowIndices`, `_uniqueExactAccountId` | 231–292 | `roster_import_draft.dart` |
| `_statusLabel`, `_toneChip`, `_noticeText` | 294–343 | `roster_import_widgets.dart` |
| `_rowCard`, `_statusTone`, `_accountRow` | 1524–1745 | thay bằng `roster_pair_card.dart` + `roster_pair_detail_sheet.dart` |

Sau tách, file màn còn khoảng 1250 dòng (phần lớn là `_RosterImportSheetState`: đọc file, AI, tạo nội dung, preview, commit, build). Vẫn trên trần mềm 800; chấp nhận trong change này và ghi nợ: tách `_runPreview/_commit` thành notifier là change riêng, không làm ở đây (rủi ro đụng nhiều test hiện có). Test hiện có không dùng `roster-row-N`, `roster-account-N-P` hay `DropdownButton` (đã grep `test/features/organizer_ops/`), nên thay thẻ không vỡ test cũ.

### D2. Trạng thái popup: giá trị bất biến trong file thuần Dart, popup chỉ giữ bản sao
`lib/features/organizer_ops/utils/roster_mapping_draft.dart` (thuần Dart, không Flutter) chứa `RosterMappingDraft` bất biến. Popup giữ `List<RosterMappingDraft>` trong state của nó (một phần tử cho mỗi khối đọc được và mỗi sheet bị bỏ qua), mọi thao tác trả bản mới. Popup trả về `RosterMappingResult?` qua `Navigator.pop`; `null` khi đóng không bấm `Xong`. Màn Nhập Excel không đổi `_readings` cho tới khi nhận kết quả khác `null`.

```dart
enum RosterColumnKind { normal, index, sensitive }

class RosterMappingColumn {
  const RosterMappingColumn({required this.index, required this.header,
      required this.sample, required this.kind, required this.slot});
  final int index;          // cột A = 0
  final String header;      // '' khi ô tiêu đề trống: UI hiện chữ cột (A, B...)
  final String sample;      // giá trị không trống đầu tiên bên dưới dòng tiêu đề, cắt 40 ký tự
  final RosterColumnKind kind;
  final RosterSlot? slot;   // null = Ghi chú
}

class RosterMappingDraft {
  factory RosterMappingDraft.fromReading(RosterReading reading,
      {required bool Function(String? divisionName) isDoublesFor});
  /// Sheet bị bỏ qua: hàng tiêu đề mặc định là dòng đầu có từ hai ô trở lên (hoặc 0).
  factory RosterMappingDraft.forSkippedSheet(RosterGridSheet grid,
      {required bool Function(String? divisionName) isDoublesFor});

  final RosterReading reading;
  final bool wasSkipped;
  List<RosterMappingColumn> get columns;
  bool get isDoubles;                 // có dòng nào thuộc nội dung đôi
  RosterPairLayout get effectiveLayout; // cái đang áp dụng (đã suy nếu chưa chọn)
  bool get hasIdentity;               // player1Name | teamName | player1Email
  int get rowCount;                   // assembleRosterRows(reading, isDoublesFor).length
  bool get headerMayBeShifted;        // dòng tiêu đề nằm trong vùng gộp ngang

  RosterMappingDraft withHeaderRow(int headerRowIndex); // 0-based, kẹp vào [0, rows-2]
  RosterMappingDraft assign(int column, RosterSlot? slot); // null = Ghi chú
  RosterMappingDraft withLayout(RosterPairLayout layout, {String? separator});
}

class RosterMappingResult {
  const RosterMappingResult({required this.readings, required this.skippedSheets});
  final List<RosterReading> readings;
  final List<String> skippedSheets;   // sheet vẫn bị bỏ qua sau khi sửa
}
```

Quy tắc trong `RosterMappingDraft` (đều có test thuần Dart, không cần widget):
- `assign(column, slot)`: cột khóa (`index`/`sensitive`) trả về chính nó. Nếu `slot != null`, xóa mọi cột khác đang giữ `slot` (cột đó tự về Ghi chú vì không còn trong mapping, `parseRosterSheet` dòng 829–836 đưa mọi cột chưa ghép vào ghi chú `Tên cột: giá trị`). `slot == null` gỡ cột khỏi mọi slot kể cả `notes`. Nếu `slot` là `player2*` mà `effectiveLayout == single` thì đặt layout `columns` và `layoutChosen = true` (như Web `handleMappingChange`).
- Cột khóa: `index` khi `isRosterIndexHeader(header)` và cột không nằm trong mapping; `sensitive` khi `isSensitiveRosterHeader(header)` và cột không nằm trong mapping (nên `Địa chỉ email` đã ghép Email không bị khóa).
- `withHeaderRow(h)`: `headers = grid.rows[h]`; `firstDataRowIndex = h + 1`; `lastRowIndex = rows.length - 1` nếu khối không phải AI, giữ nguyên nếu là khối AI mà `h + 1 <= lastRowIndex`, ngược lại kẹp; `mapping = confirmRosterColumns(dataRows, headers, detectRosterColumnMapping(headers))` (đúng như Web `handleHeaderRowChange`); layout, separator, `layoutChosen` giữ nguyên.
- `withLayout`: đặt `layout`, `layoutChosen = true`, `separator` (nếu có). Với `RosterPairLayout.sameCell` mà separator rỗng, luật `firstSeparatorIn` tự dò.
- `headerMayBeShifted`: có vùng gộp (trong `mergedRegions` hoặc `horizontalMerges`) phủ `headerRowIndex` và `endColumn > startColumn` (cùng định nghĩa `mergedOverHeader`).
- Hàng tiêu đề đang là banner gộp ngang: người dùng thấy cảnh báo. Trường hợp file mẫu của người dùng (banner ở dòng 1, tiêu đề cột thật ở dòng 2): luật dò đúng dòng 2 nên không có cảnh báo; cảnh báo chỉ hiện khi người dùng tự đặt hàng 1.

`RosterReading` thêm `copyWith({int? headerRowIndex, int? firstDataRowIndex, int? lastRowIndex, RosterColumnMapping? mapping, RosterPairLayout? layout, String? separator, bool? layoutChosen, bool? fromAi})` và `final bool layoutChosen` (mặc định `false`, constructor const hiện có không vỡ). `assembleRosterRows` đổi điều kiện dòng 106 từ `layout == single` thành `layout == single && !reading.layoutChosen`; khi `layoutChosen && single`, `applyPairLayout(single)` xóa VĐV 2 như hiện có cho nội dung đôi (`roster_pairing.dart:486–494`). Dòng 119–122 (`consecutiveRows && hasCodes → single`) giữ nguyên: mã cặp thắng, như spec đã ghi.

### D3. Popup và kết quả AI: bản sửa thắng
Cơ chế sẵn có đủ, chỉ thêm hai dòng:
- `_requestAiLayout` dừng ngay nếu `requestId != _layoutRequest` (`roster_import_sheet.dart:620, 643`) và coi như người dùng đã sửa nếu `_editRevision` đổi (:626–629, kết quả AI bị bỏ, trạng thái về `rules`).
- `Xong` của popup chạy `_layoutRequest++; _editRevision++` rồi đặt `_layoutStatus = _LayoutStatus.edited` (giá trị enum mới, không có thông báo, vì "Đã dùng bố cục do AI" (:1176) sẽ sai).
- Nút `Ghép cột` tắt khi `_layoutStatus == loading` (:554, :1155). Không mở popup trong lúc AI chưa trả lời, nên `_readings` không đổi dưới chân popup và chỉ số khối trong `RosterMappingResult` luôn khớp.
- Khi đọc file khác, `_pickFile` (:514) đặt lại `_editRevision = 0` và đọc lại như cũ: mọi sửa của file trước mất, đúng ý.

### D4. Áp dụng kết quả popup vào màn
Thêm `_applyMapping(RosterMappingResult result)` trong `_RosterImportSheetState`:
1. `_readings = result.readings`; `_skippedSheets = result.skippedSheets`.
2. `final parsed = _assembleWorkbook(_readings, _skippedSheets)` (:474; dựng dòng, kiểm tra cục bộ, nhóm).
3. Không gọi `_installParsed` (:580): hàm đó xóa `_createdDivisions` (:591) nên nội dung vừa tạo bị quên và bước xác nhận tạo nội dung hiện lại. Thay vào: gán `_rows/_groups`, `_preview = null`, `_previewPlan = null`, `_previewError = null`, `_candidates.clear()` (chỉ số dòng đã đổi), tính lại `_pendingDivisionConfirm` và `_createChoice` từ các nhóm `divisionId == null`; giữ `_createdDivisions`.
4. Nếu không còn `_pendingDivisionConfirm`: `unawaited(_runPreview())`.
5. Liên kết tài khoản (`_PlayerLink`) của dòng cũ mất vì `_DraftRow` mới (chỉ số dòng không còn nghĩa). Chấp nhận, ghi trong spec.
6. Nếu đợt 2 đã có chỉnh sửa tay (xóa/thêm/sửa dòng) thì hỏi xác nhận trước khi mở popup ("Ghép lại sẽ bỏ các sửa tay"): task 4.5. Đợt 1 không có sửa tay nên không cần.

Nội dung đã tạo trong phiên giữ nguyên nên nếu người dùng đã bấm "Tạo nội dung" thì không tạo lại; kể cả khi tạo lại, `_createMissingDivisions` hỏi `getManageDivisions` và tái dùng nội dung trùng tên (:708–722), không sinh trùng.

### D5. Hàng tiêu đề, sheet không có tiêu đề, nhiều khối
- Hàng tiêu đề UI đánh số từ 1; nội bộ 0-based. Ô nhập số có nút -/+ (vùng chạm 44 dp), kẹp [1, rows-1]. Đổi hàng gọi `withHeaderRow`.
- Sheet không dò được tiêu đề (`readSheetByRules` trả `null`, :72) hiện trong popup dưới dạng thẻ chọn (`wasSkipped`): `forSkippedSheet` đặt hàng tiêu đề là dòng đầu có từ hai ô; mapping dò từ dòng đó; sau khi người dùng ghép đủ nhận diện và có dòng thì sheet thành khối đọc được, nếu không vẫn nằm trong `skippedSheets`.
- Nhiều khối/sheet: đầu popup có dải chip tên sheet (và khối) khi có hơn một mục, chấm đỏ cạnh mục thiếu nhận diện. `Xong` chỉ bật khi mọi mục không phải skipped đều có nhận diện.
- Khối AI giữ `divisionLabel`, `singlesFromRow`, `titleLabels`: `copyWith` không đụng các field này, nên đổi cột không làm mất tên nội dung AI nêu.

### D6. Ghép cặp `CONSECUTIVE_ROWS` đã có
`RosterPairLayout.consecutiveRows` (`roster_pairing.dart:398`), `pairConsecutiveRows` (:401–427), `applyPairLayout` (:486–504) và `hasRosterPairEvidence` (`roster_layout.dart`, chỉ áp cho khối AI) đã có. Test đang phủ file cặp hai dòng gộp STT (`roster_import_sheet_test.dart` nhóm `TC-APP-ROSTER-SHEET`, fixture `roster_fixture_workbook.dart`). Thiếu: chọn tay từ popup (task 1.3/1.4 phủ bằng test thuần Dart). Không cần task riêng.

### D7. Email và tài khoản Sporto (quyết định của người dùng: Backend đã đủ, App chỉ gọi cho kỹ)
Bằng chứng từ code:

(a) Khi nào App gọi preview. `_runPreview` (:864) được gọi từ: sau đọc file nếu luật đủ tin (:561), sau khi AI trả lời (:638, :647), sau tạo nội dung (:759), sau bỏ qua tạo (:767), `_setLink` (:927), `_setAutoApprove` (:940) và nút `Thử lại` (:1303). Không debounce. Chống kết quả cũ đè mới bằng `_previewGeneration`: mỗi lần chạy tăng bộ đếm (:865), mọi `await` xong đều kiểm `generation != _previewGeneration` rồi bỏ (:893, :897, :910); `dispose` cũng tăng (:410). Request cũ không bị huỷ ở tầng Dio (interface repository không có `CancelToken`, và không đổi API), nhưng kết quả bị bỏ. Timeout 30 giây connect/send/receive (`dio_client.dart:55–57`); lỗi mạng/timeout vào nhánh `catch` (:896) đặt `_previewError` và hiện `Thử lại`; commit tắt vì `_preview == null`. Vòng lặp tối đa 3 lần cho tới khi tập tài khoản tự liên kết hội tụ (:884–895). Bấm đúp: lần thứ hai tăng bộ đếm nên lần thứ nhất bị bỏ.

Quyết định mới: sửa trong chi tiết giữ trong bản nháp của sheet chi tiết (controller), chỉ áp vào dòng khi bấm `Xong`, nên mỗi lần sửa chỉ sinh đúng một preview. Không cần debounce theo từng phím. Popup ghép cột cũng chỉ áp khi `Xong`.

(b) Sửa email thì preview chạy lại thế nào, `_PlayerLink` thế nào. `Xong` áp dòng mới và gọi `_runPreview` một lần. Backend chỉ chấp nhận `confirmedPlayerNUserId` khi email vẫn khớp đúng ứng viên: `resolveConfirmedRosterUserId` (`roster-import-batch.ts:141–155`) ném `ConflictException` ("Tài khoản được chọn không còn khớp với email") nếu `candidate.id !== selectedUserId` hoặc email lệch. Vì vậy khi email đổi, `_PlayerLink` của VĐV đó về `auto` và `_candidates[row.index]` bị xóa (khi không, payload kế tiếp mang `confirmedPlayerNUserId` cũ và preview báo 409). Đổi tên/SĐT/ghi chú/đã đóng phí thì giữ liên kết. `auto` được phân giải ở `_effectiveLink` (:842–850): liên kết khi đúng một ứng viên trùng email chính xác (`_uniqueExactAccountId` :282–292), khớp `uniqueExactAccountId` của Web.

(c) Email sai định dạng, trùng trong file, trùng trong giải. Sai định dạng: client, `_localErrors` trong parser (:598–619, regex :506) gắn `INVALID_EMAIL`, nằm trong `_localBlockingCodes` (:23–29) nên dòng không vào payload (`_buildPlan` :786); thẻ hiện ✕ từ mã cục bộ (`codes = server != null ? server.status : row.localStatus`, :1541). Trùng trong file: client, `_duplicateRowIndices` (:264–279) gắn `DUPLICATE_IN_FILE` cho mọi dòng liên quan (cả VĐV 1 lẫn VĐV 2), chặn như trên; Backend cũng kiểm (`roster-import-batch.ts:124`). Trùng trong giải: chỉ server (`existingEmailsByDivision`, `tournament-import.repository.ts:1590–1600`) trả `DUPLICATE_IN_TOURNAMENT`; App chỉ hiện mã đó. Thiếu email (`MISSING_EMAIL`) không chặn, đúng như `_serverBlockingCodes` (:31–40). Backend `@IsEmail()` cho `player1Email` (`roster-import-batch.dto.ts`) nên không bao giờ gửi email sai định dạng lên (đã chặn cục bộ).

(d) `FOUND/NOT_FOUND` trên thẻ. Backend gắn `FOUND`/`NOT_FOUND` theo từng email hợp lệ (`applyAccountStatuses`, `tournament-import.repository.ts:205–210`) dựa trên tài khoản đã xác minh email, đủ điều kiện, có tên hồ sơ (`findRosterBatchAccountCandidates` :219–264). Thẻ không in chữ: icon liên kết xanh cho VĐV có `_effectiveLink != null`, icon người mờ khi có email mà không ứng viên nào, không icon khi chưa có preview. Tròn trạng thái: `NOT_FOUND` không phải cảnh báo (VĐV khách vẫn nhập được). Chữ đầy đủ (`rosterImportStatusFound/NotFound`) chỉ nằm trong chi tiết.

(e) Commit gửi đúng lựa chọn. `_commit` (:1008) lấy `previewPlan.request` (payload đã được preview và đã mang `confirmedPlayerNUserId` do `_itemFor` dựng :826–837), lọc theo dòng `isEligible`, và chỉ chạy được khi `previewCurrent` (khóa JSON của plan hiện tại bằng plan đã preview, :1071–1076; `canCommit` :1097). `Idempotency-Key = roster:<id>:<sha256 canonical JSON>` (repository :408–413): cùng payload cùng key. `_committing` chặn bấm đúp (:1011, :1448).

Không thấy chỗ nào Backend thiếu cho các ý trên. Không có mục nào cần ghi vào "Câu hỏi còn mở" cho Backend.

### D8. Sửa dòng (đợt 2)
- Mô hình: `RosterDraftRow.parsed` đổi thành `RosterParsedRow parsed` (field không còn `final`); lớp đã có `target`, `localStatus`, `player*Link` thay đổi được (`roster_import_sheet.dart:176–192`) nên nhất quán. Mọi sửa đi qua một hàm `applyRowEdit(row, edit)` trong state (không sửa `parsed` rải rác). `RosterParsedRow` giữ bất biến: sửa tạo bản sao bằng `copyWith`.
- `RosterParsedRow.copyWith` thêm `clearPlayer1Name`, `clearPlayer1Email`, `clearPlayer1Phone`; export `rosterLocalErrors({name, email, player2Email})` (đổi tên `_localErrors`, parser :598). Sau sửa: `parsed = parsed.copyWith(..., localErrors: rosterLocalErrors(...))`, rồi `_recomputeLocalStatus()` chạy `_duplicateRowIndices` và `_localStatusOf` cho cả danh sách (trùng email là quan hệ giữa các dòng).
- Chỉ số: `clientRowIndex` = `_DraftRow.index`, duy nhất trên workbook (:179, :482). Xóa dòng không đánh số lại (Backend chỉ cần duy nhất trong 0..499, `roster-import-batch.dto.ts`). Thêm dòng lấy chỉ số nhỏ nhất chưa dùng trong 0..499 (bỏ qua chỉ số của dòng vừa xóa còn chờ hoàn tác). `_buildPlan` đã trả `null` khi `_rows.length > 500` (:781).
- Nhóm: dòng thêm tay vào nhóm `_targetFor(null)` (nội dung đang mở); xóa dòng cuối nhóm thì bỏ nhóm. Nhóm không khớp giải (`divisionId == null`) vẫn tồn tại như hiện nay.
- Dòng thêm tay: `RosterParsedRow(sheetName: '', sourceRowIndex: 0, ...)`; `_itemFor` gửi `sourceRowIndex: parsed.sourceRowIndex > 0 ? parsed.sourceRowIndex : null` và `sourceSheetName: parsed.sheetName.isEmpty ? null : parsed.sheetName` (`toJson` đã bỏ qua chuỗi rỗng, `roster_import.dart:57–76`). Thẻ không hiện "Dòng N · sheet" cho dòng thêm tay.
- Hoàn tác: có, vì xóa nhầm một cặp là thao tác mất dữ liệu. Chi phí nhỏ: giữ `(row, groupIndex, positionInGroup)` trong state tới khi hết 5 giây hoặc có chỉnh sửa khác. Không có hoàn tác nhiều bước cho sửa trường (nút `Đóng` của chi tiết đã là "hủy").
- Chi phí `Xóa cặp` và `+ Thêm VĐV` (câu hỏi bàn giao): mỗi nút khoảng 40–60 dòng logic trong state + một test; sự phức tạp nằm ở chỉ số 0..499, nhóm, hoàn tác. Tách riêng thành task 4.5 để người dùng có thể bỏ nếu muốn đợt 2 nhỏ hơn (thẻ + chi tiết sửa được vẫn đủ dùng).

### D9. Thẻ danh sách
`RosterPairCard` nhận `RosterDraftRow`, `RosterImportBatchPreviewRow?` (server), cờ `previewing`, và callback `onTap`. Hàm thuần `RosterCardStatus rosterCardStatus(...)` (enum `ok/warning/blocked/loading`) tách khỏi widget để test không cần pump:
- `blocked`: `server != null` mà `!_isRowEligible(server)`, hoặc (server null và `!row.localEligible`).
- `warning`: không blocked và (`status` chứa `MISSING_EMAIL`, hoặc nội dung đôi mà dòng chưa có VĐV 2).
- `loading`: server null và `previewing` và `row.localEligible`.
- còn lại `ok`.

Mã cảnh báo hiện một dòng chữ nhỏ dưới tên (như mockup "Thiếu SĐT"), lấy chuỗi `_statusLabel` có sẵn.

### D10. Ít chữ, theme
Màu lấy từ `context.colors` (`bgCard`, `bgSurface`, `border`, `textPrimary/Secondary/Muted`, `success`, `warning`, `error`); không hardcode hex của mockup (mockup dùng `#1D8EF8`... chỉ để minh hoạ). Icon `Icons.*_rounded`, không emoji. Bố cục popup theo mockup khung 2 và 5: bottom sheet `isScrollControlled`, cao 0.92 như sheet hiện có (:1327), `maxWidth` 640; dòng cột là `InkWell` ≥ 56 dp; chip cao 40 dp; chân sheet cố định. Khác mockup có chủ ý: (1) không có nút `Tiếp tục` ở khung 1: đọc xong là hiện danh sách luôn như hiện nay, `Ghép cột` là việc phụ; (2) thêm chip VĐV 2 (SĐT, Email) khi nội dung đôi và ô ký tự ngăn cách khi chọn "Hai VĐV một ô", vì `RosterSlot` có đủ 12 slot và Web hiển thị cả hai.

### D11. Rủi ro và cách chặn
| Rủi ro | Cách |
|---|---|
| Preview đang chạy mà người dùng sửa tiếp | `_previewGeneration` bỏ kết quả cũ; nút nhập dựa vào `previewCurrent` |
| Bấm `Nhập` hai lần | `_committing` + `Idempotency-Key` theo nội dung |
| File lớn > 500 dòng | `rosterImportTooManyRows` (:1085) tắt nhập; `+` tắt ở 500 |
| File không có dòng/rỗng (`rows` rỗng) | popup `Xong` tắt khi `rowCount == 0`; `readRosterWorkbook` trả sheet `rows` rỗng; `withHeaderRow` kẹp khi `rows.length < 2` (không có hàng tiêu đề hợp lệ thì popup hiện thông báo `rosterImportNoRows` và không có danh sách cột) |
| Sheet không có tiêu đề | D5 |
| Tiêu đề trống / trùng tên cột | cột trống hiện chữ cột (`[C]`, đúng `headerOf` :818 của parser); trùng tên vẫn phân biệt theo chỉ số cột (App map theo chỉ số, Web theo tên nên phải thêm hậu tố) |
| Cột nhạy cảm bị lộ qua ghi chú | luật hiện có bỏ cột này khỏi ghi chú (parser :836); popup khóa cột; test kiểm ghi chú không có giá trị |
| `clientRowIndex` vượt 499 | chỉ số nhỏ nhất chưa dùng; không có dòng thứ 501 |
| Email đã đổi mà tài khoản cũ còn | D7(b) |
| Popup mở trong lúc AI trả lời | D3: nút tắt khi `loading` |

## Phương án đã loại

- **Bố cục y hệt Web (mỗi trường một dropdown, nhiều chữ):** người dùng chê "nhìn chả hiểu gì cả".
- **Chip "Bỏ qua" cho cột:** Web không có; cột không ghép đã mặc định vào Ghi chú.
- **Chi tiết chỉ xem + chip ghi chú:** Web cho sửa, đổi thành ô nhập + textarea.
- **Popup sửa thẳng `_readings`:** mọi chạm ghép lại mọi dòng và gọi preview; hủy được là yêu cầu của người dùng (đóng popup không đổi gì), nên dùng bản sao.
- **Tự khớp tài khoản theo email ở App:** người dùng chốt Backend đã đủ; tránh hai nguồn sự thật. App chỉ hiện `status`/`accountCandidates`.
- **Debounce preview theo từng phím:** chi tiết áp khi `Xong` nên không cần.
- **Thêm `RosterPairLayout.none`:** làm `switch` ở `applyPairLayout` (:486) phải đổi và đụng AI (`_layoutOf` mặc định `single`); cờ `layoutChosen` ít đụng hơn.
- **Tách `_RosterImportSheetState` thành notifier trong change này:** rủi ro vỡ test hiện có; ghi nợ.

## Câu hỏi còn mở

- Đợt 1 và đợt 2 làm cùng một change hay phát hành đợt 1 trước? Task đã tách để cả hai cách đều được: nhóm 1–3 độc lập với 4–5.
- `Xóa cặp` / `+ Thêm VĐV`: giữ trong đợt 2 (mặc định, task 4.5) hay bỏ cho nhỏ?
- Không nút `Tiếp tục` ở khung 1 (D10): xác nhận ý đồ.
- "Ngày sinh" và cột nhạy cảm: giữ nguyên "Không lưu" như Web, không có công tắc cho phép lưu.
