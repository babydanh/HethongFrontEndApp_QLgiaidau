## 1. Nền tảng dùng chung
- [ ] 1.1 `MatchStatusFilter` (enum `live/scheduled/completed/all`) với `toServerParam()` và `accepts(MatchModel)`. Tiêu chí: `flutter test --no-pub test/core/utils/match_status_filter_test.dart` exit 0 (đỏ trước); test phủ `LIVE/IN_PROGRESS/ONGOING`, `COMPLETED/FINISHED/DONE/ENDED`, `scheduled`, `all`.
  - Files: tạo `lib/core/utils/match_status_filter.dart`, test `test/core/utils/match_status_filter_test.dart`
  - Giao: `enum MatchStatusFilter { live, scheduled, completed, all; static MatchStatusFilter parse(String); String? toServerParam(); bool accepts(MatchModel m); }`
  - Phụ thuộc: không
- [ ] 1.2 Bộ skeleton: `SkeletonScope` (một `Shimmer`, tĩnh khi `disableAnimations`), `SkeletonBox/Line/Circle`, khối ghép `HomeBannerSkeleton`, `HomeStatusTabsSkeleton`, `TournamentMatchesCardSkeleton` (3 biến thể), `TournamentListItemSkeleton`, `LeaderboardRowSkeleton`, `SocialPostSkeleton`, `MatchRowSkeleton`. Dùng skill `pixel-perfect-responsive` và `fluid-animations`. Tiêu chí: `flutter test --no-pub test/core/widgets/skeleton/skeleton_test.dart` exit 0 (đỏ trước): đúng 1 `Shimmer` mỗi vùng, không có `Shimmer` khi `disableAnimations`, `HomeBannerSkeleton` cao bằng ô banner ở 3 kích thước (360x640, 412x915, 820x1180), không `RenderFlex overflow`.
  - Files: tạo `lib/core/widgets/skeleton/skeleton_scope.dart`, `skeleton_shapes.dart`, `home_skeletons.dart`, `list_skeletons.dart`; test `test/core/widgets/skeleton/skeleton_test.dart`; `lib/features/tournament/widgets/tournament_state_views.dart` (chỉ để `ShimmerPlaceholder` dùng lại `SkeletonBox`, giữ nguyên API)
  - Giao: `SkeletonScope({required Widget child})`, `HomeBannerSkeleton({required double height})`, `TournamentMatchesCardSkeleton({SkeletonCardVariant variant})`, `MatchRowSkeleton()`, `LeaderboardRowSkeleton()`, `TournamentListItemSkeleton()`, `SocialPostSkeleton()`
  - Phụ thuộc: không

## 2. Nguồn dữ liệu feed
- [ ] 2.1 `getTournamentMatchesPaged` nhận `MatchStatusFilter` thay chuỗi thô và dùng `toServerParam()`; `getPublicMatchesPaged` cùng quy tắc. Tiêu chí: `flutter test --no-pub test/data/api_match_repository_home_feed_test.dart` exit 0 (cập nhật test, đỏ trước), kiểm tra tham số `status` gửi đúng `ONGOING/SCHEDULED/COMPLETED` và không gửi khi `all`.
  - Files: sửa `lib/data/repositories/api/api_match_repository.dart:1434-1460,1580-1625`, `lib/domain/repositories/match_repository.dart:148-175`, `test/data/api_match_repository_home_feed_test.dart`
  - Chủ file chung: 2.1 sửa interface trước 3.x và 5.x
  - Phụ thuộc: 1.1
