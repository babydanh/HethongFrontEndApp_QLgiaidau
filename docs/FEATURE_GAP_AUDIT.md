
# Báo Cáo Audit: Flutter App Lite vs Web Frontend

**Ngày:** 22/07/2026  
**Phạm vi:** 5 trang chính của Flutter app so với web frontend  
**Web so sánh:** `frontend-web_qlgiaidau/src/app/` (Next.js)

---

## TỔNG QUAN

Flutter app đã có nền tảng tốt với nhiều tính năng được implement đầy đủ (bracket, live score, payment, community clubs, notifications, v.v.). Tuy nhiên, so với web frontend, còn một số gaps đáng kể về **UI quality**, **tính năng** và **chiều sâu** ở cả 5 trang chính.

---

## 1. HOME / EXPLORE SCREEN

### Current State
- `home_screen.dart` (2512 dòng) — Full redesign với wave gradient header, search bar, sport filter dropdown, notification bell, carousel tự động, scroll animation
- `explore_tab.dart` (1133 dòng) — Wave header động, search bar, sport filter chips, 3 sections (nổi bật / live / hoàn thành), empty state
- Bottom nav với 5 tabs (Explore, Tournaments, Profile, Clubs, Rankings)

### UI Issues
| Issue | Mô tả | Priority |
|-------|-------|----------|
| File quá lớn | `home_screen.dart` 2512 dòng, `explore_tab.dart` 1133 dòng — khó maintain | P1 |
| Dark theme only | Không có light mode toggle trên home screen (dù có ở Profile) | P2 |
| Header padding cứng | Dùng `SafeArea` + padding hardcode (`240.0`, `90.0`) dễ vỡ trên thiết bị lạ | P1 |
| Thiếu loading skeleton | Khi load tournaments, chỉ hiện spinner trung tâm thay vì skeleton cards | P2 |

### Missing Features vs Web
| Feature | Web có | Flutter | Priority |
|---------|--------|---------|----------|
| Featured tournaments hero banner | ✅ Hero banner với tournament nổi bật | ❌ Không có banner riêng cho featured | P2 |
| Advanced filters (region, district, content type) | ✅ Lọc theo vùng/quận/nội dung/ELO/thể thức | ❌ Chỉ filter theo môn thể thao | P2 |
| Pagination | ✅ Phân trang tournament list | ❌ Load all tournaments cùng lúc | P1 |
| Community discovery grid | ✅ Communities page riêng với card design | ❌ Chỉ có tab clubs đơn giản | P1 |
| Follow từ list view | ✅ Follow/unfollow ngay từ danh sách | ❌ Chỉ follow được từ detail page | P2 |

---

## 2. TOURNAMENTS LIST & DETAIL

### Current State
- `tournament_intro_screen.dart` (1744 dòng) — 4 tabs (About, Teams, Bracket, Gallery), division filter, follow/unfollow, share, viewer count badge, countdown timer
- `tournament_detail_screen.dart` (admin) — Token management, team management, auto draw, bracket view, export Excel
- Route: `/tournaments/:id` (public) và admin routes riêng

### UI Issues
| Issue | Mô tả | Priority |
|-------|-------|----------|
| File quá lớn | `tournament_intro_screen.dart` 1744 dòng | P1 |
| Divisions filter ẩn | DivisionFilterSegment chỉ hiện khi ở tab != About | P2 |
| Gallery tab sơ sài | Chỉ là tab trống — web không có gallery riêng | P2 |
| Thiếu loading skeleton | Chỉ có spinner, không có skeleton loading | P1 |

### Missing Features vs Web
| Feature | Web có | Flutter | Priority |
|---------|--------|---------|----------|
| **Prizes tab** | ✅ Tab "Prizes" riêng hiển thị giải thưởng | ❌ **Không có** | **P1** |
| **Matches tab** trong tournament detail | ✅ Tab "Matches" hiển thị tất cả trận đấu + filter vòng/trạng thái | ❌ **Không có** (chỉ có Bracket tab) | **P1** |
| Registration flow đầy đủ | ✅ DoublesRegistrationFlow, withdraw modal, team creation | ❌ Chỉ có form đăng ký cơ bản | **P0** |
| Social share (Zalo/Facebook/Instagram) | ✅ ShareModal với nhiều nền tảng XH | ❌ Chỉ dùng native system share | P2 |
| SEO metadata | ✅ OpenGraph + Twitter cards cho từng tournament | ❌ Không có (mobile app — chấp nhận được) | P2 |
| Report violation button | ✅ Nút báo cáo vi phạm | ❌ Không có | P2 |
| Withdraw from tournament | ✅ WithdrawModal component | ❌ Không có nút rút lui | P1 |
| Expandable team members | ✅ Click vào đội để xem members | ❌ Chỉ hiện tên đội | P2 |

