## 1. Model, bộ lọc, thông báo

- [x] 1.1 `MatchModel` đọc `isStaleLive`/`lastActivityAt` (fromJson, toJson, copyWith); `MatchStatusFilter.live` loại stale. Tiêu chí: `flutter test --no-pub test/core/utils/match_status_filter_test.dart` và `test/domain/match_stale_live_test.dart` → exit 0 (TC-SLM-APP-01..03)
  - Files: sửa `lib/domain/entities/match.dart`, `lib/core/utils/match_status_filter.dart`, `lib/data/repositories/api/api_match_repository.dart`, `lib/data/repositories/api/api_tournament_repository.dart` (hai parser API dựng `MatchModel` tay, không qua `fromJson`), `test/core/utils/match_status_filter_test.dart`; tạo `test/domain/match_stale_live_test.dart`, `test/data/api_match_repository_stale_live_test.dart` (TC-SLM-APP-09)
  - Giao: `MatchModel.isStaleLive`, `MatchModel.lastActivityAt` · Nhận: (không)
  - Chủ file chung: 1.1 giữ ba file lib trên
  - Phụ thuộc: (không)
- [x] 1.2 Thông báo `MATCH_STALE_LIVE`: route mở trận, icon, màu. Tiêu chí: `flutter test --no-pub test/domain/app_notification_route_test.dart` → exit 0 (TC-SLM-APP-08)
  - Files: sửa `lib/domain/entities/app_notification.dart`, `test/domain/app_notification_route_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 1.2 giữ hai file trên
  - Phụ thuộc: (không)

## 2. Widget và màn hình

- [x] 2.1 Chuỗi l10n + widget `StaleLiveBadge`/`StaleLiveReminder`. Tiêu chí: `flutter test --no-pub test/core/widgets/stale_live_widgets_test.dart` → exit 0 (TC-SLM-APP-04, 05)
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (+ code sinh bằng `flutter gen-l10n`); tạo `lib/core/widgets/match_card/stale_live_widgets.dart`, `test/core/widgets/stale_live_widgets_test.dart`
  - Giao: hai widget · Nhận: 1.1
  - Chủ file chung: 2.1 giữ hai arb
  - Phụ thuộc: sau 1.1
- [x] 2.2 Người xem: `LiveMatchCardV2`, thẻ `/matches`, màn live theo giải (nhóm "Tạm dừng"), màn xem trận (bỏ dot LIVE, nhãn Tạm dừng). Tiêu chí: `flutter test --no-pub test/core/widgets/live_match_card_stale_test.dart` → exit 0 (TC-SLM-APP-06, 07); `flutter analyze --no-pub lib/core/widgets lib/features/live lib/features/match` → exit 0
  - Files: sửa `lib/core/widgets/match_card/live_match_card_v2.dart`, `lib/features/live/screens/live_match_screen.dart`, `lib/features/match/screens/matches_list_screen.dart`, `lib/features/match/screens/live_score_screen.dart`; tạo `test/core/widgets/live_match_card_stale_test.dart`
  - Giao: (không) · Nhận: 2.1
  - Chủ file chung: 2.2 giữ các file trên; KHÔNG đụng `pickleball_court_panel.dart`, `score_panel_notifier.dart`, `score_panel_state.dart`
  - Phụ thuộc: sau 2.1
- [x] 2.3 BTC: lời nhắc ở thẻ Vận hành giải và màn xem/chấm điểm. Tiêu chí: `flutter analyze --no-pub lib/features/organizer_ops` → exit 0 (TC-SLM-APP-05 phủ widget)
  - Files: sửa `lib/features/organizer_ops/screens/organizer_ops_screen.dart`, `lib/features/match/screens/live_score_screen.dart`
  - Giao: (không) · Nhận: 2.1
  - Chủ file chung: 2.3 chung `live_score_screen.dart` với 2.2 nên làm tuần tự
  - Phụ thuộc: sau 2.2

## 3. Kiểm tra cuối

- [x] 3.1 `flutter analyze --no-pub` chỉ trên thư mục đã sửa → exit 0; quét khóa diff staged rỗng. Tiêu chí: lệnh exit 0
  - Files: (không sửa file)
  - Giao: (không) · Nhận: 1.1–2.3
  - Chủ file chung: (không)
  - Phụ thuộc: sau 2.3
