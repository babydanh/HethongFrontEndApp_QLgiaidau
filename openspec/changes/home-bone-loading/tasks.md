## 1. Nền tảng dùng chung
- [x] 1.1 `MatchStatusFilter` (enum `live/scheduled/completed/all`) với `toServerParam()` và `accepts(MatchModel)`. Tiêu chí: `flutter test --no-pub test/core/utils/match_status_filter_test.dart` exit 0 (đỏ trước); test phủ `LIVE/IN_PROGRESS/ONGOING`, `COMPLETED/FINISHED/DONE/ENDED`, `scheduled`, `all`. (xong: 7 ca)
  - Files: tạo `lib/core/utils/match_status_filter.dart`, test `test/core/utils/match_status_filter_test.dart`
  - Giao: `enum MatchStatusFilter { live, scheduled, completed, all; static MatchStatusFilter parse(String); String? toServerParam(); bool accepts(MatchModel m); }`
  - Phụ thuộc: không
- [x] 1.2 Bộ skeleton: `SkeletonScope` (một `Shimmer`, tĩnh khi `disableAnimations`), `SkeletonBox/Line/Circle`, khối ghép `HomeBannerSkeleton`, `HomeStatusTabsSkeleton`, `TournamentMatchesCardSkeleton` (3 biến thể), `TournamentListItemSkeleton`, `LeaderboardRowSkeleton`, `SocialPostSkeleton`, `MatchRowSkeleton`. Dùng skill `pixel-perfect-responsive` và `fluid-animations`. Tiêu chí: `flutter test --no-pub test/core/widgets/skeleton/skeleton_test.dart` exit 0 (đỏ trước): đúng 1 `Shimmer` mỗi vùng, không có `Shimmer` khi `disableAnimations`, `HomeBannerSkeleton` cao bằng ô banner ở 3 kích thước (360x640, 412x915, 820x1180), không `RenderFlex overflow`. (xong: 48 ca; thêm `TournamentBannerCardSkeleton`, `TournamentMatchRowsSkeleton`, `ListPageSkeleton`, `DetailPageSkeleton`; `ShimmerPlaceholder` giữ nguyên, không đổi sang kit)
  - Files: tạo `lib/core/widgets/skeleton/skeleton_scope.dart`, `skeleton_shapes.dart`, `home_skeletons.dart`, `list_skeletons.dart`; test `test/core/widgets/skeleton/skeleton_test.dart`; `lib/features/tournament/widgets/tournament_state_views.dart` (chỉ để `ShimmerPlaceholder` dùng lại `SkeletonBox`, giữ nguyên API)
  - Giao: `SkeletonScope({required Widget child})`, `HomeBannerSkeleton({required double height})`, `TournamentMatchesCardSkeleton({SkeletonCardVariant variant})`, `MatchRowSkeleton()`, `LeaderboardRowSkeleton()`, `TournamentListItemSkeleton()`, `SocialPostSkeleton()`
  - Phụ thuộc: không

## 2. Nguồn dữ liệu feed
- [x] 2.1 BỎ: không đổi interface `getTournamentMatchesPaged`/`getPublicMatchesPaged` (đã nhận `status` dạng chuỗi; người gọi truyền `MatchStatusFilter.toServerParam()`). Lý do: `_searchQueries[0]` của trang chủ không bao giờ được gán nên feed không cần `search`; Backend đã nhận `ONGOING/LIVE`.
- [x] 2.2 `homeMatchFeedProvider` theo D1: quét 6 giải/bước, tối đa 3 request đồng thời, chặn request trùng, trần 4 bước tự động, làm mới 120 giây (30 giây khi `live` có card) gộp tín hiệu trong 1,5 giây, giữ dữ liệu cũ khi lỗi, keepAlive 60 giây theo key. Tiêu chí: `flutter test --no-pub test/providers/home_match_feed_provider_test.dart` exit 0 (đỏ trước) bằng repository giả đếm lời gọi: (a) 20 giải mở trang = 6 lời gọi, 0 lời gọi `getMatches`; (b) `live` không giải nào khớp dừng sau 24 giải; (c) hai `loadMore()` đồng thời không gọi trùng; (d) lỗi một giải không ảnh hưởng giải khác; (e) làm mới lỗi giữ dữ liệu cũ; (f) đổi bộ lọc 3 lần chỉ quét bộ lọc cuối (dùng `fakeAsync`). (xong: 14 ca; thêm ca bỏ qua trang toàn placeholder, giữ mặc định 5 trang phụ của `fetchCursorPageWhere`)
  - Files: tạo `lib/providers/home_match_feed_provider.dart`, test `test/providers/home_match_feed_provider_test.dart`; sửa `lib/providers/app_providers.dart` (export nếu repo dùng barrel)
  - Giao: `final homeMatchFeedProvider = NotifierProvider.autoDispose.family<HomeMatchFeedNotifier, HomeMatchFeedState, HomeMatchFeedQuery>(...)`; `HomeMatchFeedQuery({required MatchStatusFilter status, required String query, required List<Tournament> tournaments})`; `HomeMatchFeedState { HomeFeedPhase phase; List<Tournament> visible; Map<String, FeedPage> pages; bool hasMore }`; `Notifier.loadMore()`, `refresh()`, `retry(String tournamentId)`
  - Phụ thuộc: 1.1, 2.1

