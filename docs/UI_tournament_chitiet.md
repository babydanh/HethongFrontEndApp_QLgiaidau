# 🏗 Plan Thiết Kế Trang Chi Tiết Giải Đấu (Tournament Intro/Detail)

> **Tài liệu:** UI Tournament Detail Redesign  
> **Phiên bản:** 2.0 — Cập nhật theo yêu cầu mới  
> **Ngày:** 30/06/2026  
> **Dựa trên:** `flutter-ui-design-spec.md`, `CURRENT_STATUS.md`, frontend web register flow

---

## 🎯 Mục Tiêu

Thiết kế màn hình **Tournament Detail (Chi tiết giải đấu)** duy nhất — dùng chung cho **Viewer/Player/Admin** — với:

1. **Banner đẹp** — rõ thông tin, chuyển ảnh được nếu giải có nhiều banner
2. **Thông tin giải** — tên, ngày thi đấu, tình trạng (đang mở/đã đóng), hiển thị ngay dưới banner
3. **4 Tab** — Thông tin giải → Đội tham gia → Bảng đấu → Đăng ký
4. **Form đăng ký** chi tiết giống frontend web: chọn hình thức (division), kiểm tra ELO, thông tin ngân hàng hoàn tiền

---

## 🟥 Phân Tách Rõ: 2 Màn Hình Riêng Biệt

### A. TournamentIntroScreen (dành cho AI người chơi / khán giả) — Tab 1-4

Đây là màn hình **xem thông tin giải và đăng ký**:

| Layout | Mô tả |
|--------|-------|
| **Banner** | Ảnh/ gradient, chuyển ảnh nếu có nhiều, nút back |
| **Dưới banner** | Tên giải, ngày thi đấu, trạng thái (Đang mở/Đã đóng/Sắp diễn ra) |
| **4 Tab** | Thông tin / Đội tham gia / Bảng đấu / Đăng ký |
| **Bottom bar** | Nút Vào giải / Đăng ký ngay / Live |

### B. TournamentDetailScreen (dành cho Admin/Organizer) — Giữ nguyên layout quản lý

Đây là màn hình **quản lý giải đấu** — chỉ Admin mới thấy:

| Layout | Mô tả |
|--------|-------|
| **Banner** | Giống IntroScreen |
| **Dưới banner** | Stats row (tổng đội, trận, xong, live) |
| **4 Tab** | Quản lý (action grid) / Đội tham gia / Bracket / Kết quả |
| **Action Grid** | Mã Token, Quản lý đội, Bốc thăm, Bracket, Export, Kết thúc |

---

## 🎨 Layout Chi Tiết: TournamentIntroScreen (Mobile)

