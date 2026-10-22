## Context

Thể thức Thụy Sĩ (`the-thuc-thuy-si`, nhánh `thuy-si-20261021`) hiện đứng riêng: đủ `totalRounds` vòng thì chỉ có bảng xếp hạng và podium top 3. Giải esport/cờ thường dùng Thụy Sĩ làm vòng loại rồi cho top N vào loại trực tiếp. Hệ thống đã làm việc tương tự cho vòng bảng (`GROUP_STAGE_KNOCKOUT`: hai stage nối nhau, BTC bấm `advance-standings` để đổ đội vào cây). Change này cho Thụy Sĩ làm được tương tự, tái dùng tối đa.

Khảo sát code thật (2026-10-22, trước khi lập plan):
- `generateGroupStageKnockout` (`bracket-generator.service.ts:1272-1779`) tạo stage 1 `ROUND_ROBIN` + stage 2 loại trực tiếp với cây rỗng (`:1559-1637`, cỡ lũy thừa 2, `nextMatchId` nối theo `floor(i/2)`).
- `advanceStandings` (`:1782-2066`) đổ đội theo cách chéo bảng (A1-B2...) và khóa `stage1.type === 'ROUND_ROBIN'` (`:1796`); KHÔNG dùng lại được cho Swiss.
- `computeSwissStandings` (`utils/swiss-standings.ts:289`) là hàm thuần trả `rank` 1..N: dùng lại nguyên.
- `getSeedingOrder` (`bracket-generator.service.ts:1103`, `private`) cho thứ tự hạt giống chuẩn: chuyển ra util dùng chung.
- Web `BracketTab.tsx` (organizer) ẩn nhánh loại trực tiếp khi là Swiss (`knockoutOnly={!isSwiss}`); App `bracket_view_screen.dart:310-323` coi mọi giải có trận Swiss là Swiss thuần.

## Quyết định
- **Cấu hình là một khóa trong `roundConfig.swiss` (`advanceTopN`), không thêm `bracketType` mới.** Lý do: Swiss giữ nguyên mọi nhãn, icon, minh họa, bộ lọc ở cả 3 repo; không phải sửa ~25 bảng nhãn theo `bracketType`. `0` = hành vi cũ nên giải đang chạy không đổi.
- **BTC bấm nút `advance` sau khi Swiss xong** (không tự động). Lý do: còn dịp xử lý hòa ở biên top N và kiểm điểm; giống `advance-standings` của vòng bảng.
- **Xếp cây hạt giống chuẩn (hạng 1 gặp hạng cuối), không tránh gặp lại.** Người dùng duyệt 2026-10-22. Thuật toán tránh trùng cặp bị loại vì phá thứ tự hạt giống.
- **Cây loại trực tiếp tạo rỗng lúc sinh sơ đồ**, đổ đội lúc `advance`. Lý do: giống GSK nên Web/App/overlay đã biết vẽ cây rỗng; `undo` vòng Swiss chưa đấu không đụng stage 2.
- Bị loại (YAGNI): nhánh thua/DE sau Swiss, trận hạng ba (không generator nào sinh, đồng hạng ba chia cho hai đội thua bán kết như hiện tại), tự động đổ khi trận cuối xong, tránh gặp lại, nút `advance` trong App (App chỉ cấu hình và xem; BTC bấm trên Web, ghi ở mục "Câu hỏi còn mở").

