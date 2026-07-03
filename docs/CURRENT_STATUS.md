# 📱 Flutter App — Phân tích chi tiết UI & Nghiệp vụ còn thiếu so với Web

> **Cập nhật:** 2026-07-01 | Phương pháp: Đọc trực tiếp source code Flutter + Web, so sánh từng màn hình, từng widget  
> **Phạm vi:** Nghiệp vụ "theo dõi thi đấu" từ góc độ người dùng thông thường, người tham dự, trọng tài

## Cập nhật nhanh 2026-07-02

- App đã có nền workspace mới cho khu vực cá nhân:
  - Dùng `GET /tournaments/workspace/me`
  - Gom được `organizedTournaments`, `participatingTournaments`, `coOrganizerTournaments`, `refereeInvites`, `refereeTournaments`, `refereeMatches`
- Màn `/dashboard` đã được nâng từ dashboard chung thành màn `Của tôi`:
  - Hiện lời mời trọng tài đang chờ
  - Hiện vai trò hiện có theo giải
  - Hiện trận trọng tài được phân công
  - Hiện giải đang tham gia / quản lý và CTA vào bracket
- Màn `Lời mời trọng tài` đã bỏ endpoint cũ sai và chuyển sang workflow đúng của backend:
  - đọc từ workspace
  - phản hồi qua `PATCH /tournaments/:id/referees/:refereeId/respond`

Phần còn thiếu lớn sau cập nhật này:
- Chưa có luồng lời mời BTC/co-organizer riêng
- Chưa có khu `trận sắp đấu của tôi` cho player dựa trên endpoint `me/upcoming`
- Chưa có organizer mobile workspace lite

---

## 1. MÀN HÌNH LIVE ĐIỂM — `/live/[matchId]` vs `LiveScoreScreen`

### 1.1 Header thông tin trận (Status Bar)

| Chi tiết UI | Web ✅ | Flutter 🟡 |
|---|---|---|
| Badge TRỰC TIẾP với hiệu ứng ping đỏ nhấp nháy | ✅ `animate-ping` animation | ✅ Có dấu chấm đỏ cơ bản |
| Badge vòng số (`Vòng 3`) | ✅ | ✅ Có trong AppBar |
| **Số người đang xem real-time** (`👁 142 đang xem`) | ✅ `viewerCount` từ socket | ✅ **Đã tích hợp (Socket.io real-time)** |
| Badge tên môn thể thao (`Môn: Tennis`) | ✅ | ✅ |
| Badge "Chế độ chỉ xem" khi viewer | ✅ | ❌ Không có badge |
| Link quay lại giải đấu | ✅ | ✅ |

### 1.2 Vùng Camera / Livestream

| Chi tiết UI | Web ✅ | Flutter 🟡 |
|---|---|---|
| Container tỷ lệ 16:9 (`aspect-video`) | ✅ | ❌ Cố định 180px chiều cao |
| Gradient overlay đen mờ cao cấp | ✅ | ❌ Chỉ màu đen đặc |
| Hiệu ứng góc viền (corner decorations) | ✅ | ❌ |
| Icon LIVE badge nhấp nháy khi ONGOING | ✅ | ✅ Có chấm đỏ nhưng đơn giản |
| Nội dung thay đổi theo status (SCHEDULED/ONGOING/COMPLETED/CANCELLED) | ✅ 4 trạng thái | ✅ Có nhưng chỉ 2 trạng thái |
| Khi COMPLETED: text "Video Phát Lại (Replay)" | ✅ | ❌ Không phân biệt trạng thái COMPLETED |

### 1.3 Score Card (Bảng điểm chính — Viewer Mode)

| Chi tiết UI | Web ✅ | Flutter 🟡 |
|---|---|---|
| Thanh gradient màu trên cùng (blue→indigo→purple) | ✅ | ❌ |
| Avatar/Icon đội hình tròn lớn | ✅ `w-20 h-20` | ✅ Có nhưng nhỏ hơn |
| **Icon cúp vàng khi là đội thắng** | ✅ `Trophy icon` + `ring-4` | ❌ Không có |
| **ELO + Tier của từng thành viên đội** | ✅ Hiện `eloPoints`, `tierName` dưới avatar | ❌ **Không có** |
| **Link click vào tên thành viên → profile** | ✅ `Link href="/users/{id}"` | ❌ **Không có** |
| Điểm số font cực lớn (text-8xl) | ✅ | ✅ |
| Tên set đang thi (Tennis: "Game của Set 2: 3-2") | ✅ `currentDetailScoreLabel` | ✅ |
| **Set History với set đang đấu highlight đỏ** | ✅ `ring-2 ring-rose-100` | 🟡 Có cơ bản qua `SetHistoryBar` |
| Footer: Tên sân + Giờ thi đấu | ✅ | ❌ **Không có** |
| Won Summary Label ("Sets Won: 2") theo từng môn | ✅ `p1SetsWon`/`p2SetsWon` | 🟡 Qua score panel |