```
┌──────────────────────────────────────┐
│  🔙                        🔴 12     │ ← Viewer badge (nếu có)
├──────────────────────────────────────┤
│  ┌─── BANNER ──────────────────────┐ │
│  │  ┌──────────────────────────┐   │ │
│  │  │  Hình ảnh giải đấu       │   │ │ ← Có thể vuốt chuyển (PageView)
│  │  │  (ảnh nền / gradient)     │   │ │    nếu có nhiều banner
│  │  └──────────────────────────┘   │ │
│  │     ● ● ○ ○ (dots)             │ │ ← Indicator dots
│  │                                 │ │
│  │  [🏸 Cầu lông]   [ĐANG MỞ]    │ │ ← Sport pill + Status pill
│  │  GIẢI CẦU LÔNG VNDC            │ │ ← Tên giải 24px bold white
│  │  MỞ RỘNG 2026                  │ │
│  └──────────────────────────────────┘ │
│                                       │
│  ┌─── INFO STRIP ───────────────────┐ │
│  │  📅 15/06/2026         🔥 Đang  │ │ ← Ngày thi đấu + Status
│  │  📍 Nhà thi đấu Phú Thọ         │ │
│  │  💰 300.000đ                     │ │ ← Phí tham gia
│  │  👥 Đang đăng ký: 12/16 đội     │ │ ← Progress
│  └──────────────────────────────────┘ │
│                                       │
│  ┌─── TAB BAR ──────────────────────┐ │
│  │  📋    │  👥   │  🏆  │  📝    │ │
│  │ Thông  │  Đội  │ Bảng │ Đăng   │ │
│  │ tin    │tham gia│ đấu  │ ký     │ │
│  └───────────────────────────────────┘ │
│                                        │
│  ┌─── TAB 1: THÔNG TIN ─────────────┐ │
│  │  ┌─── Thông tin chung ─────────┐ │ │
│  │  │  Thể thức: Đánh đôi         │ │ │
│  │  │  Nhánh đấu: Loại trực tiếp  │ │ │
│  │  │  Hạng mục: Đôi nam          │ │ │
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  ┌─── Về giải đấu ────────────┐ │ │
│  │  │  (mô tả giải đấu)          │ │ │
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  ┌─── Giải thưởng ────────────┐ │ │
│  │  │  🥇 Vô địch: 10.000.000đ  │ │ │
│  │  │  🥈 Á quân: 5.000.000đ    │ │ │
│  │  │  🥉 Hạng 3: 2.000.000đ    │ │ │
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  ┌─── Ban tổ chức ────────────┐ │ │
│  │  │  👤 BTC                     │ │ │
│  │  │  📞 0909.xxx.xxx           │ │ │
│  │  └────────────────────────────┘ │ │
│  └──────────────────────────────────┘ │
│                                        │
│  ┌─── TAB 2: ĐỘI THAM GIA ──────────┐ │
│  │  ┌─── HÌNH THỨC (tabs phụ) ───┐ │ │
│  │  │ [Đơn nam] [Đôi nam] [Đôi Nữ]│ │ │ ← Nếu nhiều division
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  ┌─── GRID TEAM CARDS ────────┐ │ │
│  │  │  ┌────┐ ┌────┐ ┌────┐     │ │ │
│  │  │  │Team│ │Team│ │Team│     │ │ │
│  │  │  │  A │ │  B │ │  C │     │ │ │
│  │  │  └────┘ └────┘ └────┘     │ │ │
│  │  │  ┌────┐ ┌────┐            │ │ │
│  │  │  │Team│ │Team│            │ │ │
│  │  │  │  D │ │  E │            │ │ │
│  │  │  └────┘ └────┘            │ │ │
│  │  └────────────────────────────┘ │ │
│  │  (Ấn vào → BottomSheet/xem      │ │
│  │   trang cá nhân đội đó)          │ │
│  └──────────────────────────────────┘ │
│                                        │
│  ┌─── TAB 3: BẢNG ĐẤU ─────────────┐ │
│  │  ┌─── CHỌN HÌNH THỨC ─────────┐ │ │
│  │  │  [Đơn nam ▼]               │ │ │ ← Dropdown chọn division
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  ┌─── LỊCH THI ĐẤU ───────────┐ │ │
│  │  │  Vòng 1:                    │ │ │
│  │  │  Team A vs Team B - 08:00  │ │ │
│  │  │  Team C vs Team D - 09:00  │ │ │
│  │  │  ...                        │ │ │
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  ┌─── BRACKET ────────────────┐ │ │
│  │  │  (InteractiveViewer +       │ │ │
│  │  │   graphview bracket tree)   │ │ │
│  │  └────────────────────────────┘ │ │
│  └──────────────────────────────────┘ │
│                                        │
│  ┌─── TAB 4: ĐĂNG KÝ ───────────────┐ │
│  │  ┌─── KIỂM TRA ĐĂNG NHẬP ──────┐ │ │
│  │  │  Nếu chưa ĐN → "Đăng nhập"  │ │ │
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  ┌─── CHỌN HÌNH THỨC ─────────┐ │ │
│  │  │  [Đơn nam] [Đôi nam] [Đôi Nữ]│ │ │ ← Card animation
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  ┌─── FORM ĐĂNG KÝ ────────────┐ │ │
│  │  │  Tên đội / Tên thi đấu:     │ │ │
│  │  │  [____________________]     │ │ │
│  │  │                              │ │ │
│  │  │  Kiểm tra ELO: ✅ Phù hợp   │ │ │ ← Tự động check
│  │  │                              │ │ │
│  │  │  Phí tham gia: 300.000đ     │ │ │
│  │  │  Trạng thái: Còn 4/16 chỗ   │ │ │
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  ┌─── NẾU LÀ ĐÔI ──────────────┐ │ │
│  │  │  👥 Tìm đồng đội             │ │ │
│  │  │  [Tìm kiếm người chơi...]   │ │ │ │
│  │  │  hoặc "Mời sau"             │ │ │
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  ┌─── NẾU ĐÃ ĐĂNG KÝ ─────────┐ │ │
│  │  │  ✅ Bạn đã đăng ký          │ │ │
│  │  │  Trạng thái: Đang chờ duyệt │ │ │
│  │  │  [Hủy đăng ký] [Thanh toán] │ │ │
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  ┌─── NẾU CẦN THANH TOÁN ─────┐ │ │
│  │  │  Chọn cổng thanh toán:      │ │ │
│  │  │  [VNPAY] [MoMo] [CK]       │ │ │
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  ┌─── THÔNG TIN HOÀN TIỀN ────┐ │ │
│  │  │  Nếu rút giải → nhập:       │ │ │
│  │  │  Tên NH: [__________]       │ │ │
│  │  │  Số TK:  [__________]       │ │ │
│  │  │  Chủ TK: [__________]       │ │ │
│  │  └────────────────────────────┘ │ │
│  │                                  │ │
│  │  [✅ ĐĂNG KÝ NGAY]              │ │ ← Button chính
│  └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

---

## 🎨 Layout: TournamentIntroScreen (Tablet)

```
┌───────────────────────────────────────────────────┐
│  🔙                                        🔴 12  │
├───────────────────────────────────────────────────┤
│  ┌──── BANNER (toàn ngang) ────────────────────┐ │
│  │  [🏸] [ĐANG MỞ]  GIẢI CẦU LÔNG VNDC       │ │
│  │  📅 15/06  📍 TP.HCM  💰 300K  👥 12/16  │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│  ┌────────────────┬───────────────────────────────┐ │
│  │  ┌─── SIDEBAR ─┤  ┌─── CONTENT ─────────────┐ │ │
│  │  │ 📋 Thông tin│  │                          │ │ │
│  │  │ 👥 Đội TG   │  │  (Nội dung tab được chọn)│ │ │
│  │  │ 🏆 Bảng đấu │  │                          │ │ │
│  │  │ 📝 Đăng ký  │  └──────────────────────────┘ │ │
│  │  └─────────────┘                               │ │
│  └────────────────┴───────────────────────────────┘ │
└───────────────────────────────────────────────────┘
```

---

## 🎨 Layout: TournamentDetailScreen (Admin) — Mobile

```
┌──────────────────────────────────────┐
│  🔙  Tên giải              ⋮        │ ← AppBar + menu delete
├──────────────────────────────────────┤
│  ┌─── BANNER (dùng chung) ─────────┐ │
│  │  (giống IntroScreen)            │ │
│  └──────────────────────────────────┘ │
│                                       │
│  ┌─── STATS ROW ────────────────────┐ │
│  │  👥 12 Đội  │ ⚔️ 24 Trận       │ │
│  │  ✅ 18 Xong  │ 🔴 3 Live        │ │
│  └──────────────────────────────────┘ │
│                                       │
│  ┌─── TAB BAR ───────────────────────┐ │
│  │  Quản lý │ Đội │ Bracket │ Kết quả│ │
│  └────────────────────────────────────┘ │
│                                         │
│  ┌─── TAB: QUẢN LÝ ───────────────────┐ │
│  │  ┌─── Thông tin giải ────────────┐ │ │ ← TournamentInfoGrid
│  │  │  Thể thức, Nhánh, Hạng mục   │ │ │    (dùng chung)
│  │  └───────────────────────────────┘ │ │
│  │                                     │ │
│  │  ┌─── ACTION GRID (2 cột) ───────┐ │ │
│  │  │ 🔴 Mã Token   │ 👥 Quản lý đội│ │ │
│  │  │ 🎲 Bốc thăm   │ 🌳 Bracket    │ │ │
│  │  │ ⬇ Export      │ ✅ Kết thúc   │ │ │
│  │  └───────────────────────────────┘ │ │
│  └─────────────────────────────────────┘ │
└───────────────────────────────────────────┘
```

---

## 🔄 Điểm Khác Biệt Giữa 2 Màn Hình

| Yếu tố | IntroScreen (Public) | DetailScreen (Admin) |
|--------|---------------------|---------------------|
| **Banner** | Chung | Chung |
| **Dưới banner** | Info strip (ngày, địa điểm, phí, slot) | Stats row (tổng đội, trận, xong, live) |
| **Tab 1** | Thông tin giải (mô tả + giải thưởng) | Quản lý (action grid) |
| **Tab 2** | Đội tham gia (xem) | Đội tham gia (quản lý) |
| **Tab 3** | Bảng đấu (lịch + bracket) | Bracket (xem/quản lý) |
| **Tab 4** | Đăng ký (form + thanh toán) | Kết quả (bảng xếp hạng) |
| **Bottom** | Sticky bar (Vào/Live/Đăng ký) | AppBar menu |
| **Ai thấy?** | Mọi người (không cần đăng nhập vẫn xem được thông tin) | Chỉ Admin/Organizer |

---

## 📋 Chi Tiết Từng Tab

### TAB 1: Thông tin giải (TournamentIntroScreen)

```
┌─── THÔNG TIN CHUNG ────────────────┐
│  ┌─── 2×2 GRID ──────────────────┐ │
│  │  🔀 Thể thức   │ 🏆 Nhánh    │ │
│  │  Đánh đôi      │ Loại trực tiếp│ │
│  │  ──────────────┼──────────────│ │
│  │  👥 Số đội     │ 👤 VĐV/đội  │ │
│  │  12/16         │ 2 người     │ │
│  └────────────────┴──────────────┘ │
└────────────────────────────────────┘

