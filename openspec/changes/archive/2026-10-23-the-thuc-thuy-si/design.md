## Context

- `Tournament.bracketType` bị `toLowerCase()` khi parse (`lib/domain/entities/tournament.dart:235-239`, division `:784`) và hằng là chữ thường (`lib/core/config/app_constants.dart:117-120`): thêm `bracketSwiss = 'swiss'`. `stageType` từ API giữ chữ HOA (`MatchModel.stageType`, `lib/domain/entities/match.dart:217`): so sánh `'SWISS'` (hàm tiện ích tự `toUpperCase`).
- Kiểu trận thật: `MatchModel` ở `lib/domain/entities/match.dart:129` (`round`, `status`, `isBye`, `stageType`, `team1Id`, `team2Id`, `winnerId`; `lib/data/models/match_model.dart` chỉ re-export).
- Xếp hạng: `standingsWithDivisionProvider` (`lib/providers/standings_provider.dart:25-64`) đọc `GET /tournaments/:id/standings`, rỗng mới tự tính từ trận (`:160-314`, không có Buchholz). `Standing` (`lib/domain/entities/standing.dart:3`) chưa có `rank`/`buchholz`.
- Sơ đồ/trận: `bracketMatchesWithDivisionProvider` (`lib/providers/query_providers.dart:277-305`, poll 15 giây) chỉ trả `List<MatchModel>`; thông tin stage (kể cả `roundConfig`) bị bỏ ở `lib/data/repositories/api/api_tournament_repository.dart:905-941`.
- Lớp API thật: interface `lib/domain/repositories/tournament_repository.dart` → `api_tournament_repository.dart` → `DioClient`. `lib/data/api_service.dart` (file sinh) không được app dùng: KHÔNG dùng.
- Đã có mẫu kéo thả cho BTC: `lib/features/bracket/screens/group_stage_assignment_screen.dart:368-400` (`LongPressDraggable<String>`), `bracket_diagram_screen.dart` (`PATCH .../bracket/slots`).
- Tiếng Anh/Việt qua `flutter gen-l10n` (`l10n.yaml`: `lib/l10n/app_vi.arb` mẫu, `app_en.arb`); file sinh `lib/l10n/app_localizations*.dart` nằm trong git, không sửa tay.

## Quyết định

- **Tin Backend cho xếp hạng Swiss**: khi dòng từ endpoint có `rank` thì dùng đúng thứ tự và giá trị đó, KHÔNG tự tính lại; chỉ khi endpoint rỗng mới theo đường cũ.
- **Thông tin stage tách riêng**: thêm `swissStageProvider` (poll 15 giây, cùng nhịp với sơ đồ) đọc stage SWISS từ `GET /tournaments/:id/bracket` để lấy `stageId` và `roundConfig.swiss`; không nhét vào `MatchModel`. Đổi lại thêm một request mỗi 15 giây khi xem Swiss; chấp nhận được.
- **Bản nháp ghép cặp ở client, kiểm bằng `validate`**; không lưu nháp lên Backend.
- **Hàm thuần không import Flutter** (`swiss.dart`, `swiss_round_state.dart`, `swiss_pairing_draft.dart`) để test bằng `flutter test` nhẹ.

## Luật UI cứng (đã chốt với người dùng; reviewer kiểm từng điểm)

1. **Một mặt phẳng**: không `Card` lồng `Card`, không `Container` có cả viền và bo góc quanh từng bàn. Ngăn bằng `Divider` mảnh và khoảng trắng.
2. **Hàng cặp là hàng chữ**: `Bàn · Tên · Điểm · vs · Tên · Điểm`; không avatar, không huy hiệu. Chỉ nút **Xác nhận** là khối đặc (`FilledButton`).
3. **Icon tối đa MỘT loại**: tay nắm kéo `Icons.drag_indicator`. Cảnh báo là dòng chữ màu cam, nút là nhãn chữ (`TextButton`).
4. **Trạng thái kéo**: ô đích đổi nền nhạt; không vẽ khung thả.
5. Bảng xếp hạng và danh sách tiebreak phẳng, không card.