### 1.4 Bảng điều khiển Trọng tài (Referee Control Panel)

| Chi tiết UI | Web ✅ | Flutter 🟡 |
|---|---|---|
| Panel riêng Tennis (`TennisOfficialPanel`) | ✅ | ✅ `TennisScoreScreen` (màn riêng) |
| Panel riêng Pickleball side-out (`PickleballOfficialPanel`) | ✅ | ✅ `PickleballSideoutScoreScreen` |
| **Panel riêng Cầu lông (`BadmintonOfficialPanel`)** | ✅ | ❌ **Không có — dùng Rally generic** |
| **Panel riêng Bóng bàn (`TableTennisOfficialPanel`)** | ✅ | ❌ **Không có — dùng Rally generic** |
| Hướng dẫn luật nhập điểm (score guidance) | ✅ Box màu xanh | ❌ Không có |
| **Override Mode** (bật lý do ngoại lệ để audit) | ✅ Toggle + textarea | ❌ **Không có** |
| **Score Warning** (cảnh báo khi điểm không hợp lệ) | ✅ Box cam | ❌ **Không có** |
| Nút "Chốt Set hiện tại" | ✅ | 🟡 Ẩn trong panel sport |
| Nút "Đội 1 Thắng / Đội 2 Thắng" xác nhận kết thúc | ✅ 2 nút riêng | 🟡 Dialog riêng |
| Penalty Panel tích hợp cùng màn hình | ✅ `PenaltyPanel` component | ✅ `PenaltyInputDialog` (modal) |

### 1.5 Khu vực Comment / Bình luận

| Chi tiết UI | Web ✅ | Flutter 🟡 |
|---|---|---|
| Danh sách comment real-time (socket `comment:new`) | ✅ | 🟡 Có `MatchChatWidget` nhưng chưa rõ socket |
| Avatar + tên người bình luận | ✅ | ✅ |
| Ô nhập bình luận + nút gửi | ✅ | ✅ |
| Yêu cầu đăng nhập để bình luận | ✅ | ✅ |

### 1.6 Nghiệp vụ Viewer Count (SỐ NGƯỜI XEM)

**Web**: Sử dụng `useLiveMatch` hook → nhận `viewerCount` real-time từ socket `/match` namespace.  
**Flutter**: ✅ **Đã tích hợp** thông qua `MatchSocketService` kết nối tới `/live` namespace, lắng nghe sự kiện `viewer:count` cập nhật tự động lên UI.


---

## 2. MÀN HÌNH CHI TIẾT GIẢI ĐẤU — `/tournaments/[id]` vs `TournamentIntroScreen`

### 2.1 Header Banner

| Chi tiết UI | Web ✅ | Flutter 🟡 |
|---|---|---|
| Gallery carousel ảnh kèm banner mặc định | ✅ `GalleryCarousel` | 🟡 Chỉ có banner đơn |
| Logo giải đấu hình vuông bo góc | ✅ `w-24 h-24` | ✅ |
| Badge trạng thái với màu đúng theo status | ✅ 7 trạng thái (DRAFT→CANCELLED) | 🟡 Chỉ 4-5 trạng thái |
| Badge thể thức (LOẠI TRỰC TIẾP / VÒNG TRÒN) | ✅ | ❌ Thiếu |
| Ngày tháng + Địa điểm + Số đội | ✅ | ✅ |
| Nút "Chia sẻ" | ✅ | ❌ |
| Nút "Đăng ký ngay" với logic disabled theo status | ✅ Đầy đủ 7 case | ❌ Thiếu nhiều case |
| Badge "Bạn là chủ sở hữu" khi là organizer | ✅ | ❌ |

### 2.2 5 Tab nội dung

