# Thiết kế: sửa ghép đôi, sơ đồ và tạo giải nhanh (App)

## Ánh xạ format và giới tính (quick create)

`quick_tournament_format_mapping.dart` là nguồn duy nhất cho payload:

- `quickTournamentApiFormatFields(key)`: `format` = `mixed_doubles` cho `MIXED_DOUBLES`; `singles` cho `*_SINGLES` và `FOOTBALL_*`; `doubles` còn lại. `genderRestriction: MIXED` cấp giải chỉ khi `MIXED_DOUBLES` hoặc `FOOTBALL_MIXED`.
- `quickTournamentDivisionFormatFields(key)`: `matchType` = `SINGLES` cho `*_SINGLES` và `FOOTBALL_*`; `MIXED_DOUBLES` → `MIXED_DOUBLES`; còn lại `DOUBLES`. `genderRestriction` cấp nội dung giữ nguyên (`MALE`/`FEMALE`/`MIXED`/null).
- `_contentDrafts` mặc định: `OPEN_DOUBLES` cho môn vợt. `_resetContentDraftsForSport` cho bóng đá giữ `FOOTBALL_MALE`.
- Payload: spread `quickTournamentApiFormatFields(primary)` vào cấp giải. Với `MALE`/`FEMALE` không còn gửi `genderRestriction` cấp giải (chỉ cấp nội dung).

## Giải CLB

`create_club_tournament_screen.dart` `resolvedFormat`: bóng đá → `singles`; `mixed_doubles` giữ nguyên thay vì ép `doubles`; còn lại theo `_selectedFormat`. Điều kiện `maxCombinedElo`/`maxTeammateGap` giữ `resolvedFormat == doubles`.

## Đếm thành viên ghép cặp (Lite)

`LiteParticipant` đọc thêm `customResponses` (Map, có thể null). Getter `memberCount` mô phỏng `countParticipantMembers` của backend (`doubles-pair-member.ts:34-44`):

- Nếu `customResponses.importedFrom` thuộc nhóm nhập của BTC → `max(rosters.length, player2Name|player2Email ? 2 : 1)`.
- Còn lại → `rosters.length`.

Nhóm nhập của BTC = `ORGANIZER_DIRECT` cộng `IMPORT_SOURCES` (`roster-import.dto.ts:16`). App sao chép danh sách này thành hằng số; nếu backend thêm nguồn mới, phải cập nhật cả hai.

`isPending` = `PENDING_PARTNER` && không có `teamInviteToken` && `memberCount == 1`. `isComplete` giữ nguyên định nghĩa cũ (COMPLETE, hoặc PENDING_APPROVAL với từ 2 thành viên trở lên) và dùng `memberCount`.

## Tạo sơ đồ Lite

`LitePairingScreen._generateBracket`: nếu `payload['divisions']` có đúng một phần tử có `id`, gửi `{divisionId}`; ngược lại không gửi body. Phản hồi: đọc `unpairedNames` (List<String>) và `autoPaired` nếu có; hiện snackbar với danh sách tên không ghép được. Lỗi hiện thông điệp backend như cũ.

## Lưu sơ đồ không dùng createBatch

- Xoá `createBatch` khỏi `IMatchRepository`, `ApiMatchRepository`, và `PublishTournamentDrawUseCase` (cutover).
- Thêm `generateBracket({tournamentId, divisionId, seedingType, allowReset = false})` vào repository giải đấu (`ITournamentRepository` và triển khai API). Gửi `POST /tournaments/:id/generate-bracket` với body đúng hợp đồng. Trả về `BracketGenerationResult { autoPaired: List<AutoPairedEntry>, unpairedNames: List<String> }`; trường thiếu → rỗng.
- `auto_draw_screen._saveMatches` gọi repository mới thay vì use case cũ. `seedingType` lấy từ lựa chọn xem trước (kiểm trong file khi sửa).
- Lỗi 400 (thiếu `divisionId` khi có nhiều nội dung; sơ đồ đã có khi `allowReset` false) đi qua `e.toString()` và hiện trên snackbar.

## Trạng thái

`StatusHelper.normalizeTournamentStatus`:
- Alias tường minh: `REGISTRATION_OPEN` → registration; `REGISTRATION_CLOSED` → closed; `DRAFT`, `UPCOMING`, `DRAWING`, `ONGOING`/`IN_PROGRESS`/`LIVE`, `COMPLETED`/`FINISHED`, `CANCELLED` như cũ.
- Bỏ `PUBLISHED`, `ACTIVE`, `OPEN`, `REGISTRATION`, `REGISTER_OPEN` và nhánh suy đoán theo chuỗi con.
- Giá trị lạ không rỗng → chữ thường nguyên văn; `getTournamentStatusLabel` trả nguyên văn đó (không rơi về "Sắp diễn ra").
- Null/rỗng giữ `upcoming` như cũ.
- Không thêm khoá i18n mới cho trạng thái lạ.