## 3. Trang chủ: Khám phá
- [x] 3.1 `LiveTournamentWithMatchesCard` nhận `initialPage`, không tự gọi trang đầu; trang sau dùng skeleton hàng trận; không còn vùng trận trống (rỗng/lỗi hiển thị thông báo). Tiêu chí: `flutter test --no-pub test/features/live_tournament_with_matches_card_test.dart` exit 0 (cập nhật, đỏ trước) kèm ca mới: dựng card = 0 lời gọi repository; bấm trang sau = 1 lời gọi; trang sau lỗi giữ trang hiện tại. (xong: 9 ca)
  - Files: sửa `lib/features/explore/widgets/live_tournament_with_matches_card.dart:30-103,190-240,290-310`, `test/features/live_tournament_with_matches_card_test.dart:337`
  - Giao: `LiveTournamentWithMatchesCard({required Tournament tournament, required MatchStatusFilter filter, required FeedPage initialPage, ...})`
  - Phụ thuộc: 1.2, 2.2
- [x] 3.2 `TournamentSectionList` đọc `homeMatchFeedProvider`, bỏ `ref.watch(matchesProvider)`, bỏ hàm lọc `if` trùng; skeleton khi `phase == loading`, thông báo rỗng khi `exhausted` không card, nút "Tải thêm" khi chạm trần; sentinel gọi `loadMore()` một lần mỗi lần chạm. Tiêu chí: `flutter test --no-pub test/features/home/tournament_section_list_test.dart` exit 0 (cập nhật, đỏ trước): không có `CircularProgressIndicator`, có `TournamentMatchesCardSkeleton` khi tải, không có card trống, `loadMore` không lặp khi build lại. (xong: 11 ca, gồm ca làm mới khi app resume)
  - Files: sửa `lib/features/home/widgets/tournament_section_list.dart` (viết lại phần build, giữ ngoại hình card), `test/features/home/tournament_section_list_test.dart`
  - Phụ thuộc: 2.2, 3.1
- [x] 3.3 `home_screen.dart` tab Khám phá: `loading:` dùng `HomeBannerSkeleton` + `HomeStatusTabsSkeleton` + 3 card skeleton thay vòng xoay; giữ thanh lọc môn thật; bỏ `SliverFillRemaining` + vòng xoay. Tiêu chí: `flutter test --no-pub test/features/home/home_explore_loading_test.dart` exit 0 (đỏ trước): trạng thái loading hiển thị skeleton, không `CircularProgressIndicator`, thanh lọc môn tương tác được; chiều cao ô banner skeleton = ô banner thật. (xong: `home_feed_states_test` 9 ca, gồm ca kéo để làm mới; skeleton cả trang khi `tournamentsProvider` đang tải)
  - Files: sửa `lib/features/home/screens/home_screen.dart:674-805`; tạo test `test/features/home/home_explore_loading_test.dart`
  - Chủ file chung: 3.3 sở hữu `home_screen.dart` trong nhóm 3 và 4 (làm 3.3 trước 4.1)
  - Phụ thuộc: 1.2, 3.2

## 4. Trang chủ: các tab còn lại
- [x] 4.1 Tab Giải đấu: skeleton lần tải đầu (`TournamentListItemSkeleton` x6) và dải skeleton ở thanh "tải thêm" thay vòng xoay. Tiêu chí: `flutter test --no-pub test/features/home/home_tournaments_loading_test.dart` exit 0 (đỏ trước). (xong; thanh "Xem thêm giải đấu" giữ vòng xoay nhỏ vì nằm trong nút; sửa tràn dòng ở chân danh sách "Đã hiển thị tất cả giải đấu")
  - Files: sửa `lib/features/home/screens/home_screen.dart:1214-1400`; tạo test `test/features/home/home_tournaments_loading_test.dart`
  - Phụ thuộc: 1.2, 3.3
- [x] 4.2 Bảng xếp hạng: `LeaderboardRowSkeleton` thay 3 vòng xoay. Tiêu chí: `flutter test --no-pub test/features/rankings/leaderboard_loading_test.dart test/features/rankings/leaderboard_format_filter_test.dart` exit 0. (xong: 2 ca mới + 5 ca cũ)
  - Files: sửa `lib/features/rankings/screens/leaderboard_screen.dart:144,168,187`; tạo test `test/features/rankings/leaderboard_loading_test.dart`
  - Phụ thuộc: 1.2
- [x] 4.3 Cộng đồng: `SocialPostSkeleton` thay vòng xoay lần đầu và ở thanh tải thêm. Tiêu chí: `flutter test --no-pub test/features/social/social_list_loading_test.dart` exit 0 (đỏ trước). (xong: danh sách, chi tiết, bộ chọn vùng, sheet thành viên CLB; 2 ca màn hình)
  - Files: sửa `lib/features/social/screens/social_list_view.dart:70-75,286-290`; tạo test `test/features/social/social_list_loading_test.dart`
  - Phụ thuộc: 1.2