| Tab | Web ✅ | Flutter 🟡 |
|---|---|---|
| **Tab "Tổng quan"** — HTML description rich text | ✅ `dangerouslySetInnerHTML` | ❌ **Không có tab riêng — gộp vào màn intro** |
| **Tab "Giải thưởng"** — HTML prize description | ✅ | ❌ **Không có** |
| Tab "Đội tham gia" — danh sách đội + members | ✅ `TeamsTab` | ✅ `TeamListScreen` (màn riêng) |
| Tab "Bảng đấu" — sơ đồ nhánh | ✅ `BracketTab` | ✅ `BracketViewScreen` |
| Tab "Lịch thi đấu" — grouped by stage | ✅ `MatchesTab` | 🟡 Có nhưng chưa rõ grouping |

### 2.3 Sidebar thông tin đăng ký (Panel phải)

| Chi tiết UI | Web ✅ | Flutter 🟡 |
|---|---|---|
| **Lệ phí tham gia** (số tiền VNĐ / Miễn phí) | ✅ | ❌ **Không hiện** |
| **Thông tin Ban tổ chức** (avatar + tên + badge Uy Tín) | ✅ | ❌ **Không có sidebar** |
| **Progress bar số slot đã điền** (X/Y đội — %%) | ✅ | ❌ **Không có** |
| **Thời gian đăng ký** (start - end date) | ✅ | ✅ Có trong header |
| **Cảnh báo đăng ký đã khóa / hết hạn** | ✅ Alert box màu cam/đỏ | ❌ |
| Thông tin liên hệ (Phone, Email, Website) | ✅ `contactInfo` object | ❌ **Không có** |

### 2.4 Bộ lọc Division (Phân hạng)

| Chi tiết UI | Web ✅ | Flutter 🟡 |
|---|---|---|
| **Dropdown chọn phân hạng** (Nam đơn / Nữ đôi...) | ✅ `divisionsApi.getDivisions()` + select | ❌ **Không có** |
| Toàn bộ tab content thay đổi theo division được chọn | ✅ | ❌ |

### 2.5 MatchesTab — Lịch thi đấu chi tiết

| Chi tiết UI | Web ✅ | Flutter 🟡 |
|---|---|---|
| **Gom nhóm theo Stage/Group** (VD: "Vòng Tứ Kết", "Bán Kết") | ✅ | ❌ **Chưa có grouping** |
| **Badge trạng thái trận** (🔴 Trực Tiếp / Kết Thúc / Chờ Thi Đấu) | ✅ | 🟡 Cơ bản |
| **Điểm từng set** hiển thị dạng ô vuông | ✅ | 🟡 |
| **Link "Xem Chi Tiết"** → `/live/[matchId]` | ✅ | 🟡 Có nhưng routing? |
| **Seed ranking** (`#3`) bên cạnh tên đội | ✅ | ❌ **Không có** |
| **Tên sân** (`MapPin` + courtName) | ✅ | ❌ |
| **Label "VD: Game của Set 1"** theo môn | ✅ `sequenceLabelTitle` | ❌ |
| Click tên thành viên → link profile | ✅ | ❌ |

---

## 3. TRANG CHỦ / KHÁM PHÁ — `page.tsx` vs `HomeScreen`

| Chi tiết UI | Web ✅ | Flutter 🟡 |
|---|---|---|
| Feed trận đang LIVE | ✅ `liveMatches` state | ✅ `LiveMatchCard` |
| **Nút "Thả tim / High Five"** cổ vũ trận | ✅ `highFives` lưu localStorage | ❌ **Không có (chỉ có trên viewer screen)** |
| **Filter theo danh mục môn** (Cầu lông, Tennis...) | ✅ `categories` API | ❌ **Không có filter category trên Home** |
| **Bảng xếp hạng ELO tóm tắt** bên sidebar | ✅ `leaderboard` widget | ❌ |
| **Widget "Trận đấu tiếp theo của tôi"** | ✅ `upcomingMatch` | ❌ **Không có trên Home** |
| Carousel giải đấu nổi bật | ✅ `TournamentHeroBanner` | ✅ |
| Grid câu lạc bộ | ✅ | ✅ |
| Số người tham gia cộng đồng | ✅ | 🟡 |

---

## 4. DASHBOARD CÁ NHÂN — `/dashboard` (Web) vs Flutter (❌ Không có màn riêng)

Web có màn hình `/dashboard` hoàn chỉnh cho người chơi đã đăng nhập:

