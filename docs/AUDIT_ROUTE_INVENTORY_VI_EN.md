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
| Home | `/home` | HomeScreen, ExploreTab, MatchExploreCard, RecentCompletedMatches | Public/auth behavior and initial tab | Đã audit Explore; HomeScreen tổng thể còn một phần / Explore audited; HomeScreen overall remains partial |
| QR | `/scan-qr` | QR scanner | Camera permission and public flow | Chưa audit đầy đủ |
| Tournament public | `/intro/:id`, `/tournament/:id`, `/tournaments/:id` | TournamentIntroScreen | Public data and invalid ID | Đã audit shell và nội dung chính / Shell and main content audited |
| Tournament public live | `/live-matches/:id`, `/live/:matchId` | LiveMatchScreen, viewer LiveScoreScreen | Public viewer versus referee controls | Đã audit phần chính / Main paths audited; deeper role-flow follow-up remains |
| Tournament create | `/tournaments/create`, `/tournament/create`, `/tournament-create` | CreatePublicQuickTournamentScreen | Auth and duplicate aliases | Chưa audit đầy đủ |
| Tournament admin | `/admin/tournament/:id` and children | Detail, teams, add/edit team, bracket, tokens, match, draw | Admin/referee/tournament ownership | Chưa audit đầy đủ |
| Admin | `/admin/clubs`, `/admin/change-requests`, `/admin/disputes`, `/admin/transactions`, `/admin/verification` | Admin management screens | Admin only | Chưa audit đầy đủ |
| Referee/viewer | `/referee`, `/referee/match/:matchId`, `/referee/invites`, `/viewer` | Bracket, live score, invites | Referee/viewer role and tournament ID | Chưa audit đầy đủ |
| Community | `/club-create`, `/club/create`, `/club/:id`, `/communities/:id`, `/clubs/:id` | Create/detail club | Public detail versus authenticated management | Đã audit một phần / Partially audited; detail and management screens remain |
| Community children | `/club/:id/chat`, `/club/:id/create-tournament`, `/club/:id/edit`, `/club/:id/manage`, `/club/:id/tournaments` | Club chat, create/edit/manage/tournaments | Owner/member roles | Chưa audit đầy đủ |
| Community aliases | `/communities/:id/chat`, `/communities/:id/...` | Same club flows through alias | Alias parity and access consistency | Chưa audit đầy đủ |
| Social | `/admin/social/:id`, `/admin/chat/:id`, `/admin/social/:id` variants | CommunitySocialScreen, ClubChatScreen | Community membership and target post | Chưa audit đầy đủ |
| Profile | `/profile`, `/profile/edit`, `/profile/settings`, `/profile/change-password`, `/profile/elo`, `/profile/user/:id` | Profile, settings, password, ELO, user profile | Auth, own profile versus public profile | Auth/profile/settings/user-profile audited; edit/ELO follow-up |
| Registration | `/register/:id`, `/register/:id/doubles`, `/register/:id/team` | Singles/doubles/team registration | Invite, division, participant and team-size validation | Chưa audit đầy đủ |
| Join | `/join/:inviteCode`, `/join-team`, `/lite-join/:inviteCode`, `/lite/tournaments/join/:inviteCode` | Invite join and lite join | Public invite validity and safe fallback | Chưa audit đầy đủ |
| Lite tournament | `/lite-pairing/:id`, `/lite-manage/:id`, `/lite/tournaments/:id/manage` | Pairing and management | Organizer access and alias parity | Chưa audit đầy đủ |
| Series | `/series`, `/series/:slug` | Series list/detail | Public data and invalid slug | Chưa audit đầy đủ |
| Matches | `/matches` | MatchesListScreen | Auth and filter state | Đã audit một phần / Partially audited; dead-code cleanup verified |
| Chat | `/chat`, `/chat/:id` | Chat list/detail | Auth, room membership and null query params | Chat detail đã audit / Chat detail audited; broader list/room-flow follow-up remains |
| Dashboard | `/dashboard` | DashboardScreen | Auth/role access | Chưa audit đầy đủ |
| Notifications | `/notifications` | NotificationScreen | Auth and read state | Đã audit màn hình / Screen audited; provider/API follow-up remains |
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

| `/home` — Explore sections | Public Explore journey remains available; tournament and match navigation preserves the existing route contracts. | Reviewed provider-driven live, completed, upcoming, loading, error, and empty branches. Match-card cheer and share actions remain guarded by existing async lifecycle checks. | ExploreTab and `LiveTournamentWithMatchesCard` now source status, bracket, court, bye, action, share, and recent-results text from synchronized VI/EN ARB. `dart format` and focused `flutter analyze --no-pub` passed with **No issues found** for both changed Dart files; `git diff --check` reported no whitespace errors. The parent HomeScreen remains partially audited because of its legacy size and diagnostics. |

### Phase 4 records / Bản ghi Phase 4