**Màn Ghép cặp vòng N** (điện thoại một cột; ≥ 600 dp hai cột bằng `LayoutBuilder`):
```text
Vòng 3/5 · 12 cặp                          Ghép lại   Hoàn tác
──────────────────────────────────────────────────────────
Chưa ghép:  An 2.0 · Dũng 1.5
Nghỉ vòng này:  (thả vào đây)
──────────────────────────────────────────────────────────
 1  Bình 2.5   vs   Chi  2.5
 2  Dũng 2.0   vs   Hà   2.0      Đã gặp ở vòng 2
 3  Em   2.0   vs   Phúc 2.0
BYE Giang 1.0
──────────────────────────────────────────────────────────
[ Xác nhận vòng 3 ]  (cố định đáy, trong SafeArea)
```
- **Kéo**: nhấn giữ tên (`LongPressDraggable<String>` mang `participantId`), thả lên tên khác = hoán đổi; thả lên "Chưa ghép" = bỏ ghép; "Nghỉ vòng này" = nghỉ; dòng BYE = BYE. Giao diện đổi ngay; sau đó gọi `validate` (debounce 250 ms, bỏ kết quả lượt cũ). Bỏ qua khi thả đúng ô cũ.
- **Không chỉ kéo**: chạm tên → `showModalBottomSheet` danh sách chữ "Đổi với..." / "Chuyển tới..." (dùng được bằng TalkBack, bàn phím ngoài).
- **Cảnh báo không chỉ bằng màu**: dòng chữ "Đã gặp ở vòng 2", "BYE lần 2", "Chênh 2 điểm". Còn cảnh báo thì nút đổi nhãn "Xác nhận dù có cảnh báo" và gửi `confirmWarnings: true`.
- **Đủ chỗ mới xác nhận**: nút chỉ bật khi hết "Chưa ghép", không cặp thiếu một bên, và `validate` hợp lệ; còn thiếu thì hiện "Còn N đội chưa có chỗ".
- **Xung đột**: `409 SWISS_ROUND_EXISTS` → tải lại preview và báo "Vòng này vừa được tạo. Đã tải lại bản ghép cặp".
- **Responsive/a11y**: `SafeArea`, chữ dài `TextOverflow.ellipsis`, vùng chạm ≥ 48 dp, tôn trọng `MediaQuery.disableAnimations`, `Semantics` cho tay nắm kéo ("Giữ để kéo"), `Key` ổn định: `swiss-pairing-screen`, `swiss-pair-row-{i}`, `swiss-slot-{i}-{1|2}`, `swiss-pool`, `swiss-sitout`, `swiss-bye`, `swiss-auto`, `swiss-undo`, `swiss-confirm`, `swiss-chip-{participantId}`, `swiss-next-round`, `swiss-undo-round`. Theme/khoảng cách lấy từ `app_theme.dart`, `app_spacing.dart`, `app_typography.dart`.

**Xem Swiss**: hai tab thay cho ba tab của vòng bảng: `Xếp hạng` (bảng phẳng, cột Hạng, Đội, Trận, Thắng, Hòa, Thua, Điểm rồi cột Buchholz/Cut-1/Sonneborn-Berger/Hiệu số/Số thắng chỉ khi tiebreak đang bật; cuộn ngang khi hẹp) và `Lịch thi đấu` (trận theo vòng, bộ chọn vòng bằng chữ). Không có tab "Bảng chéo".

## Khóa i18n (chuẩn tắc; task 1.2 thêm tất cả vào `app_vi.arb` và `app_en.arb`, rồi `flutter gen-l10n`)