| Widget | Web ✅ | Flutter |
|---|---|---|
| Chào mừng + avatar | ✅ | ❌ Không có màn dashboard riêng |
| **Giải đấu đang tham gia** (list 3 giải gần nhất) | ✅ `getMyTournaments()` | ❌ |
| **Trận đấu tiếp theo** (dark card VS layout đẹp) | ✅ | ❌ |
| **ELO card** (điểm ELO + win streak badge + win rate) | ✅ | ❌ (chỉ có trên profile) |
| **Lối tắt nhanh** (Xem profile, Quản lý giải) | ✅ | ❌ |
| **Link "Xem tỷ số"** trực tiếp từ trận tiếp theo | ✅ | ❌ |

---

## 5. TENNIS SCORE SCREEN — So sánh chi tiết nghiệp vụ

### Flutter `TennisScoreScreen` — Vấn đề nghiệp vụ

| Vấn đề | Chi tiết |
|---|---|
| **Dùng state nội bộ**, không sync với server real-time | `_p1GamePoints`, `_p2GamePoints` là local state. Nếu 2 trọng tài cùng nhập → conflict |
| **Không có optimistic update** | Web dùng `optimisticTennisPointState` để UI phản hồi ngay, sau đó sync server |
| **Hiển thị tên đội cứng "Đội 1/Đội 2"** | Không đọc tên thực từ `match.team1Name` / `team2Name` |
| **Không có Deuce/Advantage hiển thị đúng** | Web hiển thị `A-40`, `Deuce` qua `formatTennisPointDisplay()`. Flutter chỉ hiện số |
| **Không có Score Rule Warning** | Web hiển thị cảnh báo khi điểm bất thường |
| **Kết thúc trận gọi API khác** | Web: `updateScore()` + `updateStatus()`. Flutter: trực tiếp `patch /matches/:id/score` với `isCompleted: true` — thiếu cập nhật status |

### Web `TennisOfficialPanel` — Có thêm

| Tính năng | Web | Flutter |
|---|---|---|
| Hiển thị game point theo format Tennis chuẩn (0/15/30/40/A) | ✅ `formatTennisPointDisplay()` | 🟡 Chỉ hiện số nguyên |
| Tiebreak mode tự động (`6-6 → tiebreak`) | ✅ Tự nhảy | 🟡 Có nhưng manual |
| Cảnh báo khi mode đặc biệt | ✅ | ❌ |

---

## 6. NGHIỆP VỤ KỸ THUẬT — Vấn đề hệ thống

### 6.1 Real-time Architecture

```
Web:
  useLiveMatch(matchId) 
    → socketClient.getMatchSocket() [namespace /match]
    → Nhận events: score:update, match:status, viewer:count, comment:new
    → Cập nhật UI ngay lập tức (zero delay)

Flutter:  
  singleMatchProvider → watchMatch()
    → api_match_repository.dart:80 → Stream.periodic(5s)
    → HTTP GET /matches/:id mỗi 5 giây
    → Chậm hơn 5 giây, tốn băng thông
```

**Hệ quả trực tiếp:**
- Viewer xem điểm trễ 5 giây so với thực tế
- Không có `viewerCount` live (cần socket)
- Comment mới không tự xuất hiện (cần socket `comment:new`)

### 6.2 Namespace Socket thiếu

```dart
// socket_service.dart — CHỈ kết nối /notifications
_socket = io.io('$serverUrl/notifications', ...);
_socket!.emit('subscribe');
// Lắng nghe: notification:new

// CẦN THÊM: namespace /match
// Events cần lắng nghe:
//   score:update    → cập nhật điểm ngay
//   match:status    → thay đổi status trận
//   viewer:count    → số người đang xem
//   comment:new     → bình luận mới
```

### 6.3 `TennisScoreScreen` không đồng bộ với `scorePanelNotifier`

- Web: tất cả score state được quản lý bởi 1 hook `useLiveMatch`, mọi cập nhật đều phản ánh real-time
- Flutter: `TennisScoreScreen` dùng state nội bộ (`_p1GamePoints`), khi reload app → mất state, không khôi phục được điểm tennis giữa chừng

---

## 7. DANH SÁCH ĐẦY ĐỦ — UI còn thiếu (theo ưu tiên)

### 🔴 Ưu tiên 1 — Sai nghiệp vụ cốt lõi