┌─── VỀ GIẢI ĐẤU ────────────────────┐
│  (Mô tả giải đấu từ tournament.description)
│  Ấn "Xem thêm" nếu dài > 3 dòng    │
└────────────────────────────────────┘

┌─── GIẢI THƯỞNG ────────────────────┐
│  🥇  Vô địch     10.000.000đ      │
│  🥈  Á quân       5.000.000đ      │
│  🥉  Hạng 3       2.000.000đ      │
│  (nếu có)                           │
│  Hoặc: "BTC chưa cập nhật"         │
└────────────────────────────────────┘

┌─── BAN TỔ CHỨC ────────────────────┐
│  👤 Avatar + Tên BTC               │
│  📞 0909.xxx.xxx                   │
│  ✉️  email@example.com             │
└────────────────────────────────────┘

┌─── LUẬT THI ĐẤU ───────────────────┐
│  ℹ️ Mô tả thể thức loại trực tiếp   │
│  Số trận: N-1  •  Bye nếu cần      │
└────────────────────────────────────┘
```

**Files:**
- `TournamentInfoGrid` (2×2 grid — đã có)
- `TournamentInfoCard` (mới — phí + địa điểm + timeline)
- `TournamentOrganizerCard` (mới — BTC contact)
- `TournamentSlotsProgress` (mới — progress bar)
- `TournamentPrizesView` (mới — podium)
- `TournamentDescriptionCard` (mới — mô tả + "xem thêm")

---

### TAB 2: Đội tham gia — FILTER THEO HÌNH THỨC (Division)

**Data flow:**
```
1. TournamentIntroScreen mount
   ↓
