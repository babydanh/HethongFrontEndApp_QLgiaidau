# Thiết kế: sửa ghép đôi, sơ đồ và tạo giải nhanh (App)

## Ánh xạ format và giới tính (quick create)

`quick_tournament_format_mapping.dart` là nguồn duy nhất cho payload:

- `quickTournamentApiFormatFields(key)`: `format` = `mixed_doubles` cho `MIXED_DOUBLES`; `singles` cho `*_SINGLES` và `FOOTBALL_*`; `doubles` còn lại. `genderRestriction: MIXED` cấp giải chỉ khi `MIXED_DOUBLES` hoặc `FOOTBALL_MIXED`.
- `quickTournamentDivisionFormatFields(key)`: `matchType` = `SINGLES` cho `*_SINGLES` và `FOOTBALL_*`; `MIXED_DOUBLES` → `MIXED_DOUBLES`; còn lại `DOUBLES`. `genderRestriction` cấp nội dung giữ nguyên (`MALE`/`FEMALE`/`MIXED`/null).
- `_contentDrafts` mặc định: `OPEN_DOUBLES` cho môn vợt. `_resetContentDraftsForSport` cho bóng đá giữ `FOOTBALL_MALE`. Dải nút chọn nội dung (`_defaultFormatKeys`) của môn vợt là `OPEN_DOUBLES`, `MIXED_DOUBLES`; không còn Đôi Nam/Đôi Nữ mặc định (vẫn chọn được qua dialog).
- Payload: spread `quickTournamentApiFormatFields(primary)` vào cấp giải. Với `MALE`/`FEMALE` không còn gửi `genderRestriction` cấp giải (chỉ cấp nội dung).

## Giải CLB

`create_club_tournament_screen.dart`: hàm thuần `resolveClubFormat({sport, selectedFormat})` ở đầu file. Bóng đá → `singles`; `mixed_doubles` giữ nguyên thay vì ép `doubles`; còn lại theo `selectedFormat`. `_submit` gọi hàm này vào biến `resolvedFormat`; điều kiện `maxCombinedElo`/`maxTeammateGap` giữ `resolvedFormat == doubles`.

## Đếm thành viên ghép cặp (Lite)

`LiteParticipant` đọc thêm `customResponses` (Map, có thể null). Getter `memberCount` mô phỏng `countParticipantMembers` của backend (`doubles-pair-member.ts:34-44`):

- Nếu `customResponses.importedFrom` thuộc nhóm nhập của BTC → `max(rosters.length, player2Name|player2Email ? 2 : 1)`.
- Còn lại → `rosters.length`.

Nhóm nhập của BTC = `ORGANIZER_DIRECT` cộng `IMPORT_SOURCES` (`roster-import.dto.ts:16`). App sao chép danh sách này thành hằng số; nếu backend thêm nguồn mới, phải cập nhật cả hai.

`isPending` = `PENDING_PARTNER` && không có `teamInviteToken` && `memberCount == 1`. `isComplete` giữ nguyên định nghĩa cũ (COMPLETE, hoặc PENDING_APPROVAL với từ 2 thành viên trở lên) và dùng `memberCount`.

## Tạo sơ đồ Lite

`LitePairingScreen._generateBracket`: nếu `payload['divisions']` có đúng một phần tử có `id`, gửi `{divisionId}`; ngược lại không gửi body. Phản hồi: đọc `unpairedNames` (List<String>) và `autoPaired` nếu có; hiện snackbar với danh sách tên không ghép được. Lỗi hiện thông điệp backend như cũ.

## Lưu sơ đồ qua generate-bracket (không dùng createBatch)

- Xoá `createBatch` khỏi `IMatchRepository` và `ApiMatchRepository`; xoá `PublishTournamentDrawUseCase` và provider của nó (cutover, không shim).
- `ITournamentRepository.generateBracket(tournamentId, {divisionId?, required seedingType, allowReset = false})` trả `Future<Map<String, dynamic>>`, cùng kiểu với `getGroupStandings`; không thêm entity mới. Gửi `POST /tournaments/:id/generate-bracket` với body `{divisionId?, seedingType, allowReset}`.
- `divisionId` chỉ gửi khi giải có đúng một nội dung. Nhiều nội dung thì không đoán: backend trả 400 "Vui lòng chọn nội dung để tạo sơ đồ.", App hiện đúng thông điệp đó.
- `seedingType` = `RANDOM` cho cả nút bốc tay và bốc tự động. Đây là suy luận từ `auto_draw_screen.dart` (màn không có lựa chọn seeding); `allowReset` = `false`.
- Sau khi server trả thành công: giữ `update(status: IN_PROGRESS)` như luồng cũ (backend không tự chuyển trạng thái), invalidate provider giải/trận/sơ đồ, rồi pop. Sơ đồ hiện ra là bản tải lại từ server; không giữ bản xem trước cục bộ.
- Bản xem trước (`_generatePreview`) chỉ để BTC xem. Bản xem trước có thể khác bản chính thức vì server sinh lại sơ đồ.
- Response: `autoPaired` và `unpairedNames` là tuỳ chọn; đọc qua `core/utils/bracket_generation_summary.dart`, thiếu trường → rỗng.
- Lỗi: `_errorText` ưu tiên `message` trong body backend, sau đó `friendlyDioErrorMessage`, cuối cùng `error.toString()`.

## Trạng thái

`StatusHelper.normalizeTournamentStatus`:
- Alias tường minh: `REGISTRATION_OPEN` → registration; `REGISTRATION_CLOSED` → closed; `DRAFT`, `UPCOMING`, `DRAWING`, `ONGOING`/`IN_PROGRESS`/`LIVE`, `COMPLETED`/`FINISHED`, `CANCELLED` như cũ.
- Bỏ `PUBLISHED`, `ACTIVE`, `OPEN`, `REGISTRATION`, `REGISTER_OPEN` và nhánh suy đoán theo chuỗi con.
- Giá trị lạ không rỗng → chữ thường nguyên văn; `getTournamentStatusLabel` trả nguyên văn đó (không rơi về "Sắp diễn ra").
- Null/rỗng giữ `upcoming` như cũ.
- Không thêm khoá i18n mới cho trạng thái lạ.