| STT | Màn hình | UI/Tính năng thiếu | Tác động |
|---|---|---|---|
| 1 | Live Score | **Socket real-time** thay HTTP polling 5s | Điểm trễ 5s, viewer count không có |
| 2 | Live Viewer | **Số người đang xem** (`viewerCount`) | Mất tính năng "social" cốt lõi |
| 3 | Referee Tennis | **Điểm Tennis đúng format** (15/30/40/A/Deuce) | Trọng tài nhập sai concept |
| 4 | Live Viewer | **ELO + Tier thành viên** trong Score Card | Thiếu thông tin quan trọng |
| 5 | Giải đấu | **Dropdown chọn Division** (phân hạng nội dung) | Không thể xem đúng nhánh đấu |

### 🟡 Ưu tiên 2 — Thiếu nghiệp vụ quan trọng

| STT | Màn hình | UI/Tính năng thiếu | Tác động |
|---|---|---|---|
| 6 | Referee | **Panel Cầu lông** riêng (đổi bên, luật 21 điểm) | Sai luật cầu lông |
| 7 | Referee | **Panel Bóng bàn** riêng (đổi bên mỗi 2 điểm) | Sai luật bóng bàn |
| 8 | Referee | **Override Mode** + Score Warning | Thiếu audit trail |
| 9 | Giải đấu | **Tab Giải thưởng** (prizeDescription HTML) | Thiếu thông tin giải |
| 10 | Giải đấu | **Sidebar đăng ký** (lệ phí, slots %, BTC info, contact) | Thiếu thông tin đăng ký |
| 11 | Giải đấu | **Tab Tổng quan** tách riêng | Hiện gộp vào intro screen |
| 12 | MatchesTab | **Grouping by Stage** (Tứ kết, Bán kết...) | Khó đọc lịch đấu |
| 13 | MatchesTab | **Seed ranking** + Tên sân + Giờ thi đấu | Thiếu thông tin trận |

### 🟢 Ưu tiên 3 — Thiếu tính năng phụ

| STT | Màn hình | UI/Tính năng thiếu | Tác động |
|---|---|---|---|
| 14 | Trang chủ | **Filter theo category/môn** | Không filter được giải |
| 15 | Trang chủ | **Widget trận tiếp theo** | Không biết lịch thi đấu của mình |
| 16 | Trang chủ | **ELO sidebar** tóm tắt | |
| 17 | Dashboard | **Màn hình Dashboard riêng** (giải đang tham gia, trận tiếp theo, ELO) | Thiếu trung tâm thông tin cá nhân |
| 18 | Score Card | **Footer sân + giờ** | |
| 19 | Score Card | **Trophy icon khi winner** | |
| 20 | Score Card | **Gradient bar trên header card** | UI nhạt hơn |
| 21 | Live Header | **Camera container aspect-ratio 16:9** | Trông không cân đối |
| 22 | Live Header | **Badge "Chế độ chỉ xem"** | Không rõ quyền của mình |
| 23 | Giải đấu | **Nút Chia sẻ** | |
| 24 | Giải đấu | **Gallery Carousel** nhiều ảnh | Chỉ có 1 banner |
| 25 | Giải đấu | **Link tên thành viên → profile** trong MatchesTab | |

---

## 8. BẢNG XẾP HẠNG (LEADERBOARD) — `/leaderboard` vs `LeaderboardScreen`

| Chi tiết UI | Web ✅ | Flutter 🟡 |
|---|---|---|
| **Bộ lọc theo môn thể thao (category tabs)** | ✅ Tabs động từ API | ✅ Có |
| **Bộ lọc Match Type** (Đơn / Đôi / Đôi Nam Nữ) | ✅ | ❌ **Không có** |
| **Bộ lọc giới tính** (Nam / Nữ) khi chọn loại | ✅ Hiện khi chọn type ≠ MIXED | ❌ **Không có** |
| **Bộ lọc tỉnh thành** (Province Selector) | ✅ 63 tỉnh từ API regions | ❌ **Không có** |
| **Podium Top 3** (sân khấu vinh danh, thiết kế đẹp) | ✅ Badge Champion/2nd/3rd + avatar | 🟡 Có list nhưng không có podium đẹp |
| **Ranks 4-10** dạng card nhỏ grid | ✅ | ❌ Chỉ show list thẳng |
| **Bảng hạng 11-100** 2 cột song song | ✅ Với avatar + ELO Tier badge + tỷ lệ thắng | 🟡 Có bảng nhưng đơn giản hơn |
| **Sidebar giải thích hệ thống Tier** (S/A/B/C/D) | ✅ Liệt kê đủ 9 tier với màu | ❌ **Không có** |
| **Tra cứu ELO theo Gmail/SĐT** | ✅ Form search + enrich ELO theo category | ❌ **Không có** |
| **EloTierBadge** — badge màu theo tier chuẩn hệ thống | ✅ `EloTierBadge` component | 🟡 Dùng `TierPalette` custom |
| Link click tên vận động viên → profile | ✅ `Link href="/users/{id}"` | ❌ |

