# Flutter Page Audit Inventory — VI/EN

## Mục tiêu / Objective

Tài liệu này là danh mục kiểm tra từng route và màn hình của app Flutter. Mỗi trang sẽ được kiểm tra theo cùng một chuẩn: quyền truy cập và redirect, tham số route, trạng thái loading/empty/error, API và repository, null-safety, async `BuildContext`, Riverpod lifecycle, chuỗi giao diện VI/EN, navigation/back behavior, accessibility, analyzer và test.

> Nguyên tắc: không sửa hàng loạt khi chưa hiểu luồng dữ liệu. Mỗi nhóm thay đổi phải được analyzer riêng, kiểm tra diff và cập nhật knowledge graph theo `docs/SKILLS.md`.

## Trạng thái tổng quan / Overall status

| Hạng mục / Area | Trạng thái / Status | Ghi chú / Notes |
|---|---|---|
| App startup and security | Đã audit một phần / Partially audited | Đã bỏ global certificate bypass. |
| Localization VI/EN | Đang triển khai / In progress | Settings, Auth và nhóm Profile đã được chuẩn hóa theo ARB; các nhóm khác còn chuỗi cứng. |
| Route inventory | Đã lập / Inventoried | Danh sách bên dưới bao phủ router hiện tại. |
| Full analyzer | Còn tồn tại diagnostics / Diagnostics remain | Baseline sau các đợt gần nhất: 228 warning/info, chưa ghi nhận compile error trong báo cáo. |
| Test suite | Bị chặn bởi môi trường / Environment-blocked | Windows runner báo thiếu `%PROGRAMFILES(X86)%`; cần xác nhận lại trên môi trường Flutter chuẩn. |

## Route inventory / Danh mục route

| Nhóm / Group | Route(s) | Màn hình / Screen | Quyền cần kiểm tra / Access to verify | Audit status |
|---|---|---|---|---|
| Auth | `/`, `/login`, `/login-loading` | Splash, login/register, loading | Public; authenticated redirect | Chưa audit đầy đủ |
| Auth recovery | `/forgot-password`, `/reset-password` | Forgot/reset password | Public; token validation | Chưa audit đầy đủ |
| Home | `/home` | HomeScreen | Public/auth behavior and initial tab | Đã audit một phần / Partially audited |
| QR | `/scan-qr` | QR scanner | Camera permission and public flow | Chưa audit đầy đủ |
| Tournament public | `/intro/:id`, `/tournament/:id`, `/tournaments/:id` | TournamentIntroScreen | Public data and invalid ID | Đã audit shell và nội dung chính / Shell and main content audited |
| Tournament public live | `/live-matches/:id`, `/live/:matchId` | LiveMatchScreen, viewer LiveScoreScreen | Public viewer versus referee controls | Đã audit phần chính / Main paths audited; deeper role-flow follow-up remains |
| Tournament create | `/tournaments/create`, `/tournament/create`, `/tournament-create` | CreatePublicQuickTournamentScreen | Auth and duplicate aliases | Chưa audit đầy đủ |
| Tournament admin | `/admin/tournament/:id` and children | Detail, teams, add/edit team, bracket, tokens, match, draw | Admin/referee/tournament ownership | Chưa audit đầy đủ |
| Admin | `/admin/clubs`, `/admin/change-requests`, `/admin/disputes`, `/admin/transactions`, `/admin/verification` | Admin management screens | Admin only | Chưa audit đầy đủ |
| Referee/viewer | `/referee`, `/referee/match/:matchId`, `/referee/invites`, `/viewer` | Bracket, live score, invites | Referee/viewer role and tournament ID | Chưa audit đầy đủ |
| Community | `/club-create`, `/club/create`, `/club/:id`, `/communities/:id`, `/clubs/:id` | Create/detail club | Public detail versus authenticated management | Chưa audit đầy đủ |
| Community children | `/club/:id/chat`, `/club/:id/create-tournament`, `/club/:id/edit`, `/club/:id/manage`, `/club/:id/tournaments` | Club chat, create/edit/manage/tournaments | Owner/member roles | Chưa audit đầy đủ |
| Community aliases | `/communities/:id/chat`, `/communities/:id/...` | Same club flows through alias | Alias parity and access consistency | Chưa audit đầy đủ |
| Social | `/admin/social/:id`, `/admin/chat/:id`, `/admin/social/:id` variants | CommunitySocialScreen, ClubChatScreen | Community membership and target post | Chưa audit đầy đủ |
| Profile | `/profile`, `/profile/edit`, `/profile/settings`, `/profile/change-password`, `/profile/elo`, `/profile/user/:id` | Profile, settings, password, ELO, user profile | Auth, own profile versus public profile | Auth/profile/settings/user-profile audited; edit/ELO follow-up |
| Registration | `/register/:id`, `/register/:id/doubles`, `/register/:id/team` | Singles/doubles/team registration | Invite, division, participant and team-size validation | Chưa audit đầy đủ |
| Join | `/join/:inviteCode`, `/join-team`, `/lite-join/:inviteCode`, `/lite/tournaments/join/:inviteCode` | Invite join and lite join | Public invite validity and safe fallback | Chưa audit đầy đủ |
| Lite tournament | `/lite-pairing/:id`, `/lite-manage/:id`, `/lite/tournaments/:id/manage` | Pairing and management | Organizer access and alias parity | Chưa audit đầy đủ |
| Series | `/series`, `/series/:slug` | Series list/detail | Public data and invalid slug | Chưa audit đầy đủ |
| Matches | `/matches` | MatchesListScreen | Auth and filter state | Đã audit một phần / Partially audited; dead-code cleanup verified |
| Chat | `/chat`, `/chat/:id` | Chat list/detail | Auth, room membership and null query params | Chưa audit đầy đủ |
| Dashboard | `/dashboard` | DashboardScreen | Auth/role access | Chưa audit đầy đủ |
| Notifications | `/notifications` | NotificationScreen | Auth and read state | Chưa audit đầy đủ |
| Football | `/football-teams` | FootballTeamsScreen | Team ownership and query team ID | Chưa audit đầy đủ |
| Payment | `/payments`, `/payment/checkout`, `/payment/payos-verify`, `/payment/result` | Payment flow | Auth, amount/order integrity and callback safety | Chưa audit đầy đủ |
| Club invites | `/club-invites` | ClubInvitesScreen | Auth and invite actions | Chưa audit đầy đủ |