Tiền tố `swiss` (lowerCamelCase, đúng quy ước các khóa `bracketView_*`/`tournamentManagementBracket*` là hỗn hợp: dùng tiền tố mới nhất quán):
- Thể thức/vòng: `swissFormatName` (Thụy Sĩ / Swiss), `swissRoundLabel` ({number}: "Vòng {number}" / "Round {number}"), `swissBye` (BYE).
- Bảng: `swissStandingsRank, swissStandingsTeam, swissStandingsPlayed, swissStandingsWon, swissStandingsDrawn, swissStandingsLost, swissStandingsPoints, swissStandingsBuchholz, swissStandingsBuchholzCut1, swissStandingsSonnebornBerger, swissStandingsPointDiff, swissStandingsWins, swissStandingsEmpty`.
- Cấu hình: `swissConfigTotalRounds, swissConfigFirstRound, swissConfigFirstRoundSeed, swissConfigFirstRoundRandom, swissConfigTiebreakTitle, swissConfigMoveUp, swissConfigMoveDown, swissConfigRoundsRange` ({max}), `swissConfigRoundsMinPlayed` ({number}); tiebreak: `swissTiebreakBuchholz, swissTiebreakBuchholzCut1, swissTiebreakSonnebornBerger, swissTiebreakPointDiff, swissTiebreakWins, swissTiebreakHeadToHead, swissTiebreakSeed`.
- Ghép cặp: `swissPairingTitle` ({number}), `swissPairingProgress` ({number},{total},{pairs}), `swissPairingPool, swissPairingSitOut, swissPairingDropHere, swissPairingBoard` ({number}), `swissPairingAutoPair, swissPairingUndo, swissPairingConfirm` ({number}), `swissPairingConfirmWithWarnings, swissPairingSwapWith, swissPairingMoveTo, swissPairingCancel, swissPairingPoints` ({points}), `swissPairingLoading, swissPairingIncompleteHint` ({count}), `swissPairingCreated` ({number}), `swissPairingUndone` ({number}), `swissPairingDragHint` (nhãn Semantics).
- Cảnh báo/lỗi: `swissWarningRematch` ({round}), `swissWarningSecondBye`, `swissWarningScoreGap` ({gap}); `swissErrorDuplicateParticipant, swissErrorUnknownParticipant, swissErrorMissingParticipant, swissErrorSelfPairing`; `swissApiErrorRoundIncomplete, swissApiErrorAllRoundsDone, swissApiErrorRoundExists, swissApiErrorInvalidPairing, swissApiErrorWarningsUnconfirmed, swissApiErrorRoundStarted, swissApiErrorUndoRoundOne, swissApiErrorNotSwiss`.
- Hành động: `swissActionGenerateNextRound` ({number}), `swissActionUndoRound` ({number}), `swissActionRoundInProgress` ({number}), `swissActionAllRoundsDone` ({total}).
Ngoài ra thêm khóa tên thể thức Swiss vào MỌI bộ khóa đang có biến thể `GroupStageKnockout` mà màn đó hiển thị tên thể thức (`createClubTournament_bracketSwiss` + `...Description`, `tournamentManagementBracketSwiss`, `registerBracketSwiss`, `quickCreateBracketSwiss` + `Desc` chỉ nếu `bracketDisplayName` dùng).

## Phương án đã loại

- Tự tính Buchholz ở client: lệch Backend, thêm công việc.
- Thẻ (Card) cho từng bàn có avatar: vi phạm luật phẳng.
- Dùng `lib/data/api_service.dart`: file sinh, không được app import, bị ghi đè khi sinh lại.
- Nhét `roundConfig` vào `MatchModel`: làm phình mô hình dùng chung nhiều màn.

## Rủi ro

| Rủi ro | Chặn |
|---|---|
| Stage `SWISS` rơi vào nhánh knockout (`bracket_stage_utils.dart:20-87`, `match_round_label.dart:19-65,196-199`, `bracket_view_screen.dart:367-393`, `public_bracket_view.dart:38-54`) | Task 1.3, 3.2 thêm nhánh SWISS sớm kèm test |
| Không biết trận Swiss từ `/bracket` có `groupName` không (quyết định `isGroupStageMatch`) | Ưu tiên `stageType == 'SWISS'` trước mọi heuristic theo `groupName`/`stageName` |
| `flutter test` cần `.env` (worktree mới không có) | Xem `AGENTS.md`; không đọc/in `.env`; chạy test thuần không phụ thuộc `.env` nếu được |
| `test/core/utils/elo_tier_test.dart` đỏ 9/9 trên `main` | Không liên quan; không sửa |
| Thả sai chỗ rồi gọi API thật | Chỉ gọi API ở `confirm`; `validate` bật nút; Backend kiểm lại |