2. Gọi GET /tournaments/:id/divisions → lấy danh sách hình thức
   ↓
3. Nếu có nhiều division → show Segment tabs để lọc
   Mỗi division có: id, name, matchType, genderRestriction, entryFee, _count.participants
   ↓
4. Mặc định chọn division đầu tiên
   ↓
5. Gọi GET /tournaments/:id/divisions/:divisionId/participants
   → List participants của hình thức đó
   ↓
6. Hiển thị Grid team cards
```

```
┌─── HÌNH THỨC (Segment Tabs) ────────┐
│  [Đơn nam] [Đôi nam] [Đôi nữ]      │ ← Lấy từ API divisions
│  (mặc định chọn cái đầu, có badge   │
│   số lượng đội: 8/16 | 4/16 | 2/16)│
└────────────────────────────────────┘

┌─── GRID TEAM CARDS (maxCrossAxisExtent) ─┐
│  ┌──────────┐ ┌──────────┐              │
│  │  🧑      │ │  👥      │              │
│  │  Team A  │ │  Team B  │              │
│  │  2 VĐV   │ │  2 VĐV   │              │
│  │  ● Check-│ │  ○ Chưa  │              │
│  │    in    │ │  check-in│              │
│  └──────────┘ └──────────┘              │
│  ┌──────────┐ ┌──────────┐              │
│  │  ...     │ │  ...     │              │
│  └──────────┘ └──────────┘              │
└──────────────────────────────────────────┘

(Ấn Team Card → BottomSheet hiển thị roster team đó
 → có thể navigate đến trang cá nhân người chơi 
 → GET /users/:userId để xem profile + ELO)
```

#### Provider cần tạo

```dart
// Lấy danh sách division của giải
final divisionsProvider = FutureProvider.family<List<Division>, String>((ref, tournamentId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getDivisions(tournamentId);
});

// Lấy participants của 1 division cụ thể
final divisionParticipantsProvider = FutureProvider.family<List<Team>, ({String tournamentId, String divisionId})>(
  (ref, params) async {
    final repo = ref.watch(tournamentRepositoryProvider);
    return repo.getDivisionParticipants(params.tournamentId, params.divisionId);
  },
);

// Teams hiện tại — filter theo division
final teamsByDivisionProvider = Provider.family<List<Team>, ({String tournamentId, String? divisionId})>(
  (ref, params) {
    final teamsAsync = ref.watch(teamsProvider(params.tournamentId));
    final teams = teamsAsync.asData?.value ?? [];
    if (params.divisionId == null) return teams;
    return teams.where((t) => t.divisionId == params.divisionId).toList();
  },
);
```

**States:**
- **Loading divisions:** Shimmer segment
- **Error divisions:** ErrorView
- **Empty divisions (single format):** Ẩn segment, hiển thị teams thẳng
- **Loading participants:** Shimmer grid
- **Empty teams:** `TeamsEmptyView` với division name
- **Data:** Grid team cards
- **Nhiều division:** Segment tabs lấy từ API
- **Ấn team card:** BottomSheet → xem roster → navigate profile

**Files:**
- `TournamentTeamCard` (đã có)
- `TournamentTeamSheet` (đã có — fix typo "Thanh vien" → "Thành viên")
- `TeamsEmptyView` (đã có)
- MỚI: `division_filter_segment.dart` — Segment tabs chọn division
- MỚI: `providers/division_provider.dart` — provider cho divisions API

**API endpoints:**
```
GET /tournaments/:id/divisions
→ [{ id, name, matchType, genderRestriction, entryFee, 
    bracketType, maxParticipants, status, _count: { participants } }]

GET /tournaments/:id/divisions/:divisionId/participants
→ [{ id, teamName, members: [{ id, fullName, avatarUrl }],
    isCheckedIn, isPaid, teamStatus }]
```

---

### TAB 3: Bảng đấu (Lịch + Bracket)

```
┌─── CHỌN HÌNH THỨC ─────────────────┐
│  [Đơn nam ▼]                        │ ← Dropdown chọn division
│  (mỗi division có bracket riêng)    │
└────────────────────────────────────┘

