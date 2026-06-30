# 🎨 Plan Thiết Kế Nav Tab 2 (Giải đấu) & Tab 4 (Bảng xếp hạng)

> **Phiên bản:** 1.0  
> **Ngày:** 30/06/2026  
> **Tuân thủ:** `SKILLS.md`, `app_responsive.dart`, `flutter-ui-design-spec.md`

---

## 📐 Tab 1: Giải đấu (Tournament List)

### Layout Tổng Thể (Mobile)

```
┌──────────────────────────────────────┐
│  🔙  Giải đấu          [Nhập mã]    │ ← AppBar
├──────────────────────────────────────┤
│  ┌─── BỘ LỌC ─────────────────────┐ │
│  │  [🏸 Tất cả] [🏸 Cầu lông]     │ │ ← Sport chips (horizontal scroll)
│  │  [🏸 Tennis] [🏸 Pickleball]   │ │
│  │  [🏸 Bóng đá] [🏸 Bóng bàn]   │ │
│  └──────────────────────────────────┘ │
│                                       │
│  ┌─── TRẠNG THÁI ──────────────────┐ │
│  │  [Tất cả] [Sắp diễn ra] [Live]  │ │ ← Status tabs
│  │  [Đã kết thúc]                  │ │
│  └──────────────────────────────────┘ │
│                                       │
│  ┌─── DANH SÁCH GIẢI ĐẤU ──────────┐ │
│  │  ┌──────────────────────────┐   │ │
│  │  │  🏸  GIẢI CẦU LÔNG VNDC  │   │ │ ← Card lớn đẹp
│  │  │       MỞ RỘNG 2026      │   │ │
│  │  │  📅 15/06 - 20/06       │   │ │
│  │  │  👥 16 đội  ·  Đánh đôi │   │ │
│  │  │       🔴 ĐANG DIỄN RA   │   │ │
│  │  └──────────────────────────┘   │ │
│  │  ┌──────────────────────────┐   │ │
│  │  │  🎾  GIẢI TENNIS MỞ RỘNG│   │ │
│  │  │       2026               │   │ │
│  │  │  📅 20/07 - 25/07       │   │ │
│  │  │  👥 32 đội · Đánh đơn   │   │ │
│  │  │       🟢 ĐANG ĐĂNG KÝ   │   │ │
│  │  └──────────────────────────┘   │ │
│  │  ...                            │ │
│  └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Card Design

```
┌──────────────────────────────────────┐
│                                      │
│  ┌─── ROW: Icon + Info + Status ──┐ │
│  │  ┌────┐                        │ │
│  │  │ 🏸 │  GIẢI CẦU LÔNG VNDC   │ │
│  │  │    │  MỞ RỘNG 2026         │ │
│  │  │50px│                        │ │
│  │  └────┘                        │ │
│  └──────────────────────────────────┘ │
│                                       │
│  ┌─── INFO ROW ────────────────────┐ │
│  │  📅 15/06 - 20/06              │ │
│  │  👥 16 đội                     │ │
│  │  🏆 Loại trực tiếp             │ │
│  └──────────────────────────────────┘ │
│                                       │
│  ┌─── STATUS + ACTION ─────────────┐ │
│  │  [🟢 ĐANG ĐĂNG KÝ]  [▶]        │ │
│  └──────────────────────────────────┘ │
│                                       │
│  (Optional: banner image gradient)    │
└──────────────────────────────────────┘
```

### Card Spec

| Element | Style |
|---------|-------|
| **Container** | `bgCard`, border radius 20, border 1px, shadowSM |
| **Sport Icon** | 50×50, `bgSurface` + border, bo góc 14, icon 24px |
| **Tên giải** | 16px bold, max 2 lines |
| **Info row** | Icons 14px + text 12px textSecondary |
| **Status badge** | 10px bold white, background động theo status |
| **Padding** | 16px all |
| **Margin bottom** | 12px |
| **Aspect ratio** | Tự do (chiều cao theo content) |

### Bộ Lọc (Filters)

**1. Sport Filter — Chip ngang**
```
[Tất cả 🏆] [Cầu lông 🏸] [Tennis 🎾] [Pickleball] [Bóng đá ⚽] [Bóng bàn 🏓]
```
- Horizontal scroll, wrap nếu cần
- Chips: bgCard mặc định, primary + bgSurface khi active
- Animation scale nhẹ khi active (1.02)

**2. Status Filter — Segmented tabs**
```
[Tất cả] [Sắp diễn ra] [Đang diễn ra] [Đã kết thúc]
```
- Dạng pills / segment, active = primary

**3. Search — TextField ở AppBar**
- Khi focus → ẩn chips, show keyboard + results
- Lọc theo tên giải

### States

| State | Xử lý |
|-------|-------|
| **Loading** | Shimmer: 4 card placeholder |
| **Empty** | Icon + "Chưa có giải đấu nào" + suggest filter |
| **Error** | ErrorView + retry |
| **Filtered empty** | "Không tìm thấy giải đấu phù hợp" + "Xoá bộ lọc" |
| **Data** | SliverList card list |

---

## 📐 Tab 4: Bảng xếp hạng (Leaderboard)

### Layout Tổng Thể (Mobile)

```
┌──────────────────────────────────────┐
│  🏆 Bảng xếp hạng                   │ ← Header
├──────────────────────────────────────┤
│  ┌─── BỘ LỌC ─────────────────────┐ │
│  │  [🏸 Tất cả] [Cầu lông]        │ │ ← Sport filter chips
│  │  [Tennis] [Pickleball]         │ │
│  └──────────────────────────────────┘ │
│                                       │
│  ┌─── PODIUM TOP 3 ────────────────┐ │
│  │         🥇                       │ │
│  │    Nguyễn Văn A                 │ │
│  │    1850 ELO                     │ │
│  │                                 │ │
│  │  🥈          🥉                │ │
│  │  Trần B      Lê C              │ │
│  │  1720        1680              │ │
│  └──────────────────────────────────┘ │
│                                       │
│  ┌─── DANH SÁCH XẾP HẠNG ──────────┐ │
│  │  4  👤 Nguyễn Văn D    1600     │ │ ← Ranking card
│  │        Thắng 65 · Thua 25      │ │
│  │  5  👤 Phạm Thị E     1550     │ │
│  │        Thắng 60 · Thua 28      │ │
│  │  ...                            │ │
│  └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Podium Design (Top 3)

