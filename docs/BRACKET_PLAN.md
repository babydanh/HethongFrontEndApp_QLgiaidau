# Kế hoạch Hệ thống Bracket (BRACKET_PLAN.md)

> Tài liệu này mô tả chi tiết logic sinh Bracket, các hình thức thi đấu, và các edge case cần xử lý.

---

## 1. Các hình thức Bracket được hỗ trợ

| Format | Giá trị DB | Mô tả | Số VĐV tối thiểu |
|---|---|---|:---:|
| Single Elimination | `SINGLE_ELIMINATION` | Thua là out | 4 |
| Double Elimination | `DOUBLE_ELIMINATION` | Thua 2 lần mới out | 4 |
| Round Robin | `ROUND_ROBIN` | Đấu vòng tròn, tính điểm | 3 |
| Round Robin → Elimination | `ROUND_ROBIN_TO_ELIMINATION` | Vòng loại bảng → loại trực tiếp | 4 |

---

## 2. Single Elimination

### 2.1 Quy tắc sinh bracket

- Số slot = `2^n` ≥ số VĐV (n là số nguyên nhỏ nhất thỏa mãn)
- Slot thừa → BYE (thắng tự động)
- Seeding mặc định: Random (có thể BTC điều chỉnh thủ công ở giai đoạn UPCOMING)

**Ví dụ: 6 VĐV → bracket 8:**
```
Vòng 1 (Quarter):
  Match 1: Seed 1  vs BYE    → Seed 1 thắng (BYE auto)
  Match 2: Seed 4  vs Seed 5
  Match 3: Seed 3  vs Seed 6
  Match 4: Seed 2  vs BYE    → Seed 2 thắng (BYE auto)

Vòng 2 (Semi):
  Match 5: Winner M1 vs Winner M2
  Match 6: Winner M3 vs Winner M4

Vòng 3 (Final):
  Match 7: Winner M5 vs Winner M6
```

### 2.2 Fields liên quan trong DB

```
matches:
  roundNumber      → Vòng (1 = Vòng đầu, tăng dần đến Final)
  matchOrder       → Thứ tự trong vòng (1, 2, 3...)
  nextMatchId      → FK đến match ở vòng sau (người thắng đi)
  isBye            → true nếu là BYE slot
  bracketBranch    → 'MAIN' (chỉ dùng cho Double Elimination)
  winnerId         → Được set khi match COMPLETED
```

### 2.3 Tự động điền người thắng vào vòng sau

```typescript
// Khi match COMPLETED:
if (match.nextMatchId) {
  const nextMatch = findMatch(match.nextMatchId);
  // Điền winner vào slot trống (participant1 hoặc participant2)
  if (!nextMatch.participant1Id) nextMatch.participant1Id = match.winnerId;
  else nextMatch.participant2Id = match.winnerId;
}
```

---

## 3. Double Elimination

### 3.1 Cấu trúc 2 nhánh

```
Winners Bracket (bracketBranch = 'MAIN'):
  Vòng W1 → Vòng W2 → ... → Winners Final

Losers Bracket (bracketBranch = 'LOSERS'):
  Người thua Winners W1 → Losers R1
  Người thua Winners W2 → Losers R2 (dropzone)
  ... → Losers Final

Grand Final:
  Winner của Winners Final vs Winner của Losers Final
```

### 3.2 Fields thêm cho Double Elimination

```
matches.loserNextMatchId → FK đến match ở Losers Bracket (nhánh thua)
```

```typescript
// Khi match COMPLETED trong Winners Bracket:
// - Người thắng → match.nextMatchId (Winners Bracket tiếp)
// - Người thua  → match.loserNextMatchId (Losers Bracket)

// Khi match COMPLETED trong Losers Bracket:
// - Người thắng → match.nextMatchId (Losers tiếp)
// - Người thua  → bị loại hoàn toàn (không có loserNextMatchId)
```

### 3.3 Grand Final Logic

```
[Case A] Winners Final Winner thắng Grand Final:
  → Kết thúc. Champion = Winner.

[Case B] Losers Final Winner thắng Grand Final (lần 1):
  → Phải đấu thêm Grand Final lần 2 (vì Winners Final Winner chưa thua lần nào)
  → Tạo thêm match "Grand Final Reset" nếu Losers winner thắng GF lần 1

[Case C] Số VĐV lẻ (ví dụ: 5, 6, 7):
  → Cần BYE trong Losers Bracket để cân bằng
  → Ai nhận BYE trong Losers: người có seed thấp nhất (seed = người thua sớm nhất)
```

### 3.4 ⚠️ Known Edge Cases cần test

| Case | Mô tả | Trạng thái |
|---|---|:---:|
| 5 VĐV | Losers Round 1 có 1 match BYE | Chưa test |
| 6 VĐV | Losers phân bổ không đều | Chưa test |
| 7 VĐV | Losers R2 cần thêm BYE | Chưa test |
| Grand Final Reset | Losers winner thắng GF lần 1 | Chưa implement |
| 3 VĐV | Không đủ cho Double Elim chuẩn | ❌ Không nên cho phép |

> **Tạm thời:** Với đồ án, chỉ cần test Double Elimination với 4, 8, 16 VĐV (số 2^n). Các số lẻ có thể disable hoặc fallback về Single Elimination.

---

## 4. Round Robin

### 4.1 Sinh lịch thi đấu

Dùng **thuật toán xoay vòng (Round Robin Scheduling)**:

```typescript
// Với n VĐV:
// - n chẵn: n-1 vòng, mỗi vòng n/2 trận
// - n lẻ: n vòng, mỗi vòng (n-1)/2 trận (1 người nghỉ)

// Ví dụ 4 VĐV: A, B, C, D
// Vòng 1: A vs D, B vs C
// Vòng 2: A vs C, D vs B
// Vòng 3: A vs B, C vs D
```