---

## 9. HỒ SƠ CÔNG KHAI — `/users/[id]` vs `UserProfileScreen`

### 9.1 Header Profile

| Chi tiết UI | Web ✅ | Flutter 🟡 |
|---|---|---|
| **Cover photo** (ảnh bìa full-width 56 chiều cao) | ✅ Gradient fallback đẹp | ❌ **Không có cover photo** |
| Avatar hình tròn to (128px) + border trắng | ✅ `w-32 h-32` | ✅ 96px, có ring gradient |
| Badge "Đã xác minh" + `ShieldCheck` icon | ✅ | ✅ Có icon xanh |
| **Danh sách ELO Tier Badge** theo từng môn ngay trên header | ✅ Chips màu theo tier | ❌ Chỉ hiện ở ELO tab |
| **Ngày tham gia** (`Tham gia từ 01/2024`) | ✅ | ❌ |
| Badge "Vận động viên" | ✅ | ❌ |

### 9.2 Tab nội dung (Web có 3 tab)

| Tab | Web ✅ | Flutter |
|---|---|---|
| **Tab "Tổng quan"** — Bio + Giới tính + Activity feed | ✅ | ❌ **Không có tab — hiện thẳng cuộn** |
| **Tab "Trận đấu"** — 10 trận gần nhất với kết quả | ✅ Hiện đối thủ, điểm số, Thắng/Thua badge, link live | ❌ **Không có** |
| **Tab "Thống kê ELO"** — Cards ELO theo môn + Biểu đồ đường ELO theo thời gian + Lịch sử ELO | ✅ Recharts LineChart | ❌ **Không có biểu đồ ELO** |

### 9.3 ELO Stats Card (mỗi môn)

| Chi tiết | Web ✅ | Flutter 🟡 |
|---|---|---|
| ELO + Tier badge | ✅ | ✅ |
| Số trận / Thắng / Win Streak | ✅ 3 stat boxes | ✅ Có (Trận, Thắng, Tỉ lệ) |
| **Win Streak với icon Zap** | ✅ `Zap` icon | ❌ Không có win streak |
| **Biểu đồ ELO theo thời gian** | ✅ `LineChart` recharts | ❌ **Không có** |
| **Lịch sử thay đổi ELO** (log từng trận) | ✅ Danh sách ngày + giải + +/-ELO | ❌ **Không có** |

---

## 10. HỒ SƠ CÁ NHÂN — `/profile` vs `ProfileScreen`

### 10.1 So sánh

| Chi tiết | Web ✅ | Flutter 🟡 |
|---|---|---|
| ELO ranking cards | ✅ Có trên dashboard | ✅ Tab "Thông tin & Chỉ số" có card gradient đẹp |
| Cover photo + Avatar upload | ✅ | ✅ Có upload cả cover và avatar |
| **Tab "Trận đấu"** (lịch sử) | ✅ | ❌ **Không có trong Profile** |
| **Biểu đồ ELO** | ✅ | ❌ |
| **Lịch sử ELO** | ✅ | ❌ (menu "Lịch sử ELO" nhưng route = `null` — chưa implement) |
| Thông tin ngân hàng | ✅ Trong settings | ✅ Hiện trong Info Card |
| **Nút "Xem profile công khai"** | ✅ | ❌ |
| Menu "Cài đặt & Tiện ích" | ✅ | ✅ Tab 2 |

---

## 11. BAN TỔ CHỨC — Quản lý giải (Organizer Manage/Ops)

> Flutter **không có màn hình quản lý dành cho BTC**. Tất cả chức năng Organizer chỉ có trên Web.

### 11.1 Manage Tabs (Web `/organizer/tournaments/[id]/manage`)