## Hợp đồng chung Backend ↔ Web ↔ App (nguồn: Backend; bản sao nguyên văn ở cả 3 repo, đổi một nơi phải đổi cả ba)

Tiền tố API: `/api/v1/tournaments`. Mọi phản hồi bọc `{ statusCode, message, data, meta }` như INSTRUCTIONS.md; bên dưới chỉ mô tả `data`. Định danh trường dùng đúng tên viết ở đây.

### 1. Giá trị và cấu hình
- `division.bracketType` / `tournamentConfig.bracketType` = `'SWISS'` (varchar, không migration). Stage: `stage.type = 'SWISS'`, MỘT stage MỘT group (tên group `Thụy Sĩ`). Mọi trận Swiss gắn `groupId` của group đó (sơ đồ công khai chỉ hiện trận có `groupId`).
- Cấu hình nằm ở `roundConfig.swiss` của division (trước khi sinh sơ đồ) và của stage (sau khi sinh; `PATCH /tournaments/stages/:stageId`):
  ```ts
  type SwissTiebreak = 'BUCHHOLZ' | 'BUCHHOLZ_CUT1' | 'SONNEBORN_BERGER' | 'POINT_DIFF' | 'WINS' | 'HEAD_TO_HEAD' | 'SEED';
  interface SwissConfig {
    totalRounds: number;                 // số nguyên 1..30; mặc định lúc sinh sơ đồ = max(1, ceil(log2(N))), N = số đội hợp lệ
    tiebreakOrder: SwissTiebreak[];      // không trùng; mặc định ['BUCHHOLZ','POINT_DIFF','HEAD_TO_HEAD','SEED']
    firstRoundPairing: 'SEED' | 'RANDOM'; // mặc định 'SEED'
  }
  ```
- Số đội hợp lệ tối thiểu để sinh sơ đồ Swiss: 4. `totalRounds` không được nhỏ hơn số vòng đã sinh (`max(roundNumber)` của stage) và không lớn hơn `max(1, N - 1)` khi sinh sơ đồ.
- Điểm thắng/hòa/thua: dùng `sportRules` sẵn có (`winPoints`/`drawPoints`/`lossPoints`, mặc định 3/1/0) như vòng tròn. BYE = `winPoints`.