- [ ] 2.2 `homeMatchFeedProvider` theo D1: quét 6 giải/bước, tối đa 3 request đồng thời, chặn request trùng, trần 4 bước tự động, làm mới 120 giây (30 giây khi `live` có card) gộp tín hiệu trong 1,5 giây, giữ dữ liệu cũ khi lỗi, keepAlive 60 giây theo key. Tiêu chí: `flutter test --no-pub test/providers/home_match_feed_provider_test.dart` exit 0 (đỏ trước) bằng repository giả đếm lời gọi: (a) 20 giải mở trang = 6 lời gọi, 0 lời gọi `getMatches`; (b) `live` không giải nào khớp dừng sau 24 giải; (c) hai `loadMore()` đồng thời không gọi trùng; (d) lỗi một giải không ảnh hưởng giải khác; (e) làm mới lỗi giữ dữ liệu cũ; (f) đổi bộ lọc 3 lần chỉ quét bộ lọc cuối (dùng `fakeAsync`).
  - Files: tạo `lib/providers/home_match_feed_provider.dart`, test `test/providers/home_match_feed_provider_test.dart`; sửa `lib/providers/app_providers.dart` (export nếu repo dùng barrel)
  - Giao: `final homeMatchFeedProvider = NotifierProvider.autoDispose.family<HomeMatchFeedNotifier, HomeMatchFeedState, HomeMatchFeedQuery>(...)`; `HomeMatchFeedQuery({required MatchStatusFilter status, required String query, required List<Tournament> tournaments})`; `HomeMatchFeedState { HomeFeedPhase phase; List<Tournament> visible; Map<String, FeedPage> pages; bool hasMore }`; `Notifier.loadMore()`, `refresh()`, `retry(String tournamentId)`
  - Phụ thuộc: 1.1, 2.1

## 3. Trang chủ: Khám phá
- [ ] 3.1 `LiveTournamentWithMatchesCard` nhận `initialPage`, không tự gọi trang đầu; trang sau dùng skeleton hàng trận; không còn vùng trận trống (rỗng/lỗi hiển thị thông báo). Tiêu chí: `flutter test --no-pub test/features/live_tournament_with_matches_card_test.dart` exit 0 (cập nhật, đỏ trước) kèm ca mới: dựng card = 0 lời gọi repository; bấm trang sau = 1 lời gọi; trang sau lỗi giữ trang hiện tại.
  - Files: sửa `lib/features/explore/widgets/live_tournament_with_matches_card.dart:30-103,190-240,290-310`, `test/features/live_tournament_with_matches_card_test.dart:337`
  - Giao: `LiveTournamentWithMatchesCard({required Tournament tournament, required MatchStatusFilter filter, required FeedPage initialPage, ...})`
  - Phụ thuộc: 1.2, 2.2
- [ ] 3.2 `TournamentSectionList` đọc `homeMatchFeedProvider`, bỏ `ref.watch(matchesProvider)`, bỏ hàm lọc `if` trùng; skeleton khi `phase == loading`, thông báo rỗng khi `exhausted` không card, nút "Tải thêm" khi chạm trần; sentinel gọi `loadMore()` một lần mỗi lần chạm. Tiêu chí: `flutter test --no-pub test/features/home/tournament_section_list_test.dart` exit 0 (cập nhật, đỏ trước): không có `CircularProgressIndicator`, có `TournamentMatchesCardSkeleton` khi tải, không có card trống, `loadMore` không lặp khi build lại.
  - Files: sửa `lib/features/home/widgets/tournament_section_list.dart` (viết lại phần build, giữ ngoại hình card), `test/features/home/tournament_section_list_test.dart`
  - Phụ thuộc: 2.2, 3.1
- [ ] 3.3 `home_screen.dart` tab Khám phá: `loading:` dùng `HomeBannerSkeleton` + `HomeStatusTabsSkeleton` + 3 card skeleton thay vòng xoay; giữ thanh lọc môn thật; bỏ `SliverFillRemaining` + vòng xoay. Tiêu chí: `flutter test --no-pub test/features/home/home_explore_loading_test.dart` exit 0 (đỏ trước): trạng thái loading hiển thị skeleton, không `CircularProgressIndicator`, thanh lọc môn tương tác được; chiều cao ô banner skeleton = ô banner thật.
  - Files: sửa `lib/features/home/screens/home_screen.dart:674-805`; tạo test `test/features/home/home_explore_loading_test.dart`
  - Chủ file chung: 3.3 sở hữu `home_screen.dart` trong nhóm 3 và 4 (làm 3.3 trước 4.1)
  - Phụ thuộc: 1.2, 3.2

## 4. Trang chủ: các tab còn lại
- [ ] 4.1 Tab Giải đấu: skeleton lần tải đầu (`TournamentListItemSkeleton` x6) và dải skeleton ở thanh "tải thêm" thay vòng xoay. Tiêu chí: `flutter test --no-pub test/features/home/home_tournaments_loading_test.dart` exit 0 (đỏ trước).
  - Files: sửa `lib/features/home/screens/home_screen.dart:1214-1400`; tạo test `test/features/home/home_tournaments_loading_test.dart`
  - Phụ thuộc: 1.2, 3.3
