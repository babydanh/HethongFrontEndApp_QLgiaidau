# Proposal

## Why

Tab "Bảng đấu" của trang chi tiết giải đôi khi hiện sơ đồ cho nội dung chưa bốc thăm. Khi `GET /tournaments/:id/bracket?divisionId=X` rỗng, `bracketMatchesWithDivisionProvider` dự phòng sang `GET /matches?tournamentId&divisionId=X&publicOnly=true`. Nội dung X chưa có stage thì Backend trả **toàn bộ trận của giải** (`matches.repository.ts` nhánh `hasTournamentScope`), App vẽ chúng thành bracket ảo. Đo production 2026-10-19: 33 nội dung chưa bốc thăm trên 48 giải công khai trả trận của nội dung khác (VNDC T4 "Đôi linh hoạt": 15 trận, VPSF "Đôi Nam": 100 trận).

## What Changes

- Mọi lần App tải trận công khai theo nội dung (`ApiMatchRepository._fetchAllByTournament` có `divisionId`) gửi thêm `strictDivisionScope=true`, giống Web (`load-manage-matches.ts`). Backend khi đó trả rỗng nếu giải đã gán stage cho nội dung khác; giải bracket cũ chưa gán nội dung vẫn giữ trận của giải.

## Capabilities

### New Capabilities

- `public-division-bracket`: sơ đồ bảng đấu theo nội dung ở trang chi tiết giải.

### Modified Capabilities

(không có)

## Out of scope

- Không đổi Backend (cờ `strictDivisionScope` đã có).
- Không đổi Web: trang công khai Web vẽ sơ đồ từ `/bracket`.
- Không đổi cách tải trận không theo nội dung (`divisionId` null, snapshot công khai).

## Impact

- App: `lib/data/repositories/api/api_match_repository.dart`, test `test/data/api_match_repository_division_scope_test.dart`.
- API dùng: `GET /api/v1/matches` thêm query `strictDivisionScope=true` khi có `divisionId`.