┌─── 2 PHỤ: Lịch thi đấu | Bracket  ──┐ ← TabBar phụ
│                                      │
│  ┌─── LỊCH THI ĐẤU ──────────────┐ │ ← Tab phụ 1
│  │  Vòng 1 - 15/06/2026          │ │
│  │  ┌────────────────────────┐   │ │
│  │  │ 🆚 Team A vs Team B    │   │ │
│  │  │ ⏰ 08:00 - Sân 1       │   │ │
│  │  │ 🟢 Đang diễn ra / 2-1  │   │ │
│  │  └────────────────────────┘   │ │
│  │  ┌────────────────────────┐   │ │
│  │  │ 🆚 Team C vs Team D    │   │ │
│  │  │ ⏰ 09:30 - Sân 2       │   │ │
│  │  │ ⚪ Sắp diễn ra         │   │ │
│  │  └────────────────────────┘   │ │
│  │  ...                          │ │
│  └──────────────────────────────┘ │
│                                    │
│  ┌─── BRACKET ──────────────────┐ │ ← Tab phụ 2
│  │  (InteractiveViewer +        │ │
│  │   graphview tree)            │ │
│  │                              │ │
│  │  Vòng 1    Vòng 2    CK     │ │
│  │  ┌──┐      ┌──┐      ┌──┐  │ │
│  │  │A │──────│A │      │  │  │ │
│  │  │B │      │  │──────│  │  │ │
│  │  └──┘      │C │      │  │  │ │
│  │  ┌──┐      │D │      └──┘  │ │
│  │  │C │──────└──┘           │ │
│  │  │D │                      │ │
│  │  └──┘                      │ │
│  └──────────────────────────────┘ │
└────────────────────────────────────┘
```

**States:**
- **No matches:** "Chưa có lịch thi đấu" empty state
- **Loading:** Shimmer
- **Single division:** Hiển thị luôn
- **Multiple divisions:** Dropdown chọn

**Files cần:**
- MỚI: `tournament_matches_list.dart` — lịch thi đấu dạng list
- `BracketViewScreen` (đã có) — embedded trong tab
- MỚI: `division_selector_dropdown.dart`
- MỚI: `match_card.dart` — card trận đấu (status, time, score)

---

### TAB 4: Đăng ký (IntroScreen)

```
┌─── KIỂM TRA ───────────────────────┐
│  Nếu chưa đăng nhập:               │
│  → "Vui lòng đăng nhập" + button   │
│  → redirect /login                 │
│                                     │
│  Nếu profile chưa đủ (thiếu tên,   │
│  số điện thoại, giới tính):         │
│  → "Hồ sơ chưa hoàn thiện" + button│
│                                     │
│  Nếu đã hết hạn đăng ký:           │
│  → "Đăng ký đã đóng" + lý do       │
│                                     │
│  Nếu yêu cầu mã mời (private):     │
│  → Ô nhập mã mời + Xác thực        │
└────────────────────────────────────┘

┌─── CHỌN HÌNH THỨC THI ĐẤU ────────┐
│  "Chọn nội dung muốn tham gia"     │
│  ┌──────────┐ ┌──────────┐        │
│  │ Đơn nam  │ │ Đôi nam  │        │ ← Card animation, chọn 1
│  │ 8/16 đội │ │ 4/16 đội │        │
│  │ 300.000đ │ │ 500.000đ │        │
│  └──────────┘ └──────────┘        │
│  ┌──────────┐                      │
│  │ Đôi nữ   │                      │
│  │ 2/16 đội │                      │
│  │ 500.000đ │                      │
│  └──────────┘                      │
└────────────────────────────────────┘

┌─── KIỂM TRA ELO ───────────────────┐
│  ✅ ELO của bạn (1340) phù hợp    │ ← Tự động check sau khi chọn division
│  ⚠️ ELO của bạn (1100) thấp hơn   │
│     yêu cầu tối thiểu (1200)      │
└────────────────────────────────────┘

┌─── FORM ĐĂNG KÝ ───────────────────┐
│  Tên đội / Tên thi đấu *          │
│  [________________________]       │
│                                    │
│  * Lưu ý: Lệ phí sẽ thông báo sau │
│  Bằng việc đăng ký, bạn đồng ý    │
│  với điều khoản BTC.              │
└────────────────────────────────────┘

┌─── NẾU LÀ ĐÔI (Doubles) ──────────┐
│  👥 THÔNG TIN ĐỒNG ĐỘI            │
│  ┌─── Tìm kiếm người chơi ──────┐ │
│  │ 🔍 [Tìm kiếm theo tên, email]│ │
│  │ Kết quả: Nguyễn Văn A       │ │
│  │ [Chọn]                        │ │
│  └──────────────────────────────┘ │
│  Hoặc:                            │
│  [💌 Mời đồng đội]               │ ← Sinh link mời, copy/share
│  Link mời: /join-team?token=...   │
│  [📋 Copy link] [📱 Share]       │
│                                    │
│  ⏱ Còn 1g 45p để tìm đồng đội    │ ← Countdown 2 tiếng
└────────────────────────────────────┘

┌─── BOTTOM ─────────────────────────┐
│  [✅ ĐĂNG KÝ NGAY]                │ ← Button chính
│  hoặc (nếu đã đăng ký):           │
│  ✅ Bạn đã đăng ký                 │ ← Thẻ xanh
│  Trạng thái: Đang chờ duyệt       │
│  [Hủy đăng ký] [💳 Thanh toán]   │
└────────────────────────────────────┘