---

## 3. MATCH LIST

### Current State
- `matches_list_screen.dart` (759 dòng) — Search bar, sport/status/date/location filters, grouped by tournament, refresh indicator, error state, empty state
- `live_score_screen.dart` (3274 dòng) — Live score tracking với nhiều sport panels (badminton, tennis, table tennis, pickleball), set history, penalty, injury

### UI Issues
| Issue | Mô tả | Priority |
|-------|-------|----------|
| Match card quá đơn giản | Chỉ text-based team names và scores | P1 |
| Thiếu ELO badges | Web hiển thị ELO tier badge trên mỗi match card | P1 |
| Thiếu avatar participants | Web hiển thị avatar VĐV 2 bên | P2 |
| Live score screen quá lớn | 3274 dòng — cần refactor | P1 |

### Missing Features vs Web
| Feature | Web có | Flutter | Priority |
|---------|--------|---------|----------|
| **ELO badges trên match card** | ✅ Mỗi player/team có ELO + tier badge | ❌ **Không có** | **P1** |
| **Viewer count / Cheer count** | ✅ Số người xem + cổ vũ | ❌ **Không có** | **P1** |
| Match round labels | ✅ "Vòng 1/8", "Tứ kết" tự động theo bracket size | ❌ Không có | P2 |
| Score display summary | ✅ extractMatchScores + presentation helper | ❌ Chỉ show raw scores | P2 |
| Avatars trên match card | ✅ Hiện avatar VĐV/team 2 bên | ❌ Chỉ text | P2 |

---

## 4. RANKINGS / LEADERBOARD

### Current State
- `leaderboard_screen.dart` (611 dòng) — Sport chips, match type filter (SINGLES/DOUBLES/MIXED), gender filter, province filter, search by name, podium view, tier legend, user stats card
- Widgets: `elo_progress_card.dart`, `podium_view.dart`, `ranking_row.dart`, `tier_legend_view.dart`, `user_stats_card.dart`

### UI Issues
| Issue | Mô tả | Priority |
|-------|-------|----------|
| 148px top padding | Leaderboard embedded trong HomeScreen với padding cứng cho header | P0 |
| Thiếu header title khi đứng riêng | Nếu dùng standalone, không có app bar | P1 |
| Search chỉ trong Top 100 | Web search được toàn bộ user trên hệ thống | P1 |
| Thiếu transition animation | Web dùng Framer Motion cho mượt | P2 |

### Missing Features vs Web
| Feature | Web có | Flutter | Priority |
|---------|--------|---------|----------|
| **User search toàn hệ thống** | ✅ Search users API (tìm theo tên/email/SĐT) + enrich với ELO | ❌ Chỉ filter trong top 100 đã load | **P1** |
| **ELO User search riêng** | ✅ Form search riêng, gọi usersApi.searchUsersByQuery | ❌ **Không có** | **P1** |
| Empty search result nâng cao | ✅ "VĐV có thể nằm ngoài Top 100" + hướng dẫn | ❌ Chỉ "not found" | P2 |

---

## 5. PROFILE

### Current State
- `profile_screen.dart` (1648 dòng) — Cover/avatar với camera upload, ELO rankings card, personal info, my tournaments, followed tournaments, settings, theme toggle
- `edit_profile_screen.dart`, `settings_screen.dart`, `change_password_screen.dart`, `user_profile_screen.dart`
- 2 tabs: "Thông tin & Tiện ích" / "Theo dõi & Nghiên cứu"

### UI Issues
| Issue | Mô tả | Priority |
|-------|-------|----------|
| File rất lớn | `profile_screen.dart` 1648 dòng | P1 |
| Chỉ 2 tabs | Web có 5 tabs — thiếu nhiều nội dung | P0 |
| Thiếu ELO chart | Web có biểu đồ LineChart Recharts rất đẹp | P0 |
| Thiếu achievement cards | Web có card cho quán quân/á quân/hạng ba | P1 |
| Thiếu match history | Web có tab matches riêng | P1 |