### 2. Luật nghiệp vụ
- **Vòng hiện tại** = `max(roundNumber)` các trận chưa xóa của stage. **Vòng N xong** = mọi trận không-BYE của vòng N có `status = 'COMPLETED'`. **Được sinh vòng kế** = `currentRound >= 1` && `currentRound < totalRounds` && vòng hiện tại xong. Client tính cờ này từ danh sách trận bằng đúng quy tắc trên; Backend cưỡng chế lại.
- **Vòng 1**: sinh cùng lúc khóa/sinh sơ đồ (như các thể thức khác). `firstRoundPairing = 'SEED'`: sắp theo seed tăng (seed rỗng xếp cuối, rồi theo `participantId`), cặp (1, N/2+1), (2, N/2+2)...; `'RANDOM'`: xáo trộn. Số đội lẻ: người cuối bảng sắp thứ tự nhận BYE.
- **Vòng ≥ 2** (máy đề xuất, BTC chỉnh, xác nhận mới tạo trận): nhóm theo điểm giảm dần; trong nhóm chia nửa trên/nửa dưới (hạt giống cao gặp thấp); **không gặp lại đối thủ cũ** (quay lui; nếu không thể thì chọn phương án ít gặp lại nhất); người thừa trong nhóm xuống nhóm dưới; số lẻ thì BYE cho người điểm thấp nhất **chưa từng BYE** mà phần còn lại vẫn ghép được.
- **BYE**: trận có `isBye = true`, `participant1Id` = người nhận BYE, `participant2Id = null`, `status = 'COMPLETED'`, `winnerId = participant1Id`. Mỗi người tối đa 1 BYE (BYE lần 2 chỉ qua được khi BTC xác nhận cảnh báo). BYE tính `winPoints`, đóng góp 0 vào Buchholz của người khác.
- **Nghỉ vòng này** (`sitOutParticipantIds`): không có dòng trận, 0 điểm vòng đó, không tính là BYE, tham gia lại vòng sau.
- **Rút hẳn / loại**: dùng `teamStatus` sẵn có (`WITHDRAWN`, `KICKED`...). Đội không còn hợp lệ (`eligibleTeamCondition`) tự bị loại khỏi preview; kết quả cũ của họ vẫn nằm trong xếp hạng và Buchholz của đối thủ.
- **Vào muộn**: BTC thêm VĐV (luồng add-athletes sẵn có) trước khi sinh vòng kế; người mới 0 điểm, xuất hiện trong preview vòng kế và trong xếp hạng (dù chưa có trận).
- **Xếp hạng** (Backend là nguồn duy nhất; Web/App chỉ hiển thị): sắp theo `totalPoints` giảm dần, rồi lần lượt `tiebreakOrder`, rồi `participantId` tăng dần (khử hòa tuyệt đối). Định nghĩa:
  - `BUCHHOLZ` = tổng `totalPoints` hiện tại của các đối thủ thật đã gặp (BYE không tính, nghỉ vòng không tính).
  - `BUCHHOLZ_CUT1` = `BUCHHOLZ` trừ `totalPoints` thấp nhất trong các đối thủ đã gặp (0 đối thủ thì 0).
  - `SONNEBORN_BERGER` = tổng `totalPoints` đối thủ đã thắng + một nửa tổng `totalPoints` đối thủ đã hòa.
  - `POINT_DIFF` = `pointsFor - pointsAgainst` (cùng cách tính tổng điểm set như vòng tròn, `sumSetPoints`); BYE đóng góp 0.
  - `WINS` = số trận thắng (BYE tính 1).
  - `HEAD_TO_HEAD` = chỉ áp khi đúng 2 người còn hòa sau các tiêu chí trước và đã gặp nhau: người thắng trận đó xếp trên; ngoài ra bỏ qua.
  - `SEED` = `seed` tăng dần, seed rỗng xếp cuối.
- **Podium** khi đã đủ `totalRounds` vòng và mọi trận xong: top 3 theo xếp hạng trên. Chưa đủ thì không có podium.

### 3. Endpoint (quyền: `@Roles(...TOURNAMENT_MANAGER_ROLES)` + `@Verified()` + `TournamentAccessService.isManager`)
Khối chung (draft):
```ts
interface SwissRoundDraft {
  divisionId: string;                       // bắt buộc với giải nhiều nội dung
  stageId?: string;                         // bỏ trống = stage SWISS đang hoạt động của nội dung
  pairs: { participant1Id: string; participant2Id: string }[];
  byeParticipantId?: string | null;
  sitOutParticipantIds?: string[];
}
type SwissWarning = { type: 'REMATCH' | 'SECOND_BYE' | 'SCORE_GAP'; participantIds: string[]; round?: number; gap?: number };
type SwissError = { code: 'DUPLICATE_PARTICIPANT' | 'UNKNOWN_PARTICIPANT' | 'MISSING_PARTICIPANT' | 'SELF_PAIRING'; participantIds: string[] };
```
- `SCORE_GAP` khi hai người trong một cặp chênh điểm hơn `winPoints`; `REMATCH.round` = vòng đã gặp trước đó; `SECOND_BYE` khi người nhận BYE đã từng BYE.
- Quy tắc hợp lệ: mọi đội hợp lệ xuất hiện đúng MỘT lần trong `pairs` ∪ `byeParticipantId` ∪ `sitOutParticipantIds`; không đội lạ; không tự ghép với chính mình.

1. `POST /:id/swiss/preview` body `{ divisionId, stageId? }` → 200
   ```ts
   {
     roundNumber: number; totalRounds: number;
     pairs: { board: number; participant1Id: string; participant2Id: string }[];
     byeParticipantId: string | null;
     sitOutParticipantIds: string[];          // luôn [] khi máy đề xuất
     participants: { id: string; teamName: string; logoUrl: string | null; seed: number | null; totalPoints: number; buchholz: number; hadBye: boolean }[];
     warnings: SwissWarning[];                // cảnh báo của chính bản đề xuất (thường rỗng)
   }
   ```
   Không ghi DB. Lỗi: 400 `SWISS_NOT_SWISS`, 409 `SWISS_ROUND_INCOMPLETE`, 409 `SWISS_ALL_ROUNDS_DONE`.