```
┌──────────────────────────────────────┐
│         ┌──────────┐                │
│         │    🥇    │                │ ← Gold crown
│         │  rank 1  │                │
│         └──────────┘                │
│         Nguyễn Văn A               │
│          1850 ELO                   │
│           Trận: 120                 │
│           Win rate: 82%            │
│                                      │
│  ┌──────────┐  ┌──────────┐        │
│  │    🥈    │  │    🥉    │        │ ← Silver/Bronze
│  │  rank 2  │  │  rank 3  │        │
│  └──────────┘  └──────────┘        │
│  Trần B          Lê C              │
│  1720            1680              │
│  Trận: 105       Trận: 98         │
└──────────────────────────────────────┘
```

### Ranking Card Design (từ 4–N)

```
┌──────────────────────────────────────┐
│  4  ┌────┐  Nguyễn Văn D     1600  │
│      │ 👤 │  Thắng 65 · Thua 25    │
│      └────┘                        │
│                                     │
│  5  ┌────┐  Phạm Thị E      1550  │
│      │ 👤 │  Thắng 60 · Thua 28   │
│      └────┘                        │
└────────────────────────────────────┘
```

**Row spec:**
- **Rank number**: 12px bold, textSecondary (top 3 có màu gold/silver/bronze)
- **Avatar**: 36×36, border radius 10
- **Name**: 14px bold, 1 line
- **ELO**: 14px bold, primary color
- **Stats**: 11px textSecondary, "Thắng X · Thua Y"
- **Chevron**: bên phải