### Missing Features vs Web
| Feature | Web có | Flutter | Priority |
|---------|--------|---------|----------|
| **ELO History Chart** | ✅ LineChart Recharts: biểu đồ ELO theo thời gian (ResponsiveContainer, XAxis, YAxis, CartesianGrid, Tooltip, Legend) | ❌ **Không có** | **P0** |
| **Achievements Section** | ✅ Tournament placements: quán quân/á quân/hạng ba với medal styling | ❌ **Không có** | **P0** |
| **Match History trong profile** | ✅ Tab "matches" riêng với lịch sử trận đấu | ❌ **Không có** | **P1** |
| **5 tabs** (overview, tournaments, achievements, matches, elo) | ✅ Đầy đủ | ❌ Chỉ 2 tabs | **P1** |
| Verification ticket system | ✅ Upload giấy tờ, trạng thái PENDING/APPROVED/REJECTED | ❌ Không có | P2 |
| ELO history log | ✅ EloHistoryLog với từng thay đổi ELO | ❌ Không có | P1 |
| Community management | ✅ Quản lý communities trong profile | ❌ Không có (có community riêng) | P2 |

---

## TỔNG HỢP PRIORITY

### P0 — Phải sửa ngay
| # | Tính năng | Trang | Lý do |
|---|-----------|-------|-------|
| 1 | **ELO History Chart** | Profile | Web có biểu đồ ELO rất đẹp + chi tiết, Flutter hoàn toàn thiếu |
| 2 | **Achievements** | Profile | Hiển thị thành tích giải đấu (quán quân/á quân/hạng ba) |
| 3 | **Tournament Registration Flow** | Tournament | Thiếu doubles registration, withdraw, team creation |
| 4 | **Embedded leaderboard padding** | Rankings | 148px top padding cứng — vỡ layout trên thiết bị lạ |

### P1 — Nên sửa
| # | Tính năng | Trang |
|---|-----------|-------|
| 5 | **Prizes tab** trong tournament detail | Tournament |
| 6 | **Matches tab** trong tournament detail | Tournament |
| 7 | **User search toàn hệ thống** trên leaderboard | Rankings |
| 8 | **5 tabs profile** (thêm achievements, matches, elo) | Profile |
| 9 | **Match history** trong profile | Profile |
| 10 | **ELO badges** trên match cards | Match List |
| 11 | **Viewer/Cheer count** trên match | Match List |
| 12 | **Phân trang** tournament list | Home |
| 13 | **Refactor file quá lớn** (>1000 dòng) | All pages |
| 14 | **Community discovery** integration | Home |
| 15 | **Withdraw from tournament** | Tournament |

### P2 — Nice to have
| # | Tính năng | Trang |
|---|-----------|-------|
| 16 | Social share (Zalo/Facebook) | Tournament |
| 17 | Advanced filters (region, district, content type, ELO) | Home/Tournament |
| 18 | Report violation button | Tournament |
| 19 | Skeleton loading thay vì spinner | All pages |
| 20 | Light mode toggle consistency | All pages |
| 21 | SEO Metadata | Tournament |
| 22 | Verification ticket system | Profile |
| 23 | Match round labels | Match List |

---

## SO SÁNH NHANH

| Tiêu chí | Flutter App | Web Frontend |
|----------|-------------|--------------|
| Tổng số features (5 pages) | ~28 features | ~42 features |
| UI quality | Tốt (dark theme premium) | Rất tốt (responsive, nhiều component) |
| Loading states | Spinner cơ bản | Skeleton + spinner |
| Error handling | Cơ bản (retry button) | Tốt (error boundary + retry) |
| API integration | Đầy đủ endpoints | Đầy đủ endpoints |
| File organization | Theo feature (tốt) | Theo route (tốt) |
| Code splitting | File lớn (>1000 dòng) | Component nhỏ hơn |
| Animation | Wave header + Carousel | Framer Motion |

---

## KẾT LUẬN

**Điểm mạnh của Flutter app:**
- Live score system rất chi tiết (3274 dòng) với panels cho từng môn
- Bracket view cho Single/Double Elimination và Round Robin
- Payment flow (PayOS, mock gateway, checkout)
- Community clubs (challenges, management, tournaments)
- Dark theme premium design nhất quán
- Notification system + Presence tracking

**Điểm yếu chính so với Web:**
1. **Profile thiếu nhiều**: Chỉ 2/5 tabs, thiếu ELO chart, achievements, match history
2. **Tournament detail thiếu**: Không có Prizes tab, Matches tab, registration flow đầy đủ
3. **Match list thiếu chiều sâu**: ELO badges, viewer count, round labels
4. **Leaderboard search hạn chế**: Chỉ search trong top 100 thay vì toàn hệ thống
5. **Code maintainability**: Nhiều file >1000 dòng cần được tách nhỏ