| Tab | Tính năng chính | Flutter |
|---|---|---|
| **Tab Thông tin** | Tên, mô tả, logo, banner, gallery ảnh, giải thưởng, thông tin liên hệ | ❌ Chỉ có `CreateTournamentScreen` nhưng không có màn sửa đầy đủ |
| **Tab Lịch & Địa điểm** | Tỉnh/huyện/xã, sân thi đấu, ngày khai mạc/bế mạc | ❌ |
| **Tab Đăng ký** | Chế độ công khai/riêng tư, link mời, duyệt/từ chối hồ sơ, seed mock data, suất đặc cách | ❌ |
| **Tab Sơ đồ** | Generate bracket, cấu hình luật theo vòng/trận, sport rule presets | ❌ |
| **Tab Tài chính** | Lệ phí tham gia, phí sàn, yêu cầu rút tiền | ❌ |
| **Tab Phân quyền** | Thêm/xóa trọng tài, co-organizer | ❌ |

### 11.2 Ops Panel (Web `/organizer/tournaments/[id]/ops`)

| Tính năng | Web ✅ | Flutter |
|---|---|---|
| **Health Dashboard** (Số chặng, vòng, chưa xếp lịch, xung đột, tranh chấp) | ✅ 6 stat cards | ❌ |
| **Nhịp vận hành theo vòng** (Chờ/Đang/Xong per round) | ✅ | ❌ |
| **Phát hiện xung đột** (trùng sân, trùng trọng tài, trùng VĐV, sai thứ tự nhánh) | ✅ Logic `conflictSummary` tự động | ❌ |
| **Danh sách trận** với bộ lọc status + tìm kiếm | ✅ `OpsMatches` component | ❌ |
| **Xếp lịch trận** (sân + giờ + trọng tài + config riêng) | ✅ | ❌ |
| **Cập nhật điểm trực tiếp** từ Ops panel | ✅ `updateMatchScore()` | ❌ |
| **Tạo tranh chấp** (Dispute) + giải quyết tranh chấp | ✅ `OpsDisputes` component | ❌ |
| **Nhật ký hoạt động** (Activity Log) | ✅ `OpsActivity` component | ❌ |
| **Kick người tham gia** | ✅ | ❌ |
| **Tóm tắt giải** (overview stats) | ✅ `OpsOverview` | ❌ |

### 11.3 TournamentStepper (Luồng Publish giải)

| Bước | Web ✅ | Flutter |
|---|---|---|
| Stepper trực quan: DRAFT → Registration Open → Registration Closed → Bracket → Live → Completed | ✅ `TournamentStepper` với 6 bước có màu | ❌ Không có stepper |
| Nút Publish + xác nhận phí công bố | ✅ | ❌ |
| Nút chốt danh sách + modal tóm tắt số người / phí sàn | ✅ Lock modal | ❌ |

### 11.4 Manage Bracket — Cấu hình luật chơi (Web có, Flutter thiếu)

| Tính năng | Web ✅ | Flutter |
|---|---|---|
| **Sport Rule Presets** (Preset nhanh: BO3/BO5, luật cầu lông 21 điểm...) | ✅ `getSportRulePresets()` | ❌ |
| **Cấu hình luật theo từng vòng** (setsToWin, pointsPerSet, winByTwo, maxDeuce) | ✅ Round modal | ❌ |
| **Cấu hình riêng từng trận** (override sport rule per match) | ✅ Match modal | ❌ |
| **Super Tiebreak** toggle + điểm | ✅ | ❌ |
| Ghi chú điều phối vòng đấu | ✅ Textarea | ❌ |
| Sân mặc định cho vòng | ✅ Select venues | ❌ |

---

## 12. ĐĂNG KÝ GIẢI ĐẤU — `/tournaments/[id]/register` vs Flutter

| Chi tiết | Web ✅ | Flutter |
|---|---|---|
| **Form đăng ký cá nhân/đội** (tên đội + partner nếu đánh đôi) | ✅ Multi-step form | ✅ `tournament_registration_sheet.dart` |
| **Chọn Division** khi đăng ký | ✅ | 🟡 Có nhưng qua `DivisionFilterSegment` |
| **Thanh toán lệ phí** online (VNPay/MoMo) | ✅ | ❌ **Không có** |
| **Ghép partner** (invite token để đối tác xác nhận) | ✅ `teamInviteToken` flow | ❌ |
| **Nhập mã mời** (inviteCode) để vào giải riêng tư | ✅ | 🟡 Chưa rõ có flow inviteCode không |
| Xem trạng thái đăng ký (PENDING / COMPLETE / REJECTED) | ✅ Realtime | 🟡 Cơ bản |