## Verified audit records / Bản ghi audit đã xác minh

### Auth routes / Route xác thực

| Route / Route | Access & redirect / Quyền và redirect | Data and safety / Dữ liệu và an toàn | Localization and verification / Ngôn ngữ và xác minh |
|---|---|---|---|
| `/`, `/login`, `/login-loading` | Public entry; authenticated users are redirected through the centralized router. | Google/Apple token flows now guard `mounted` after asynchronous credential calls; loading and error paths were reviewed. | Social-button labels and token-missing messages use ARB. Targeted analyzer passed for the changed Auth files. |
| `/forgot-password`, `/reset-password` | Public recovery flow; reset token is passed through the route contract. | Reset-password flow now checks `mounted` after the API call before presenting UI feedback. | Visible recovery feedback remains localized where touched; a broader Auth string sweep is still pending. |

### Phase 3 records / Bản ghi Phase 3

| Route / Route | Access & redirect / Quyền và redirect | Data and safety / Dữ liệu và an toàn | Localization and verification / Ngôn ngữ và xác minh |
|---|---|---|---|
| `/home` | Central router permits public and authenticated access; the initial tab is managed by HomeScreen state. | Main carousel, provider-driven sections, club/tournament filters, and empty/loading branches were reviewed. No route redirect change was made. | Safe analyzer cleanup applied: wildcard callback parameters, braces, and `withValues`. The very large HomeScreen still has legacy unused helpers/diagnostics; targeted analyzer later stalled at analysis startup, so this route remains partially audited. |
| `/intro/:id`, `/tournament/:id`, `/tournaments/:id` | Public aliases resolve to the tournament intro flow; invalid data uses the shared not-found state and back navigation returns safely to the previous route or Home. | Tournament and division providers expose loading, empty/not-found, error/retry, team, bracket, and gallery branches. Follow/register actions retain authentication checks and mounted guards. | Tournament state widgets, header ranked/unranked badges, date fallback, About-tab contact labels, and image zoom hint now use synchronized VI/EN ARB. Targeted analyzer passed with **No issues found** for the intro screen, banner, and About tab. Legacy banner participant summary remains a separate review item. |
| `/live-matches/:id`, `/live/:matchId` | Router exposes public viewer paths; scoring controls remain separated from viewer paths by screen state and role checks. | LiveScore null-aware chains and async context handling were corrected. Write-only score-animation state and two unreferenced private helpers were removed; behavior of the active viewer/scoring paths was preserved. | LiveScore and the LiveMatch parent/card now use synchronized VI/EN labels for headers, filters, statuses, counts, empty/error/retry states, score placeholders, and card metadata. Targeted analyzer passed with **No issues found** for `live_score_screen.dart`, `live_match_screen.dart`, and `live_match_card_v2.dart`. Deeper role-flow verification remains pending. |
| `/matches` | Route is available through the centralized router; filter state remains in MatchesListScreen. | Confirmed dead null-check and unused local were removed without changing list loading, empty, or error branches. | Targeted cleanup was applied; a broader route verification and visible-string localization sweep remain pending. |

### Profile routes / Route hồ sơ

| Route / Route | Access & redirect / Quyền và redirect | Data and safety / Dữ liệu và an toàn | Localization and verification / Ngôn ngữ và xác minh |
|---|---|---|---|
| `/profile` | Authenticated own-profile screen; unauthenticated state provides a safe login route. | Image picker permission/error branches and upload success feedback were reviewed; async UI updates guard `mounted`. | Login prompt, registration CTA, image-picker actions, permission errors, and upload feedback use ARB. |
| `/profile/settings` | Authenticated settings route with profile, banking, and security tabs. | Locale selection persists through the existing locale provider and shared preferences. | VI/EN language card added; settings tab labels and change-password entry point use ARB. |
| `/profile/change-password` | Authenticated security route. | Validation, API error handling, and post-submit context safety were reviewed. | Title, labels, hints, validators, success/error messages, button, and help text use ARB. |
| `/profile/user/:id` | Public profile route; profile data is loaded by the requested user ID. | Loading shimmer, API error placeholder, empty ranking/match/achievement states, and null-safe profile fields were reviewed. | Tabs, role labels, statistics, achievements, ELO action, share metadata, club-title labels, and match states use ARB. Targeted analyzer passed with no issues. |

> **Current limitation / Giới hạn hiện tại:** `/profile/edit` and `/profile/elo` remain inventoried but require separate screen-level verification. Role data is not present on `UserPublicProfile`, so the public-profile role badge currently uses the existing default-player fallback until the API model exposes a role field.

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