### 4.2 Tính điểm bảng xếp hạng

```
Thắng: +3 điểm (totalPoints)
Hòa:   +1 điểm (draws)
Thua:  +0 điểm

Tie-breaker theo thứ tự:
  1. totalPoints (nhiều hơn thắng)
  2. pointsFor - pointsAgainst (hiệu số điểm set/game)
  3. Head-to-head (đối đầu trực tiếp)
```

### 4.3 Fields trong DB

```
group_standings:
  played, won, lost, draws
  pointsFor, pointsAgainst
  totalPoints
  updatedAt  → cập nhật sau mỗi match COMPLETED
```

---

## 5. Round Robin → Elimination

### 5.1 Cấu trúc

```
Giai đoạn 1: Round Robin (vòng bảng)
  ├── Chia VĐV thành N bảng (groups)
  ├── Mỗi bảng đấu vòng tròn nội bộ
  └── Top K từ mỗi bảng đi tiếp

Giai đoạn 2: Single/Double Elimination (vòng chính)
  └── Ghép kết quả từ các bảng → bracket
```

**Ví dụ: 16 VĐV, 4 bảng (A/B/C/D), top 2 đi tiếp:**
```
Bảng A (4 người) → 1A, 2A
Bảng B (4 người) → 1B, 2B
Bảng C (4 người) → 1C, 2C
Bảng D (4 người) → 1D, 2D

Quarter Final:
  1A vs 2C | 1C vs 2A
  1B vs 2D | 1D vs 2B
```

### 5.2 Fields trong DB

```
tournament_groups:
  name       → "Bảng A", "Bảng B"...
  stageId    → FK → tournament_stages (giai đoạn Round Robin hay Elimination)
  type       → 'ROUND_ROBIN' hoặc 'ELIMINATION'
```

---

## 6. Seed VĐV & Thứ tự xếp hạng

### 6.1 Seeding tự động khi tạo Bracket

```typescript
// Theo thứ tự ưu tiên:
1. Seed thủ công do BTC set (nếu có)
2. ELO cao → seed thấp (seed 1 = mạnh nhất)
3. Nếu không có ELO → random
```

### 6.2 BTC chỉnh seed thủ công (UPCOMING stage)

```
Tab Bracket → Drag & Drop thứ tự VĐV
  → Seed mới được lưu vào tournament_participants.seed
  → Bracket được tính lại preview (chưa chốt)
  → Nhấn [Generate chính thức] → locked
```

---

## 7. Trạng thái Match

| Status | Mô tả |
|---|---|
| `SCHEDULED` | Đã xếp lịch, chưa bắt đầu |
| `ONGOING` | Đang thi đấu |
| `COMPLETED` | Đã có kết quả |
| `DISPUTED` | Kết quả đang bị kháng cáo *(hiện không implement)* |

**Transition:**
```
SCHEDULED → ONGOING  : Khi trọng tài bắt đầu nhập điểm
ONGOING   → COMPLETED: Khi trọng tài xác nhận kết quả
```

---

## 8. BYE Slot

- BYE = slot ảo không có VĐV thật
- Match có BYE → VĐV còn lại thắng auto (`isBye = true`)
- `p1SetsWon = setsToWin`, `p2SetsWon = 0` (hoặc ngược lại tùy vị trí BYE)
- Không gửi notification, không tính điểm ELO
- BTC không cần xếp lịch cho match BYE

---

## 9. Auto-advance Logic (khi Match COMPLETED)

```typescript
async onMatchCompleted(matchId: string) {
  const match = await getMatch(matchId);

  // 1. Set winnerId
  match.winnerId = calculateWinner(match);

  // 2. Điền winner vào match kế tiếp
  if (match.nextMatchId) {
    await advanceParticipant(match.winnerId, match.nextMatchId);
  }

  // 3. Điền loser vào Losers Bracket (Double Elim)
  if (match.loserNextMatchId && match.bracketBranch === 'MAIN') {
    const loserId = match.participant1Id === match.winnerId
      ? match.participant2Id
      : match.participant1Id;
    await advanceParticipant(loserId, match.loserNextMatchId);
  }

  // 4. Kiểm tra tất cả match đã COMPLETED?
  const allDone = await checkAllMatchesCompleted(match.tournamentId);
  if (allDone) {
    await setTournamentStatus(match.tournamentId, 'COMPLETED');
    // Trigger ELO update nếu isRanked
  }

  // 5. Cập nhật group_standings (Round Robin)
  if (match.group?.type === 'ROUND_ROBIN') {
    await updateGroupStandings(match);
  }

  // 6. Gửi notification kết quả cho 2 VĐV
  await sendMatchResultNotification(match);
}
```

---

## 10. Trạng thái còn thiếu cần implement

| # | Việc cần làm | File cần sửa |
|---|---|---|
| 1 | `onMatchCompleted` tự động advance participant | `matches.service.ts` hoặc `bracket-generator.service.ts` |
| 2 | Tự động set tournament `COMPLETED` khi all matches done | `matches.service.ts` |
| 3 | Grand Final Reset cho Double Elimination | `bracket-generator.service.ts` |
| 4 | BYE auto-advance ngay khi bracket được tạo | `bracket-generator.service.ts` |
| 5 | Seeding drag & drop ở frontend (UPCOMING stage) | `manage/page.tsx` — Tab Bracket |
| 6 | Round Robin standings update sau mỗi match | `matches.service.ts` |
| 7 | Validate số VĐV hợp lệ cho từng format | `tournaments.service.ts` — hàm `lock()` |