### Stats Bar (Tài khoản của tôi)

```
┌─── NẾU ĐÃ ĐĂNG NHẬP ──────────────┐
│  ┌──────────────────────────────┐  │
│  │  👤  Nguyễn Văn A           │  │
│  │  Hạng 12       1340 ELO    │  │
│  │  Thắng 31 · Thua 16        │  │
│  │     ━━━━━━━━━━━━━━━━       │  │ ← Win rate bar 66%
│  └──────────────────────────────┘  │
└────────────────────────────────────┘
```

### Bộ Lọc (Filters)

**1. Sport Filter — Chip ngang**
- Giống tab Giải đấu: [Tất cả] [Cầu lông] [Tennis] [Pickleball] ...
- Gọi API `GET /rankings?categoryId=...`

**2. Period filter (optional)**
- [Mọi lúc] [Tuần này] [Tháng này] [Mùa giải]

### States

| State | Xử lý |
|-------|-------|
| **Loading** | Shimmer podium + 3 card |
| **Empty** | "Chưa có dữ liệu xếp hạng" |
| **Error** | ErrorView + retry |
| **Data** | Podium + ListView |
| **Chưa login** | Stats bar ẩn, chỉ hiển thị ranking public |
| **Ím hơn 3 người** | Chỉ podium + list, không đủ top 3 thì ẩn podium |

---

## 🎯 Các Component Cần Tạo

### Shared (dùng chung)

| Component | Mô tả |
|-----------|-------|
| `core/widgets/sport_filter_chips.dart` | Chips lọc môn thể thao (tái sử dụng) |
| `core/widgets/status_segment.dart` | Segment tabs cho trạng thái |
| `core/widgets/shimmer_card.dart` | Shimmer placeholder cho card |

### Tab 1 — Giải đấu

| Component | Mô tả |
|-----------|-------|
| `features/home/widgets/tournament_card_v2.dart` | Card giải đấu đẹp (thay TournamentCardList) |
| `features/home/widgets/tournament_filter_bar.dart` | Bar chứa sport chips + status |

### Tab 4 — Bảng xếp hạng

| Component | Mô tả |
|-----------|-------|
| `features/rankings/widgets/podium_view.dart` | Top 3 podium |
| `features/rankings/widgets/ranking_row.dart` | 1 row ranking (rank 4+) |
| `features/rankings/widgets/user_stats_card.dart` | Stats bar của user hiện tại |
| `features/rankings/widgets/ranking_filter_bar.dart` | Sport chips + period |

---

## 📈 Tiến Độ

```
Phase 1: Sport filter chips (shared)     ░░░░░░░░░░  Chưa làm
Phase 2: Tournament card v2               ░░░░░░░░░░  Chưa làm
Phase 3: Tournament list tab hoàn chỉnh   ░░░░░░░░░░  Chưa làm
Phase 4: Podium view                      ░░░░░░░░░░  Chưa làm
Phase 5: Ranking list tab hoàn chỉnh      ░░░░░░░░░░  Chưa làm
```

---

## 🎯 Thứ Tự Ưu Tiên

| Ưu tiên | Nội dung | Lý do |
|:-------:|----------|-------|
| ⭐1 | **Sport filter chips** | Dùng chung cho cả 2 tab |
| ⭐2 | **Tournament card v2** | Card đẹp, thay card cũ |
| ⭐3 | **Tournament list** | Kết hợp filter + card + list |
| ⭐4 | **Podium view** | Điểm nhấn cho ranking |
| ⭐5 | **Ranking list** | Kết hợp podium + list + filter |

---

## 🔗 Liên Kết

- [Design System & UI](ui.md)
- [Flutter UI Design Spec](flutter-ui-design-spec.md)
- [App Responsive](../lib/core/widgets/app_responsive.dart)
- [Trạng thái hiện tại](../CURRENT_STATUS.md)
