# Flutter Page Audit Inventory — VI/EN

## Mục tiêu / Objective

Tài liệu này là danh mục kiểm tra từng route và màn hình của app Flutter. Mỗi trang sẽ được kiểm tra theo cùng một chuẩn: quyền truy cập và redirect, tham số route, trạng thái loading/empty/error, API và repository, null-safety, async `BuildContext`, Riverpod lifecycle, chuỗi giao diện VI/EN, navigation/back behavior, accessibility, analyzer và test.

> Nguyên tắc: không sửa hàng loạt khi chưa hiểu luồng dữ liệu. Mỗi nhóm thay đổi phải được analyzer riêng, kiểm tra diff và cập nhật knowledge graph theo `docs/SKILLS.md`.

## Trạng thái tổng quan / Overall status

| Hạng mục / Area | Trạng thái / Status | Ghi chú / Notes |
|---|---|---|
| App startup and security | Đã audit một phần / Partially audited | Đã bỏ global certificate bypass. |
| Localization VI/EN | Đang triển khai / In progress | Settings có language card và lưu locale. Các màn hình khác còn chuỗi cứng. |
| Route inventory | Đã lập / Inventoried | Danh sách bên dưới bao phủ router hiện tại. |
| Full analyzer | Còn tồn tại diagnostics / Diagnostics remain | Baseline sau các đợt gần nhất: 228 warning/info, chưa ghi nhận compile error trong báo cáo. |
| Test suite | Bị chặn bởi môi trường / Environment-blocked | Windows runner báo thiếu `%PROGRAMFILES(X86)%`; cần xác nhận lại trên môi trường Flutter chuẩn. |

## Route inventory / Danh mục route

| Nhóm / Group | Route(s) | Màn hình / Screen | Quyền cần kiểm tra / Access to verify | Audit status |
|---|---|---|---|---|
| Auth | `/`, `/login`, `/login-loading` | Splash, login/register, loading | Public; authenticated redirect | Chưa audit đầy đủ |
| Auth recovery | `/forgot-password`, `/reset-password` | Forgot/reset password | Public; token validation | Chưa audit đầy đủ |
| Home | `/home` | HomeScreen | Public/auth behavior and initial tab | Chưa audit đầy đủ |
| QR | `/scan-qr` | QR scanner | Camera permission and public flow | Chưa audit đầy đủ |
| Tournament public | `/intro/:id`, `/tournament/:id`, `/tournaments/:id` | TournamentIntroScreen | Public data and invalid ID | Chưa audit đầy đủ |
| Tournament public live | `/live-matches/:id`, `/live/:matchId` | LiveMatchScreen, viewer LiveScoreScreen | Public viewer versus referee controls | Chưa audit đầy đủ |
| Tournament create | `/tournaments/create`, `/tournament/create`, `/tournament-create` | CreatePublicQuickTournamentScreen | Auth and duplicate aliases | Chưa audit đầy đủ |
| Tournament admin | `/admin/tournament/:id` and children | Detail, teams, add/edit team, bracket, tokens, match, draw | Admin/referee/tournament ownership | Chưa audit đầy đủ |
| Admin | `/admin/clubs`, `/admin/change-requests`, `/admin/disputes`, `/admin/transactions`, `/admin/verification` | Admin management screens | Admin only | Chưa audit đầy đủ |
| Referee/viewer | `/referee`, `/referee/match/:matchId`, `/referee/invites`, `/viewer` | Bracket, live score, invites | Referee/viewer role and tournament ID | Chưa audit đầy đủ |
| Community | `/club-create`, `/club/create`, `/club/:id`, `/communities/:id`, `/clubs/:id` | Create/detail club | Public detail versus authenticated management | Chưa audit đầy đủ |
| Community children | `/club/:id/chat`, `/club/:id/create-tournament`, `/club/:id/edit`, `/club/:id/manage`, `/club/:id/tournaments` | Club chat, create/edit/manage/tournaments | Owner/member roles | Chưa audit đầy đủ |
| Community aliases | `/communities/:id/chat`, `/communities/:id/...` | Same club flows through alias | Alias parity and access consistency | Chưa audit đầy đủ |
| Social | `/admin/social/:id`, `/admin/chat/:id`, `/admin/social/:id` variants | CommunitySocialScreen, ClubChatScreen | Community membership and target post | Chưa audit đầy đủ |
| Profile | `/profile`, `/profile/edit`, `/profile/settings`, `/profile/change-password`, `/profile/elo`, `/profile/user/:id` | Profile, settings, password, ELO, user profile | Auth, own profile versus public profile | Settings partially audited |
| Registration | `/register/:id`, `/register/:id/doubles`, `/register/:id/team` | Singles/doubles/team registration | Invite, division, participant and team-size validation | Chưa audit đầy đủ |
| Join | `/join/:inviteCode`, `/join-team`, `/lite-join/:inviteCode`, `/lite/tournaments/join/:inviteCode` | Invite join and lite join | Public invite validity and safe fallback | Chưa audit đầy đủ |
| Lite tournament | `/lite-pairing/:id`, `/lite-manage/:id`, `/lite/tournaments/:id/manage` | Pairing and management | Organizer access and alias parity | Chưa audit đầy đủ |
| Series | `/series`, `/series/:slug` | Series list/detail | Public data and invalid slug | Chưa audit đầy đủ |
| Matches | `/matches` | MatchesListScreen | Auth and filter state | Chưa audit đầy đủ |
| Chat | `/chat`, `/chat/:id` | Chat list/detail | Auth, room membership and null query params | Chưa audit đầy đủ |
| Dashboard | `/dashboard` | DashboardScreen | Auth/role access | Chưa audit đầy đủ |
| Notifications | `/notifications` | NotificationScreen | Auth and read state | Chưa audit đầy đủ |
| Football | `/football-teams` | FootballTeamsScreen | Team ownership and query team ID | Chưa audit đầy đủ |
| Payment | `/payments`, `/payment/checkout`, `/payment/payos-verify`, `/payment/result` | Payment flow | Auth, amount/order integrity and callback safety | Chưa audit đầy đủ |
| Club invites | `/club-invites` | ClubInvitesScreen | Auth and invite actions | Chưa audit đầy đủ |

## Audit order / Thứ tự thực hiện

1. **Auth, Profile, Settings:** establish locale, session, and permission baseline.
2. **Home, Explore, Tournament, Match:** verify the main user journey and data states.
3. **Community, Chat, Ranking, Notifications:** address the largest analyzer and async-risk surface.
4. **Registration, Lite, Payment, Admin/Referee:** verify route parameters, role gates, and transaction-sensitive flows.
5. **Full verification:** rerun analyzer, targeted tests where available, whitespace check, and produce a page-by-page report.

## Page checklist / Checklist cho từng trang

| Check | VI question | EN question |
|---|---|---|
| Route | Route có đúng tham số và redirect không? | Are route parameters and redirects correct? |
| Permission | Role nào được vào? Có lọt quyền không? | Which roles may enter, and is access constrained? |
| Data | Loading, empty, error, retry đã đủ chưa? | Are loading, empty, error, and retry states complete? |
| Safety | Có null-unsafe, async context hoặc dispose risk không? | Are null, async-context, and dispose risks handled? |
| Localization | Chuỗi hiển thị đã qua ARB chưa? | Are visible strings sourced from ARB localization? |
| UX | Back, refresh, keyboard, accessibility có ổn không? | Do back, refresh, keyboard, and accessibility behave correctly? |
| Verification | Analyzer/test/diff đã chạy chưa? | Were analyzer, tests, and diff checks run? |