## Rủi ro và cách chặn
- **Hòa ở biên top N** (cùng điểm và mọi tiêu chí): cảnh báo `BOUNDARY_TIE`, cần `confirmWarnings`.
- **Trận hòa ở loại trực tiếp** (bóng đá không bật `penaltyShootout`): cảnh báo `DRAW_WITHOUT_PENALTY`; chặn nhập hòa vẫn do `matches.service.ts:2147-2150` đang làm.
- **Hai logic "Swiss xong" lặp** (`roundIsComplete` ở `tournament-swiss.service.ts:149-156` và `hasCompletedSwissRounds` ở `tournament-results.service.ts:39-60`): task thêm điều kiện thứ ba nên gom về một hàm dùng chung, không viết lần thứ ba.
- **`followsGroupStage`** (`repositories/tournament-bracket.repository.ts:611-624`) chỉ nhận `ROUND_ROBIN`: nếu không thêm `SWISS`, `resolveSingleTeamFirstRound` có thể tạo BYE sai khi BTC kéo-thả ô cây sau Swiss.
- **Podium**: `buildSwissAwards` (`tournament-results.service.ts:428`) chỉ chạy khi chưa có trận loại trực tiếp (`:211-214`); phải có test chứng minh khi có stage 2 podium lấy từ cây.
- **Sửa điểm một trận Swiss đã xong sau khi đã đổ cây** làm danh sách top N lệch cây hiện tại: chấp nhận, ghi trong spec, không chặn ở v1 (gọi lại `advance` khi cây chưa đấu sẽ điền lại).
- **`advance` không phát socket ở `advanceStandings` cũ**: route mới phát `bracket:update` (`SWISS_ADVANCED`) để Web/App công khai tự cập nhật.
- **Số đội thay đổi** (rút, vào muộn) sau khi sinh sơ đồ: `advance` kiểm lại `advanceTopN <= số đội hợp lệ hiện tại`.

## Hợp đồng chung Backend ↔ Web ↔ App (nguồn: Backend; bản sao nguyên văn ở cả 3 repo, đổi một nơi phải đổi cả ba)

Mở rộng hợp đồng của change `the-thuc-thuy-si` (cùng tiền tố `/api/v1/tournaments`, cùng bọc `{ statusCode, message, data, meta }`, cùng quyền như các route Swiss). Mọi thứ không nêu ở đây giữ nguyên. Định danh trường dùng đúng tên viết ở đây.

### 1. Cấu hình
- Thêm vào `roundConfig.swiss` (của division trước khi sinh sơ đồ; của stage sau khi sinh): `advanceTopN: number` — số nguyên; `0` = không có loại trực tiếp (mặc định, hành vi cũ); ngược lại `2..64`. Thiếu khóa = `0`.
- `bracketType` vẫn là `'SWISS'`. Không migration (`roundConfig` là jsonb).
- `advanceTopN` chỉ đặt được khi tạo/sửa nội dung TRƯỚC khi sinh sơ đồ. Sau khi đã sinh sơ đồ, `PATCH /api/v1/tournaments/stages/:stageId` gửi `swiss.advanceTopN` khác giá trị đã lưu → 409 `SWISS_ADVANCE_LOCKED` (muốn đổi: tạo lại sơ đồ bằng luồng sẵn có).
- Khi sinh sơ đồ mà `advanceTopN > 0` và số đội hợp lệ N < `advanceTopN` → 400 `SWISS_ADVANCE_INVALID`.

### 2. Sơ đồ
- Khi `advanceTopN > 0`, sinh sơ đồ Swiss tạo thêm stage thứ hai: `name = 'Vòng loại trực tiếp'`, `type = 'SINGLE_ELIMINATION'`, `order = 2`, `roundConfig.advanceMapping = { source: 'SWISS', totalAdvancing: advanceTopN }`. Cây rỗng kích thước `P = 2^ceil(log2(advanceTopN))` (cùng cách dựng với `generateGroupStageKnockout`: ô chưa có đội để `null`, không trận hạng ba, không nhánh thua). Stage Swiss giữ `order = 1` và mọi hợp đồng cũ.
- Tạo lại sơ đồ xóa mềm cả hai stage.