┌─── THANH TOÁN (nếu có phí) ───────┐
│  💳 THANH TOÁN LỆ PHÍ             │
│  Số tiền: 300.000đ                 │
│  Chọn cổng:                        │
│  ┌────┐ ┌────┐ ┌──────────────┐   │
│  │VNPY│ │MoMo│ │Chuyển khoản  │   │
│  └────┘ └────┘ └──────────────┘   │
│  [Tiến hành thanh toán]           │
└────────────────────────────────────┘

┌─── HOÀN TIỀN (khi rút giải) ──────┐
│  📋 THÔNG TIN HOÀN TIỀN           │
│  (Hiện ra nếu đã đóng phí > 0)    │
│  Tên ngân hàng: [____________]    │
│  Số tài khoản: [____________]     │
│  Chủ tài khoản: [____________]    │
│  [Xác nhận rút giải]              │
└────────────────────────────────────┘
```

**States:**
- **Chưa đăng nhập:** Redirect hoặc show login card
- **Profile chưa đủ:** Cảnh báo + nút cập nhật
- **Đã hết hạn:** Thông báo đóng
- **Private:** Invite code input
- **Chưa đăng ký:** Form đầy đủ
- **Đã đăng ký đơn:** Thẻ xanh + hủy/thanh toán
- **Đã đăng ký đôi (chờ đồng đội):** Countdown + link mời
- **Đã đăng ký hoàn tất:** Thẻ xanh
- **Cần thanh toán:** Chọn cổng

**Files cần:**
- MỚI: `tournament_register_tab.dart` — tab tổng
- MỚI: `widgets/register/division_selector.dart` — chọn hình thức
- MỚI: `widgets/register/team_name_form.dart` — tên đội
- MỚI: `widgets/register/partner_search.dart` — tìm đồng đội
- MỚI: `widgets/register/payment_method_selector.dart` — chọn cổng
- MỚI: `widgets/register/bank_refund_form.dart` — thông tin hoàn tiền
- MỚI: `widgets/register/registration_status_card.dart` — thẻ đã đăng ký
- MỚI: `widgets/register/elo_check_card.dart` — kiểm tra ELO

---

## 🧩 Cấu Trúc Files

```
lib/features/tournament/
├── screens/
│   ├── tournament_intro_screen.dart     ← 🔄 REFACTOR CHÍNH
│   └── tournament_detail_screen.dart    ← 🔄 Giữ riêng cho Admin
│
├── widgets/
│   ├── tournament_banner.dart           ← 🔄 Cập nhật (PageView + ảnh)
│   ├── tournament_info_grid.dart        ← ✅ Giữ nguyên
│   ├── tournament_stats_row.dart        ← ✅ Giữ nguyên (cho Admin)
│   ├── tournament_team_card.dart        ← ✅ Giữ nguyên
│   ├── tournament_team_sheet.dart       ← 🔄 Fix typo
│   ├── tournament_teams_empty.dart      ← ✅ Giữ nguyên
│   ├── tournament_state_views.dart      ← ✅ Giữ nguyên
│   │
│   ├── status_badge.dart                ← ✨ MỚI
│   ├── sport_pill.dart                  ← ✨ MỚI
│   ├── tournament_info_card.dart        ← ✨ MỚI (Location+Fee+Timeline)
│   ├── tournament_organizer_card.dart   ← ✨ MỚI (BTC contact)
│   ├── tournament_slots_progress.dart   ← ✨ MỚI (Progress bar)
│   ├── tournament_prizes_view.dart      ← ✨ MỚI (Podium)
│   ├── tournament_description.dart      ← ✨ MỚI (Mô tả + xem thêm)
│   ├── info_strip.dart                  ← ✨ MỚI (Dải thông tin dưới banner)
│   ├── division_filter_segment.dart     ← ✨ MỚI (Segment tabs division)
│   ├── division_selector_dropdown.dart  ← ✨ MỚI (Dropdown division)
│   ├── tournament_matches_list.dart     ← ✨ MỚI (Lịch thi đấu)
│   ├── match_card.dart                  ← ✨ MỚI (Card trận đấu)
│   │
│   └── register/                        ← ⚡ Tất cả components cho Tab Đăng ký
│       ├── tournament_register_tab.dart
│       ├── division_selector.dart
│       ├── team_name_form.dart
│       ├── partner_search.dart
│       ├── payment_method_selector.dart
│       ├── bank_refund_form.dart
│       ├── registration_status_card.dart
│       └── elo_check_card.dart
```

---

## 🔴 BỎ HẾT MOCK DATA — GỌI API THẬT

### Các mock data hiện tại trong code

| File | Mock | Dòng | Thay bằng |
|------|------|:----:|-----------|
| `providers/ranking_provider.dart` | `mockRankingsProvider` — 12 user fake | 5-103 | `rankingsApi.getLeaderboard()` |
| `providers/ranking_provider.dart` | `mockUserRankProvider` — ELO fake 1340 | 10-13 | `rankingsApi.getUserRank(userId)` |
| `providers/ranking_provider.dart` | `mockUserRankingDetailProvider` — detail fake | 15-18 | `rankingsApi.getUserRankings(userId)` |
| `home_screen.dart` | `_mockElo = 1340`, `_mockWins = 31`, `Top 142` | — | `rankingsApi.getUserRank(userId)` |
| `home_screen.dart` | Notification bell count `= 3` | — | API notification count |
| `query_providers.dart` | `presenceCountProvider` — `Stream.value(0)` | 33-38 | Socket.IO presence count |
| `info_strip.dart` | `final currentSlots = 12` | 19-20 | `teamsProvider` real count |
| `rankings/leaderboard_screen.dart` | `ref.watch(mockRankingsProvider)` | 39 | API thật |
| `rankings/user_ranking_detail_screen.dart` | `ref.watch(mockUserRankingDetailProvider)` | 15 | API thật |

### Hành động cụ thể

#### 1. Xoá `providers/ranking_provider.dart`

Tạo lại từ đầu:
```dart
// ✅ THẬT — gọi API
final rankingsProvider = FutureProvider.family<List<PlayerRanking>, RankingsQuery>((ref, query) async {
  final repo = ref.watch(rankingRepositoryProvider);
  return repo.getLeaderboard(query);
});