- [ ] 4.2 Bảng xếp hạng: `LeaderboardRowSkeleton` thay 3 vòng xoay. Tiêu chí: `flutter test --no-pub test/features/rankings/leaderboard_loading_test.dart test/features/rankings/leaderboard_format_filter_test.dart` exit 0.
  - Files: sửa `lib/features/rankings/screens/leaderboard_screen.dart:144,168,187`; tạo test `test/features/rankings/leaderboard_loading_test.dart`
  - Phụ thuộc: 1.2
- [ ] 4.3 Cộng đồng: `SocialPostSkeleton` thay vòng xoay lần đầu và ở thanh tải thêm. Tiêu chí: `flutter test --no-pub test/features/social/social_list_loading_test.dart` exit 0 (đỏ trước).
  - Files: sửa `lib/features/social/screens/social_list_view.dart:70-75,286-290`; tạo test `test/features/social/social_list_loading_test.dart`
  - Phụ thuộc: 1.2

## 5. Màn `/matches`
- [ ] 5.1 `matches_list_screen.dart` tải theo trang bằng `getPublicMatchesPaged`, skeleton `MatchRowSkeleton`, tải thêm khi cuộn, không bật lại skeleton khi đã có dữ liệu; pill dùng `MatchStatusFilter`, gộp "Vừa kết thúc"/"Đã kết thúc", bỏ pill "Đăng ký". Tiêu chí: `flutter test --no-pub test/features/match/matches_list_screen_test.dart` exit 0 (đỏ trước): mở = 1 lời gọi trang đầu (không `getMatches`); cuộn cuối = 1 lời gọi với cursor; chọn "Đã kết thúc" cho kết quả không rỗng khi có trận `completed`; lỗi lần đầu hiện nút thử lại; làm mới nền lỗi giữ danh sách.
  - Files: sửa `lib/features/match/screens/matches_list_screen.dart:31-120,219-234,279-360`; tạo test `test/features/match/matches_list_screen_test.dart`
  - Phụ thuộc: 1.1, 1.2, 2.1

## 6. Chuỗi hiển thị
- [ ] 6.1 Thêm key i18n mới nếu có (ví dụ nhãn "Tải thêm" của feed, nhãn trợ năng cho skeleton) ở cả `app_vi.arb` và `app_en.arb`, rồi `flutter gen-l10n`. Tiêu chí: `flutter gen-l10n` exit 0; mọi key mới có ở cả hai file (kiểm bằng `diff <(jq -S 'keys' lib/l10n/app_vi.arb) <(jq -S 'keys' lib/l10n/app_en.arb)` rỗng).
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (file sinh `app_localizations*.dart` không sửa tay)
  - Phụ thuộc: 3.2, 5.1

## 7. Kiểm chứng
- [ ] 7.1 `flutter analyze --no-pub` trên `lib/core/widgets/skeleton lib/core/utils lib/providers lib/features/home lib/features/explore lib/features/rankings lib/features/social/screens lib/features/match/screens lib/data/repositories/api`; `flutter test --no-pub` đúng các file test ở mục 1-5; `openspec validate home-bone-loading --strict`. Tiêu chí: tất cả exit 0.
  - Phụ thuộc: 6.1
- [ ] 7.2 Ghi bằng chứng số request: trong `home_match_feed_provider_test.dart` đã đếm lời gọi (mở 20 giải = 6; bộ lọc không khớp dừng ở 24; 0 lời gọi `getMatches`/`watchByTournament`). Dán số đếm vào mô tả PR, kèm ghi chú "chưa xem thật trên điện thoại" nếu máy cloud không chạy được app (không có `.env`). Tiêu chí: mô tả PR có ba số đếm đó.
  - Phụ thuộc: 7.1
- [ ] 7.3 Push nhánh `cloud/danh1-hi-ban-dang-o-thu-hfpe` (chỉ repo `app`), chạy các bước trước khi push trong luật máy cloud (`related-tests`, `openspec-gate`, `overlap`, `safe-push-check`, `e2e-impact`), tạo PR cho repo App (không có staging). Tiêu chí: PR tạo xong, CI `analyze` + `test` xanh; sau đó `cloud-xong hi-ban-dang-o-thu-hfpe`.
  - Phụ thuộc: 7.2