2. `POST /:id/swiss/validate` body = `SwissRoundDraft` → 200 `{ valid: boolean; errors: SwissError[]; warnings: SwissWarning[] }` (luôn 200, `valid=false` khi có `errors`). Không ghi DB. Web/App gọi (debounce 250 ms) sau mỗi lần BTC chỉnh.
3. `POST /:id/swiss/next-round` body `SwissRoundDraft & { confirmWarnings?: boolean }` → 201 `{ roundNumber: number; matchIds: string[] }`. Trong MỘT transaction: khóa hàng giải `FOR UPDATE`, kiểm lại mọi điều kiện, tạo trận (`roundNumber`, `matchOrder` nối tiếp toàn cục, `bracketBranch='MAIN'`, `status='SCHEDULED'`, trận BYE theo luật trên), xóa cache, phát `bracket:update`. Lỗi:
   - 400 `SWISS_INVALID_PAIRING` (`details.errors: SwissError[]`);
   - 409 `SWISS_WARNINGS_UNCONFIRMED` (`warnings: SwissWarning[]` kèm trong body) khi có cảnh báo mà `confirmWarnings` không phải `true`;
   - 409 `SWISS_ROUND_INCOMPLETE`, 409 `SWISS_ALL_ROUNDS_DONE`, 409 `SWISS_ROUND_EXISTS` (vòng này vừa được người khác tạo; client tải lại preview).
4. `POST /:id/swiss/rounds/:round/undo` body `{ divisionId, stageId? }` → 200 `{ roundNumber: number }`. Chỉ vòng **mới nhất** và vòng ≥ 2; xóa mềm mọi trận của vòng đó. Lỗi: 400 `SWISS_UNDO_ROUND_ONE`, 409 `SWISS_ROUND_STARTED` (có trận không-BYE đã bắt đầu/kết thúc, theo `hasStartedMatchInTx`).
5. Đọc (đã có, mở rộng): `GET /:id/bracket?divisionId=` trả stage `type:'SWISS'` kèm `roundConfig.swiss`; `GET /:id/standings?divisionId=` với stage SWISS trả mỗi dòng thêm `rank: number`, `buchholz: number`, `buchholzCut1: number`, `sonnebornBerger: number` (các trường cũ giữ nguyên: `participantId, teamName, logoUrl, seed, players, played, won, lost, draws, pointsFor, pointsAgainst, totalPoints, groupId`), đã sắp theo `rank` tăng dần. Đủ mọi đội hợp lệ (kể cả chưa có trận) và mọi đội đã có trận.
6. Cấu hình: `PATCH /stages/:stageId` (đường dẫn đầy đủ `PATCH /api/v1/tournaments/stages/:stageId`, KHÔNG có `:id` giải) với `{ roundConfig: { swiss: Partial<SwissConfig> } }` (sai kiểu/giá trị → 400 theo validator hiện có) và đường cấu hình division hiện có.

### 4. Realtime
Sự kiện socket `bracket:update` (namespace `/live`, phòng `tournament:{id}`), payload `{ tournamentId: string; divisionId: string | null; stageId: string | null; action: 'SWISS_ROUND_CREATED' | 'SWISS_ROUND_UNDONE' | 'BRACKET_SLOTS_UPDATED'; roundNumber: number | null; occurredAt: string }`. Web tải lại bracket/standings khi nhận; App đã poll 15–20 giây nên không bắt buộc nghe socket.

### 5. Nhãn hiển thị (client)
Vòng Swiss hiển thị `Vòng {roundNumber}` / `Round {roundNumber}`; trận BYE hiển thị tên người nhận + nhãn `BYE`; tên thể thức `Thụy Sĩ` / `Swiss`. Tiêu đề cột Buchholz: `Buchholz`.