---

## 13. COMMUNITY (CLB) — `/communities/[id]` vs `ClubDetailScreen`

| Tab/Tính năng | Web ✅ | Flutter 🟡 |
|---|---|---|
| Tab "Giới thiệu" + rich text mô tả | ✅ `AboutTab` | ✅ Có mô tả |
| Tab "Thành viên" + roles + join request | ✅ `MembersTab` với Moderator/Member/Request | ✅ Cơ bản |
| Tab "Gallery ảnh" | ✅ `GalleryTab` | ❌ **Không có** |
| **Tab "Xếp hạng nội bộ CLB"** (ELO trong CLB) | ✅ `RankingsTab` | ❌ **Không có** |
| **Tab "Giải đấu CLB"** (danh sách giải do CLB tổ chức) | ✅ `TournamentsTab` | ✅ Có `CreateClubTournamentScreen` |
| **Tab "Kiểm duyệt"** (quản lý thành viên vi phạm) | ✅ `ModerationTab` với warn/ban | ❌ **Không có** |
| **Tab "Cài đặt CLB"** (chỉnh logo, banner, mô tả, rules, visibility) | ✅ `SettingsTab` đầy đủ | 🟡 Có `ClubManagementScreen` nhưng đơn giản hơn |
| Badge role "Trưởng CLB / Phó / Thành viên" | ✅ | ✅ |
| **Nút "Đăng bài / Post"** trong CLB feed | ✅ | ❌ Không có feed |
| **Số thành viên + chỉ số hoạt động** | ✅ Header stats | 🟡 |

---

## 14. TÓM TẮT SO SÁNH TỔNG QUAN (ĐẦY ĐỦ)

```
Mức độ hoàn thiện theo module:

LiveScore Referee        ████████████████████  95% — Gần đủ, thiếu Badminton/TableTennis panel
LiveScore Viewer         ████████████░░░░░░░░  60% — Thiếu socket, viewer count, ELO members
TournamentDetail         ████████████░░░░░░░░  60% — Thiếu division, sidebar, tab Giải thưởng
MatchesTab               ████████░░░░░░░░░░░░  40% — Thiếu grouping, seed, sân, giờ
HomePage Feed            ████████████████░░░░  80% — Thiếu category filter, widget trận tiếp theo
Dashboard                ████░░░░░░░░░░░░░░░░  20% — Chưa có màn riêng
RealTime Architecture    ████░░░░░░░░░░░░░░░░  20% — Toàn bộ dùng HTTP polling
Leaderboard              ████████████░░░░░░░░  60% — Thiếu filter matchtype/gender/province, podium, search ELO
User Public Profile      ████████░░░░░░░░░░░░  40% — Thiếu cover photo, tab trận đấu, biểu đồ ELO
Personal Profile         ████████████░░░░░░░░  65% — Thiếu lịch sử ELO, tab trận đấu, link profile công khai
Organizer Manage         ░░░░░░░░░░░░░░░░░░░░   0% — Toàn bộ chức năng BTC chỉ có trên Web
Organizer Ops            ░░░░░░░░░░░░░░░░░░░░   0% — Không có health dashboard, conflict detection, dispute
Registration             ████████░░░░░░░░░░░░  40% — Thiếu payment, partner invite, inviteCode flow
Community                ████████████░░░░░░░░  60% — Thiếu gallery, ranking nội bộ, moderation, post feed
```

### Tổng số tính năng kiểm tra

| Nhóm | Web có | Flutter có | Tỷ lệ |
|---|---|---|---|
| Live Score (Viewer + Referee) | 32 | 20 | 62% |
| Tournament Detail | 24 | 13 | 54% |
| Leaderboard | 10 | 5 | 50% |
| User Public Profile | 14 | 5 | 36% |
| Personal Profile | 11 | 8 | 73% |
| Organizer Manage | 30 | 0 | 0% |
| Organizer Ops | 12 | 0 | 0% |
| Registration | 6 | 3 | 50% |
| Community | 10 | 5 | 50% |
| **TỔNG** | **149** | **59** | **~40%** |