### 3. Luật nghiệp vụ
- **Swiss xong** = `currentRound >= totalRounds` và mọi trận không-BYE của stage Swiss `COMPLETED`.
- **Danh sách vào loại trực tiếp** = `advanceTopN` đội đầu của `computeSwissStandings` (hạng 1..`advanceTopN`; hạng chính là hạt giống trong cây).
- **Xếp cây**: hạng `s` vào đúng ô theo thứ tự hạt giống chuẩn của cây cỡ `P` (`getSeedingOrder(P)`: hạng 1 gặp hạng P, hạng 2 gặp hạng P-1...). Hạng lớn hơn `advanceTopN` là ô trống nên hạng cao được BYE (`resolveKnockoutByes`). KHÔNG tránh việc hai đội đã gặp nhau ở vòng Swiss (người dùng đã duyệt 2026-10-22).
- **Cảnh báo** (cần `confirmWarnings: true` mới chạy tiếp):
  - `BOUNDARY_TIE`: đội hạng `advanceTopN` và đội hạng `advanceTopN + 1` bằng nhau ở `totalPoints` và ở mọi tiêu chí trong `tiebreakOrder` (kể cả `SEED`, hai seed rỗng coi là bằng); `participantIds` = mọi đội bằng nhau ở biên đó. Thứ tự cuối cùng theo `participantId` chỉ là khử hòa kỹ thuật, không phải theo thành tích.
  - `DRAW_WITHOUT_PENALTY`: luật môn cho phép hòa ở Swiss mà `tournamentConfig.penaltyShootout !== true` (trận hòa ở loại trực tiếp sẽ bị chặn nhập điểm); `participantIds = []`.
- **Gọi lại** `advance` khi chưa có trận loại trực tiếp nào bắt đầu: xóa đội khỏi mọi ô rồi điền lại theo bảng xếp hạng hiện tại (idempotent, bấm đúp an toàn). Đã có trận loại trực tiếp bắt đầu/kết thúc: 409 `SWISS_KNOCKOUT_STARTED`.
- **Podium**: khi giải có stage loại trực tiếp của Swiss, podium lấy từ cây loại trực tiếp (như vòng bảng), không lấy từ bảng Swiss; chưa xong chung kết thì chưa có podium.

### 4. Endpoint
`POST /:id/swiss/advance` body `{ divisionId: string; stageId?: string; confirmWarnings?: boolean }` (`stageId` = stage SWISS; bỏ trống = stage SWISS đang hoạt động) → 201
```ts
{ knockoutStageId: string; qualified: { rank: number; participantId: string }[] }
```
Lỗi: 400 `SWISS_NOT_SWISS`; 409 `SWISS_ADVANCE_DISABLED` (`advanceTopN = 0`, không có stage loại trực tiếp); 409 `SWISS_ROUNDS_REMAINING` (chưa sinh đủ `totalRounds` vòng); 409 `SWISS_ROUND_INCOMPLETE` (vòng cuối còn trận chưa xong); 409 `SWISS_ADVANCE_INVALID` (số đội hợp lệ hiện tại < `advanceTopN`); 409 `SWISS_KNOCKOUT_STARTED`; 409 `SWISS_WARNINGS_UNCONFIRMED` (body kèm `warnings: { type: 'BOUNDARY_TIE' | 'DRAW_WITHOUT_PENALTY'; participantIds: string[] }[]`); 409 `SWISS_TOURNAMENT_CLOSED` (như `next-round`). Mã `SWISS_ADVANCE_LOCKED` do `PATCH /stages/:stageId`.
Trong MỘT transaction: khóa hàng giải `FOR UPDATE`, kiểm lại mọi điều kiện, điền ô, `resolveKnockoutByes`, xóa cache, phát `bracket:update`.
Đọc: `GET /:id/bracket` trả cả hai stage; `GET /:id/standings` giữ nguyên (stage SWISS có `rank`).

### 5. Realtime
`bracket:update.action` thêm `'SWISS_ADVANCED'` (`roundNumber = null`; `stageId` = stage loại trực tiếp).

### 6. Nhãn hiển thị (client)
- Ô cấu hình: vi `Số đội vào loại trực tiếp` (giá trị `0` hiển thị `Không`), en `Teams advancing to knockout`. Nút BTC: vi `Đưa vào loại trực tiếp`, en `Advance to knockout`.
- Sơ đồ có hai phần: stage Swiss (nhãn `Thụy Sĩ`) rồi stage 2 (nhãn loại trực tiếp sẵn có). Bảng xếp hạng Swiss kẻ một đường sau hạng `advanceTopN`.
- Mã lỗi hiển thị bằng tiếng Việt đời thường, một câu, đặt cạnh các mã `SWISS_*` hiện có (key = mã lỗi).