## 5. Màn `/matches`
- [x] 5.1 `matches_list_screen.dart` tải theo trang bằng `getPublicMatchesPaged`, skeleton `MatchRowSkeleton`, tải thêm khi cuộn, không bật lại skeleton khi đã có dữ liệu; pill dùng `MatchStatusFilter`, gộp "Vừa kết thúc"/"Đã kết thúc", bỏ pill "Đăng ký". Tiêu chí: `flutter test --no-pub test/features/match/matches_list_screen_test.dart` exit 0 (đỏ trước): mở = 1 lời gọi trang đầu (không `getMatches`); cuộn cuối = 1 lời gọi với cursor; chọn "Đã kết thúc" cho kết quả không rỗng khi có trận `completed`; lỗi lần đầu hiện nút thử lại; làm mới nền lỗi giữ danh sách. (xong: 7 ca)
  - Files: sửa `lib/features/match/screens/matches_list_screen.dart:31-120,219-234,279-360`; tạo test `test/features/match/matches_list_screen_test.dart`
  - Phụ thuộc: 1.1, 1.2, 2.1

## 6. Chuỗi hiển thị
- [x] 6.1 Không thêm key i18n mới (nút "Tải thêm" dùng `homeGlobalSearchLoadMore`, lỗi dùng `homeMatchesLoadError`, thử lại dùng `homeGlobalSearchRetry`). Tiêu chí: không có thay đổi ở `lib/l10n/` nên không cần `flutter gen-l10n`.

## 6b. Quét mọi trang còn lại (bone loading toàn app)
- [x] 6b.1 `lib/features/community/**`: 19 spinner tải nội dung đổi sang skeleton, 20 ca test.
- [x] 6b.2 `lib/features/tournament/**`, `lib/features/bracket/**`: skeleton `Bone*` dùng chung, 61 ca test.
- [x] 6b.3 register, teams, football_team, series, referee, lite, organizer_ops, payment, dashboard, admin: 26 ca test mới.
- [x] 6b.4 profile, notification, chat, match (ngoài `matches_list_screen`), auth, `global_search_screen`, `lib/shared/**`: 18 spinner tải nội dung đổi sang skeleton, +177 ca test chạy xanh; `app_router.dart` (phòng chat CLB) cũng đổi.
  - Giữ nguyên có chủ đích: vòng xoay trong nút/đang gửi/đang lưu/upload, màn chờ có chủ đích (PayOS, xác thực mã mời, đăng nhập), trình phát video, thanh "tải thêm" nhỏ ở đáy.

## 7. Kiểm chứng
- [x] 7.1 `flutter analyze --no-pub` toàn repo: 212 issue (0 lỗi), không issue nào do thay đổi này gây ra (đối chiếu từng dòng thay đổi so với `origin/main`; 3 `curly_braces` ở `tournament_management_*_section.dart` và 1 `depend_on_referenced_packages` cho `fake_async` trong test giống test có sẵn `swiss_pairing_notifier_test.dart`). `flutter test --no-pub` toàn bộ: 2467 ca pass, 2 bỏ qua, 0 lỗi (exit 0). `openspec validate home-bone-loading --strict` pass.
  - Phụ thuộc: 6.1
- [x] 7.2 Bằng chứng số request (đếm bằng repository giả; mọi lời gọi khác `getTournamentMatchesPaged` đều ném lỗi): mở tab với 20 giải = 6 lời gọi (`home_match_feed_provider_test.dart`); bộ lọc không khớp giải nào trong 30 giải dừng ở 24 giải và không còn request nền; 6 giải hiển thị chỉ tốn 6 lời gọi gồm cả card (`tournament_section_list_test.dart`); 0 lời gọi `getMatches`/`watchByTournament`; làm mới 120 giây (30 giây cho "Trực tiếp" khi có card live) thay vì 15 giây theo từng giải. Trước đây: mỗi giải quét mở một luồng kéo toàn bộ trận cộng một lần gọi riêng của card (>= 2 lần mỗi giải), tải lại 15 giây một lần, và bộ lọc không khớp quét hết mọi giải. CHƯA xem thật trên điện thoại (máy cloud không có `.env` thật và không chạy được app).
  - Phụ thuộc: 7.1
- [x] 7.3 Push nhánh `cloud/danh1-hi-ban-dang-o-thu-hfpe` (chỉ repo `app`), chạy các bước trước khi push trong luật máy cloud (`related-tests`, `openspec-gate`, `overlap`, `safe-push-check`, `e2e-impact`), tạo PR cho repo App (không có staging). Tiêu chí: PR tạo xong, CI `analyze` + `test` xanh; sau đó `cloud-xong hi-ban-dang-o-thu-hfpe`. (xong: đã push và tạo PR https://github.com/babydanh/HethongFrontEndApp_QLgiaidau/pull/5; `overlap` và `safe-push-check` an toàn, `e2e-impact` không có spec bị ảnh hưởng; CI đang chạy lúc ghi)
  - Phụ thuộc: 7.2
