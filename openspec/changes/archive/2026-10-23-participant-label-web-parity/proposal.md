## Why

Ba chỗ App hiển thị đội/VĐV khác Web (chuẩn: `src/features/participants/participant-display.ts` và `src/components/ui/ParticipantIdentity.tsx` ở Web):

1. App thiếu luật tên ghép. Backend cũ tự đặt `teamName` = tên các VĐV nối bằng " / " (vd `Minh Khang / Hoang Linh`). Web nhận ra và hiện từng VĐV kèm avatar; App coi đó là tên đội thật nên hiện nguyên chuỗi, không avatar, không viết tắt.
2. Bố cục khác: Web dùng MỘT dòng mỗi bên (tối đa 2 avatar chồng nhau, chữ cái đầu 1 ký tự, tên nối " / " viết tắt ở chỗ hẹp); App xếp mỗi VĐV một dòng và lấy 2 chữ cái đầu.
3. Lỗi lặp: khi Backend trả `players[]`/`members[]` có trùng (thẻ trận hiện `L. N. P. Duy` 5 dòng), App vẽ nguyên số dòng đó. Gốc lỗi ở Backend (change `match-roster-dedupe`), App thêm lớp loại trùng phòng thủ.

## What Changes

- `resolveParticipantDisplay`: thêm luật tên ghép "A / B" như Web (`teamNameIsJoinedNames`).
- `ParticipantLabel` (PLAYERS): một dòng, tối đa 2 avatar chồng nhau, chữ cái đầu 1 ký tự, tên các VĐV nối " / " (viết tắt khi `compact`), tên đầy đủ qua Tooltip. TEAM giữ nguyên.
- Loại trùng VĐV theo `userId` (khách: theo tên chuẩn hoá) trong `toParticipantPlayers`, `participantPlayersFromMemberInfos`, `participantPlayersFromNames`.

## Out of scope

- Logo đội cho bóng đá hoặc đội trên 2 người, popup thông tin đội (Web có `teamPopupData`).
- Không đổi `abbreviateName` (đã giống Web), không đổi API hay model.
- Không đổi chuỗi i18n.

## Capabilities

### New Capabilities

(không có)

### Modified Capabilities

- `participant-display`: sửa luật chọn TEAM/PLAYERS, bố cục compact; thêm yêu cầu loại trùng VĐV.

## Impact

- App: `lib/core/participants/participant_display.dart`; widget `ParticipantLabel` có 20 file gọi (thẻ trận, bracket, explore, organizer, tournament...), nên test widget cũ tìm từng dòng tên có thể phải đổi.
- Backend: không đổi (change `match-roster-dedupe` ở repo Backend giải quyết nguồn trùng).
- Web: không đổi.