| Route / Route | Access & redirect / Quyền và redirect | Data and safety / Dữ liệu và an toàn | Localization and verification / Ngôn ngữ và xác minh |
|---|---|---|---|
| `/chat`, `/chat/:id` | Chat detail remains behind the existing router/session contract; room ID and participant access are consumed from the route/provider flow. | Typed socket callbacks no longer use redundant runtime type checks; current-user lookup follows the non-null provider contract; message/media loading and send/reaction branches retain lifecycle guards. Targeted analyzer passed with **No issues found** for `chat_detail_screen.dart`. | Visible chat labels were reviewed against the existing localization surface; broader chat-list and room-permission verification remains pending. |
| `/notifications` | Authenticated notification route; opening the screen refreshes page 1, community invites, and unread badge state. | Infinite-scroll loading uses a guarded in-flight flag; invite actions validate IDs, mark notifications read, invalidate dependent providers, and guard `mounted` before UI feedback. Loading, empty, filtered-empty, error/retry, and pagination states were reviewed. | The handled-invite badge now uses synchronized `notification_inviteHandled` VI/EN ARB. Focused analyzer passed with **No issues found** for `notification_screen.dart`. |
| `/profile/elo` and ranking surfaces | Ranking detail consumes the requested user/profile data through the existing authenticated/public profile flow; no route redirect behavior was changed. | Loading/error, ELO summary, stats, recent matches, and empty states were reviewed. `RankingRow` and `ClubRankingWidget` preserve ranking/filter behavior while removing a nullable doubles-format risk. | Ranking detail, reusable ranking row, and club-ranking header/filter/fallback/empty/error strings now use synchronized VI/EN ARB. Focused analyzers passed with **No issues found** for the changed ranking widgets/screens. Full route-level profile-ELO verification remains pending. |
| Community ranking component | `ClubRankingWidget` is embedded in community/club surfaces; membership/owner gates remain owned by the parent route and were not broadened. | Ranking loading, fetch fallback, filter, search, empty/error, podium, and list states were reviewed without changing API contracts. | Team/member/unranked fallbacks and all visible ranking controls/states now use ARB. Parent `/club/:id` and `/communities/:id` access/management flows still require separate verification. |
| `/club/:id`, `/communities/:id`, `/clubs/:id` | Club detail accepts the route `clubId`; unauthenticated viewers remain read-only while membership and role state are loaded through the existing community provider/repository flow. Alias parity and child management redirects were not changed. | Membership, notification preference, follow/favorite, tournament filters, social settings, gallery, ranking, and empty/error branches were reviewed. The uncommitted user route was not overwritten. Focused analyzer baseline reports 15 infos: 12 brace-style items, 2 async-context items, and 2 unnecessary-underscore items. | The route still contains hardcoded notification-preference labels and requires a separate localization patch after protecting the user’s uncommitted changes. Route is therefore **partially audited / audit partiel**. |
| `/club-invites` | Authenticated invite-management screen; back navigation safely falls back to `/profile` when no previous route exists. | Provider-driven loading, pending-only filtering, refresh, empty, error/retry, image fallback, accept/decline actions, already-member handling, provider invalidation, and `mounted` guards were reviewed. | Title, inviter metadata, pending badge, action labels, success/error feedback, and empty/error/retry states now use synchronized VI/EN ARB. `dart format` and focused analyzer passed with **No issues found** for `club_invites_screen.dart`. |
| `/club/:id/tournaments` | Club tournament list receives `clubId` through the existing route and keeps the existing create/manage navigation contracts. The add action exposes Lite, Web quick-create, and advanced Web flows. | Provider handles loading, empty, refresh, and error states; tournament config parsing safely determines Lite mode; date parsing falls back to an empty date; external Web launch and clipboard feedback were reviewed. | List labels, type sheet, Lite/Web/advanced descriptions, dialog actions, and copied-link feedback now use synchronized VI/EN ARB. Focused analyzer passed with **No issues found** for `club_tournaments_screen.dart`. |
| `/communities/:id/social`, `/admin/social/:id` variants | Community social screen consumes `communityId`, `communityName`, optional header, and optional target post; membership and platform-admin checks control posting, tag management, moderation, and chat access. | Initial/load-more/refresh, target-post scrolling, provider-backed social settings, feed error/empty/loading, delete confirmation, post deletion, and mounted guards were reviewed. Focused analyzer passed with **No issues found**. The uncommitted user file was not modified. | Existing social route still has hardcoded notice, delete-dialog, tooltip, and feedback strings; localization patch remains pending to avoid overwriting the user’s uncommitted social changes. |
| `/create-club` | Authenticated creation form; the screen submits through the existing community API and redirects to `/club/:id` only after a successful response. | Form validation, province/ward auto-detection debounce, image-picker/upload lifecycle, category resolution, loading state, API failure feedback, controller disposal, and mounted guards were reviewed. Focused analyzer passed with **No issues found** for `create_club_screen.dart`. | The form still contains many hardcoded Vietnamese labels, hints, validation messages, upload/source-picker labels, and join-policy text. A dedicated synchronized ARB patch is pending to avoid mixing a large form change with the already-verified route batches. |
| `/club/:id/create-tournament` | Authenticated club-scoped Lite tournament creation receives `clubId` and posts to `/tournaments/lite`; successful creation invalidates club providers and opens the success/manage flow. | Form validation, club-sport mapping, optional date and recurring schedule handling, API response parsing, loading/failure feedback, date/time picker guards, provider invalidation, and controller disposal were reviewed. Focused analyzer passed with **No issues found** for `create_club_tournament_screen.dart`. | The form still contains hardcoded Vietnamese labels, picker text, recurring schedule options, validation/errors, success-sheet actions, and share/copy feedback. A dedicated ARB patch is pending because the screen is large and behavior-rich. |
| `/club/:id/edit` | Club-management edit route receives `clubId`; deep-link back navigation safely falls back to the club detail route when no stack exists. | Provider loading/error/data branches, one-time form initialization, image picker/upload, category resolution, region validation, save/update invalidation, mounted guards, controller disposal, and image fallback were reviewed. Removed redundant image error-builder parameters; focused analyzer now reports **No issues found**. | The screen still has hardcoded Vietnamese edit labels, upload-source labels, validation messages, privacy/join-policy text, and save feedback. A separate ARB patch remains pending. |

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