final userRankProvider = FutureProvider.family<UserRankResponse, String>((ref, userId) async {
  final repo = ref.watch(rankingRepositoryProvider);
  return repo.getUserRank(userId);
});

final userRankingDetailProvider = FutureProvider.family<PlayerRanking, String>((ref, userId) async {
  final repo = ref.watch(rankingRepositoryProvider);
  return repo.getUserRankings(userId);
});
```

#### 2. Sửa `home_screen.dart` — bỏ mock

```dart
// ❌ Xoá: final _mockElo = 1340, _mockWins = 31
// ✅ Thay: gọi userRankProvider khi user đã đăng nhập
final rankAsync = ref.watch(userRankProvider(currentUserId));
// → hiển thị ELO thật, wins thật, rank thật
```

#### 3. Sửa `info_strip.dart` — lấy real slot count

```dart
// ❌ Xoá: final currentSlots = 12;
// ✅ Dùng teamsProvider từ tournament
final teamsAsync = ref.watch(teamsProvider(tournamentId));
final currentSlots = teamsAsync.asData?.value.length ?? 0;
```

#### 4. Sửa `query_providers.dart` — presence count

```dart
// ❌ Xoá: Stream.value(0)
// ✅ Kết nối Socket.IO /live namespace lấy presence thật
// (Hoặc comment chờ khi implement socket)
```

### Backend API sẵn có

| API | Endpoint | Method | Ghi chú |
|-----|----------|--------|---------|
| **Leaderboard** | `/rankings?categoryId=&limit=50` | GET | Public, trả về ranking theo môn |
| **User rank** | `/rankings/user/:userId` | GET | Public, trả ELO + tier + categoryId |
| **User detail** | `/rankings/user/:userId/history` | GET | Lịch sử biến động ELO |
| **Update ELO** | `/rankings/update-elo` | POST | Admin trigger |

```
GET /rankings?categoryId=badminton&limit=50
→ {
    "data": [
      { "id": "p1", "userId": "u1", "fullName": "Nguyễn Văn A",
        "eloPoints": 1850, "tierName": "Kim Cương",
        "rank": 1, "matchesPlayed": 120, "matchesWon": 98 },
      ...
    ]
  }

GET /rankings/user/:userId
→ {
    "eloPoints": 1340,
    "tierName": "Kim Cương",
    "categoryId": "badminton"
  }
