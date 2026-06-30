# 📊 Trạng thái hiện tại — Flutter App (app_quanly_giaidau)

> Cập nhật: 29/06/2026 — lần 2 (header collapse + nav redesign)

## 🟢 Đã hoàn thiện (UI + API thật)

| Tính năng | File | Ghi chú |
|---|---|---|
| Auth JWT (login/register/Google) | `features/auth/screens/`, `providers/auth_provider.dart` | Gọi NestJS `/auth/mobile/*` |
| Dio client + refresh token | `core/services/dio_client.dart` | Auto-inject Bearer, retry 401 |
| Theme dark/light | `core/config/app_theme.dart`, `providers/theme_provider.dart` | Material3 |
| Router + role-based redirect | `core/router/app_router.dart` | GoRouter, 15+ routes |
| DI & providers | `core/di/*` | Repository, usecase, core providers |
| Home Screen — scroll header collapse + search bar fade | `features/home/screens/home_screen.dart` | ✅ Scroll-driven: 248px→80px, search bar hiện khi collapse, logo thu nhỏ |
| Bottom Nav — profile avatar thay FAB | `core/widgets/floating_bottom_nav.dart` | ✅ Avatar center, bấm → /profile |
| Header — noti trái + search phải, xoá profile initials | `features/home/screens/home_screen.dart` | ✅ Layout mới |
| Tournament detail | `features/tournament/screens/tournament_detail_screen.dart` | Actions: teams, bracket, tokens, draw, delete |
| Team list + add team | `features/teams/screens/` | CRUD qua API |
| Bracket view | `features/bracket/screens/bracket_view_screen.dart` | graphview, double elim |
| Score input + penalty | `features/match/screens/score_input_screen.dart` | Referee scoring, events, injury, penalty |
| Auto draw | `features/bracket/screens/auto_draw_screen.dart` | Manual + auto draw |
| Live match screen | `features/live/screens/live_match_screen.dart` | List live/upcoming/completed |
| QR scanner | `features/home/screens/qr_scanner_screen.dart` | mobile_scanner |
| Profile | `features/profile/screens/profile_screen.dart` | Edit + change password |
| Settings | `features/home/screens/home_screen.dart` — tab "Cài đặt" | Dark mode toggle |
| Entities & Models | `domain/entities/*`, `data/models/*` | User, Tournament, Team, Match, Token, Ranking |
| Repositories | `data/repositories/api/*` | Gọi NestJS API |
| Use cases | `domain/usecases/*` | Auth + Tournament |
| Bracket generator | `core/utils/bracket_generator.dart` | Single Elimination |
| Draw service | `core/services/draw_service.dart` | Fisher-Yates shuffle |

## 🟡 Có UI nhưng còn sơ sài

| Tính năng | Vấn đề | File |
|---|---|---|
| Create tournament | Chỉ 3 field (tên, môn, thể thức) — thiếu: category, hạng mục, giới tính, phí, bracket config, division | `features/tournament/screens/create_tournament_screen.dart` |
| Token management | Chưa regenerate token, QR share, deactivate | `features/tournament/screens/token_management_screen.dart` |
| Tournament intro | UI cơ bản, thiếu thông tin chi tiết, bảng xếp hạng | `features/tournament/screens/tournament_intro_screen.dart` |
| Add team form | Chưa có UI import Excel/CSV, chưa quản lý roster | `features/teams/screens/add_team_screen.dart` |
| Bracket (Round Robin) | UI cross table có, nhưng chưa tích hợp đầy đủ | `features/bracket/widgets/cross_table_view.dart` |

## 🔴 Chưa có — Mock / Stub / Fake

| Tính năng | Vấn đề | File |
|---|---|---|
| **Leaderboard / Bảng xếp hạng** | **12 users fake cứng**, chưa gọi API thật | `providers/ranking_provider.dart` |
| **User ranking detail** | **Data fake**, không gọi API thật | `providers/ranking_provider.dart` |
| **ELO stats header (Home)** | **Mock số cứng**: `_mockElo = 1340`, `_mockWins = 31`, `Top 142` | `features/home/screens/home_screen.dart` |
| **Notification bell** | **Mock count = 3**, chưa có notification list screen | `features/home/screens/home_screen.dart` |
| **Presence count (online)** | `Stream.value(0)` — chưa có Firebase RTDB | `providers/query_providers.dart` |
| **Import Excel/CSV** | Package có, code parse có, nhưng **chưa có UI import** | `data/repositories/api/api_team_repository.dart` — importTeams tồn tại |
| **Match schedule / calendar** | Chưa có màn hình lịch thi đấu | — |
| **Chat** | Chưa có UI chat | — |
| **Notification center** | Chưa có màn hình danh sách notification | — |
| **Payment** | Chưa có UI payment (VNPay/Momo) | — |
| **Admin dashboard** | Chưa có quản lý giải, thống kê, doanh thu | — |
| **User search** | Chưa có UI tìm kiếm người dùng | — |
| **Invite team member** | Chưa có UI mời thành viên vào team | — |

## 🔴 Chưa có — Realtime / WebSocket

| Tính năng | Vấn đề |
|---|---|
| **Socket.IO live score** | Backend có Socket.IO gateway `/live` nhưng Flutter chưa kết nối — đang dùng HTTP polling 10-15s |
| **Real-time bracket updates** | Bracket không tự cập nhật khi trận kết thúc — cần kéo refresh |
| **Real-time notification** | Chưa push notification từ server |

## 🔴 Chưa có — API Mapping chưa chuẩn

| Vấn đề | Chi tiết |
|---|---|
| **Tournament entity** | `sport`, `format`, `bracketType` là string thuần — không mapping đúng NestJS response (thiếu `matchType`, `tournamentType`, `sportRules`, `tournamentConfig`, `prizes`, `divisions`, `stages`) |
| **Team entity** | Thiếu `tournamentDivisionId`, `teamStatus`, `isPaid`, `registeredBy` |
| **Match entity** | Đang map đơn giản — NestJS trả `scoreDetails` dạng JSON, `sets` cần parse từ `p1SetsWon/p2SetsWon` |
| **Tournament status** | App dùng `draft/registration/drawing/in_progress/completed` nhưng Backend dùng `DRAFT/REGISTRATION_OPEN/IN_PROGRESS/COMPLETED/CANCELLED` |

## 📋 Tổng quan

```
Auth & Profile  ████████████████░░░░  70%
Home/Explore    ████████████████░░░░  75%
Tournament List █████████████░░░░░░░  60%
Create Tourn.   ██████░░░░░░░░░░░░░░  30%
Team Mgmt       ██████████░░░░░░░░░░  45%
Bracket         ██████████████░░░░░░  65%
Match/Scoring   ████████████████░░░░  70%
Rankings        ████░░░░░░░░░░░░░░░░  20%
Import/Export   ████░░░░░░░░░░░░░░░░  15%
Notification    ██░░░░░░░░░░░░░░░░░░  10%
Realtime/Socket ░░░░░░░░░░░░░░░░░░░░   0%
Chat            ░░░░░░░░░░░░░░░░░░░░   0%
Payment         ░░░░░░░░░░░░░░░░░░░░   0%
```

## 🎯 Ưu tiên kế tiếp (gợi ý)

1. **Create Tournament Wizard** — multi-step: info → config → divisions → confirm
2. **Leaderboard thật** — gọi API rankings, bỏ mock
3. **User stats thật** — bỏ mock ELO/wins/rate trong header
4. **Socket.IO** — realtime match updates
5. **Import Excel UI** — preview + confirm
6. **Notification center** — list + realtime
7. **Fix API mapping** — Tournament/Team/Match entity cho đúng NestJS response