```

---

## 📊 Data Flow

### Backend API endpoints cho Tab Đăng ký

| API | Method | Mô tả |
|-----|--------|-------|
| `/tournaments/:id` | GET | Thông tin giải + divisions |
| `/tournaments/:id/divisions` | GET | Danh sách hình thức (division) |
| `/tournaments/:id/register` | POST | Đăng ký tham gia |
| `/tournaments/:id/withdraw` | POST | Rút giải + bank info |
| `/tournaments/:id/my-registration` | GET | Kiểm tra trạng thái đăng ký |
| `/tournaments/:id/validate-invite` | POST | Xác thực mã mời |
| `/users/:id/rank?categoryId=` | GET | Kiểm tra ELO |
| `/payments/checkout` | GET | Redirect thanh toán |

### Flutter Entity Mapping (từ Tournament.fromJson)

```dart
tournament.name                 → Banner title
tournament.sport (category.slug) → SportPill
tournament.category (category.name) → Division filter
tournament.format (matchType)    → InfoGrid
tournament.bracketType           → InfoGrid
tournament.status                → StatusBadge
tournament.entryFee             → Banner + InfoCard + Register
tournament.startDate/endDate    → InfoCard + Lịch
tournament.registrationStartDate/EndDate → Kiểm tra đăng ký
tournament.locationAddress      → Banner + InfoCard
tournament.prizeDescription     → PrizesView
tournament.contactInfo          → OrganizerCard
tournament.description          → Description tab
tournament.maxTeams             → SlotsProgress
tournament.maxPlayersPerTeam    → InfoGrid + Register
```

---

## 🧪 States Cho Từng Tab

### Tab 1 — Thông tin
| State | Xử lý |
|-------|-------|
| Loading | ShimmerBody |
| Error | ErrorView + retry |
| Success | Hiển thị info grid + description + prizes + organizer |
| Không có mô tả | Ẩn section |
| Không có giải thưởng | "BTC chưa cập nhật" |

### Tab 2 — Đội tham gia
| State | Xử lý |
|-------|-------|
| Loading | Shimmer grid |
| Error | ErrorView |
| Empty | TeamsEmptyView |
| Data | Grid 2 cột team cards |
| Nhiều division | Segment tabs filter |
| Ấn team card | BottomSheet → xem roster |

### Tab 3 — Bảng đấu
| State | Xử lý |
|-------|-------|
| Loading | Shimmer |
| Error | ErrorView |
| Empty (chưa có lịch) | "Chưa có lịch thi đấu" |
| Data | Lịch dạng list + Bracket tree |
| Nhiều division | Dropdown chọn |
| Chưa bốc thăm | "Chờ bốc thăm" |

### Tab 4 — Đăng ký
| State | Xử lý |
|-------|-------|
| Chưa đăng nhập | Card đăng nhập + redirect |
| Profile chưa đủ | Cảnh báo + nút cập nhật |
| Hết hạn đăng ký | Thông báo đóng |
| Private (cần mã mời) | Invite code input + verify |
| Chưa đăng ký | Form + chọn division + ELO check |
| Đăng ký đơn xong | Thẻ xanh + thanh toán |
| Đăng ký đôi chờ partner | Countdown + link mời |
| Đăng ký hoàn tất | Thẻ xanh |
| Đã thanh toán | Thẻ đã thanh toán |
| Cần hoàn tiền | Form bank info |

---

## 📝 Coding Guidelines

### 1. Design Tokens
```dart
// ✅ Đúng: context.colors.primary, AppTheme.radiusMedium
// ❌ Sai: Color(0xFF1565C0) hardcode
```

### 2. `withOpacity` → `withAlpha` / `withValues`
```dart
// ✅ Đúng: Colors.white.withAlpha(30)
// ✅ Đúng: AppTheme.primary.withValues(alpha: 0.12)
// ❌ Sai: Colors.white.withOpacity(0.12)
```

### 3. Giới hạn dòng
- Widget con < 300 dòng
- Screen < 400 dòng
- Logic nghiệp vụ trong providers, KHÔNG trong widget

### 4. Text full dấu tiếng Việt
- "Thông tin", "Đội tham gia", "Bảng đấu", "Đăng ký"
- "Thể thức", "Hạng mục", "Giải thưởng"
- "Đã check-in", "Thành viên" (không "Thanh vien")
- "Đăng ký", "Hủy đăng ký", "Đồng đội"

### 5. Animation
- `flutter_animate` cho entry: fadeIn + slideY
- Scale nhẹ (1.02-1.04x) khi chọn division/category
- PageView cho banner nếu nhiều ảnh
- `InteractiveViewer` cho Bracket

### 6. Images
- `PageView` + `Indicator` dots cho banner
- `placeholder` widget khi ảnh lỗi (errorBuilder)
- Aspect ratio 16:9 cho banner images

---

## 📈 Tiến Độ

```
Phase 1: Banner + Info Strip (Tab 1)  ██░░░░░░░░  Chưa làm
Phase 2: Tab 1 - Thông tin giải       ██████░░░░  Đã có 50% components
Phase 3: Tab 2 - Đội tham gia         ██████░░░░  Đã có TeamCard, cần filter
Phase 4: Tab 3 - Bảng đấu            ██░░░░░░░░  Có BracketView, chưa có lịch
Phase 5: Tab 4 - Đăng ký             ░░░░░░░░░░  Chưa làm
Phase 6: Tách Admin DetailScreen     ██████░░░░  Đã có cơ bản
```

---

## 🎯 Thứ Tự Ưu Tiên

| Ưu tiên | Nội dung | Lý do |
|:-------:|----------|-------|
| 1 | **Banner** — PageView + Info strip | Ai vào cũng thấy đầu tiên |
| 2 | **Tab 1: Thông tin** — dùng component có sẵn | Nhanh, ít rủi ro |
| 3 | **Tab 2: Đội tham gia** — thêm filter division | Nhiều giải có nhiều hình thức |
| 4 | **Tab 4: Đăng ký** — form giống web | Tính năng chính, người dùng cần |
| 5 | **Tab 3: Bảng đấu** — lịch + bracket | Đã có BracketView, thêm lịch |
| 6 | **Tách Admin DetailScreen** | Giữ nguyên, ít thay đổi |

---

## 🔗 Liên Kết

- [Design System & UI](ui.md)
- [Flutter UI Design Spec](flutter-ui-design-spec.md)
- [Trạng thái hiện tại](../CURRENT_STATUS.md)
- [Bracket UI Plan](BRACKET_UI_PLAN.md)
- [Feature Plan](FEATURE_PLAN.md)
