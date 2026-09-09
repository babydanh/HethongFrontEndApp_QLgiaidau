# 🏗️ ARCHITECTURE — Kiến trúc hệ thống Flutter App (SportO)

Tài liệu này mô tả chi tiết và chuẩn xác toàn bộ kiến trúc mã nguồn của ứng dụng di động **SportO (`HethongFrontEndApp_QLgiaidau`)**. Được thiết kế nhằm giúp bất kỳ lập trình viên hoặc AI nào khi tiếp cận dự án đều hiểu ngay:
1. **Các tầng kiến trúc (Clean Architecture + Feature-First)**.
2. **Quy tắc phân chia widget: Widget dùng chung toàn app đặt ở đâu? Widget đặc thù tính năng đặt ở đâu?**
3. **Luồng dữ liệu (Data Flow) từ REST API Backend & WebSocket đến Riverpod State và UI**.
4. **Hệ thống Routing, State Management, Theme, Đa ngôn ngữ (l10n), và Bảo mật**.

---

## 1. Sơ đồ cấu trúc thư mục thực tế (`lib/`)

```text
lib/
├── main.dart                       # Điểm khởi động app: Khởi tạo DI, Env, Notification, bọc ProviderScope
├── app.dart                        # MaterialApp.router: Cấu hình Theme, l10n, Router, Error Handler toàn cục
│
├── core/                           # 🛠️ TẦNG LÕI DÙNG CHUNG TOÀN ỨNG DỤNG (Global Core)
│   ├── config/                     # Cấu hình AppTheme (màu sắc, typography), AppConstants, GlobalErrorHandler
│   ├── di/                         # Riverpod dependency wiring và repository/use-case bindings
│   ├── dialogs/                    # Các popup/hộp thoại dùng chung toàn hệ thống (ConfirmDialog, AppDialog)
│   ├── extensions/                 # Dart Extensions tiện ích (BuildContext, String, DateTime, Num...)
│   ├── router/                     # Cấu hình GoRouter (app_router.dart), Route Names, Navigation Guards
│   ├── services/                   # Dio, token, socket, notification, media và app services
│   ├── strategy/                   # Strategy thuần cho logic dùng chung
│   ├── utils/                      # Helper về ngày, ELO, bracket, pagination, status và địa chỉ
│   └── widgets/                    # 💎 WIDGETS DÙNG CHUNG CƠ BẢN TOÀN APP (Atomic / Base UI)
│       ├── app_action_button.dart  # Nút bấm chuẩn hệ thống (Primary, Secondary, Ghost, Outline)
│       ├── app_text_field.dart     # Ô nhập liệu chuẩn, validate, format, icons
│       ├── sporto_header.dart      # Header/AppBar chuẩn SportO đồng bộ toàn app
│       ├── floating_bottom_nav.dart# Thanh điều hướng nổi dưới đáy màn hình
│       ├── rank_tier_badge.dart    # Badge hiển thị cấp bậc ELO / Tier chuẩn
│       ├── score_display.dart      # Component hiển thị tỷ số set/trận chuẩn
│       ├── score_stepper.dart      # Bộ đếm điểm (+/-) cho trọng tài/trận đấu
│       ├── countdown_timer.dart    # Đồng hồ đếm ngược thời gian thi đấu / đăng ký
│       ├── status_indicator.dart   # Chấm trạng thái (Live, Sắp diễn ra, Kết thúc)
│       ├── sport_filter_chips.dart # Bộ lọc môn thể thao (Cầu lông, Pickleball, Tennis, Bóng đá)
│       ├── sport_icon_widget.dart  # Icon môn thể thao kèm fallback
│       ├── province_picker.dart    # Bộ chọn Tỉnh/Thành phố toàn quốc
│       ├── tournament_avatar.dart  # Avatar giải đấu/CLB chuẩn tỉ lệ, có fallback
│       ├── club_network_image.dart # Tải ảnh mạng tối ưu cache, placeholder, error
│       ├── app_share_modal.dart    # BottomSheet chia sẻ giải đấu/trận đấu
│       ├── app_update_gate.dart    # Màn hình/Widget chặn bắt buộc cập nhật app
│       ├── custom_error_widget.dart# Giao diện báo lỗi thân thiện (mất mạng, 404, 500)
│       └── match_card/             # Các card hiển thị trận đấu tổng quát (Single, Doubles, Feed)
│
├── shared/                         # 🧩 WIDGETS DÙNG CHUNG CẤP CAO (Cross-feature Composite UI)
│   └── widgets/
│       ├── app_image_viewer.dart   # Trình xem ảnh full màn hình (zoom, pan, swipe to dismiss)
│       ├── report_sheet.dart       # BottomSheet báo cáo vi phạm (report trận đấu, CLB, người dùng)
│       └── withdraw_sheet.dart     # BottomSheet rút lui khỏi giải đấu/trận đấu
│
├── domain/                         # 🏛️ DOMAIN LAYER (Nghiệp vụ thuần túy - Thuần Dart, không phụ thuộc UI)
│   ├── entities/                   # Entity thuần: tournament, match, team, community, user, ranking...
│   ├── repositories/               # Repository interfaces theo bounded context
│   ├── services/                   # Score validator và sport rule service thuần domain
│   └── usecases/                   # Use case auth/tournament, độc lập với UI
│
├── data/                           # 💾 DATA LAYER (Lớp Dữ liệu & Kết nối Backend)
│   ├── models/                     # DTO / JSON Models map từ Backend API (kèm fromJson, toJson)
│   └── repositories/
│       ├── api/                    # Triển khai giao tiếp REST API qua Dio (ApiTournamentRepository, ApiCommunityRepository...)
│       ├── firebase/               # Triển khai Firebase (FirebaseMessaging cho FCM Push Notification)
│       └── local/                  # Lưu trữ cục bộ (FlutterSecureStorage, SharedPreferences cho Token, Cache)
│
├── providers/                      # 🔗 STATE MANAGEMENT LAYER (Riverpod Providers Toàn Cục)
│   ├── app_providers.dart          # Provider dữ liệu và hạ tầng cấp app
│   ├── auth_provider.dart          # Quản lý trạng thái xác thực người dùng (User, Token, Role, Session)
│   ├── user_provider.dart          # Quản lý thông tin profile cá nhân, danh sách bạn bè
│   └── theme_provider.dart         # Quản lý Dark/Light mode và theme state
│
├── features/                       # 🚀 PRESENTATION LAYER (Chia theo Tính Năng - Feature-First)
│   ├── admin/                      # Quản trị hệ thống
│   ├── auth/                       # Đăng nhập, đăng ký, session
│   ├── bracket/                    # Sơ đồ nhánh và auto draw
│   ├── chat/                       # Chat và message UI
│   ├── community/                  # CLB, social, member, ranking, search
│   ├── dashboard/                  # Dashboard tổng hợp
│   ├── explore/                    # Khám phá giải/trận/live
│   ├── football_team/              # Đội bóng đá
│   ├── home/                       # Màn hình chính và feed
│   ├── lite/                       # Các flow lite join/pairing/management
│   ├── match/                      # Cập nhật tỷ số trận đấu (Trọng tài/BTC), Live Score Screen, Match Detail
│   ├── live/                       # Khám phá các trận đang đánh Real-time, Livestream ghép nối camera thiết bị
│   ├── notification/               # Trung tâm thông báo đẩy
│   ├── organizer_ops/              # Tác vụ vận hành giải
│   ├── payment/                    # Thanh toán lệ phí
│   ├── profile/                    # Profile, settings, lịch sử ELO
│   ├── rankings/                   # Bảng xếp hạng ELO
│   ├── referee/                    # Flow trọng tài
│   ├── register/                   # Đăng ký giải đơn/đôi/đội
│   ├── reports/                    # Báo cáo/khiếu nại
│   ├── series/                     # Series list/detail
│   ├── teams/                      # Danh sách và quản lý đội
│   └── tournament/                 # Chi tiết/tạo giải và widget riêng của giải
│
└── l10n/                           # 🌐 LOCALIZATION (Đa ngôn ngữ)
    ├── app_vi.arb                  # Bản dịch Tiếng Việt
    ├── app_en.arb                  # Bản dịch Tiếng Anh
    └── app_localizations.dart      # Mã nguồn tự sinh bởi Flutter intl tool
```

---

## 2. Quy tắc phân loại Widget: "Widget dùng chung để ở đâu?"

Khi xây dựng giao diện mới hoặc tái cấu trúc, việc đặt widget đúng chỗ giúp code không bị trùng lặp, dễ tìm kiếm và tránh circular dependency (phụ thuộc vòng):

```text
                     ┌──────────────────────────────┐
                     │   Bạn đang tạo Widget mới?   │
                     └──────────────┬───────────────┘
                                    │
           ┌────────────────────────┴────────────────────────┐
           ▼                                                 ▼
[Chỉ dùng trong 1 tính năng]                    [Dùng ở từ 2 tính năng trở lên]
           │                                                 │
           ▼                                                 ▼
lib/features/<tên_feature>/widgets/              [Là Widget nền tảng hay tính năng ghép?]
Ví dụ:                                                       │
- club_activity_tab.dart                         ┌───────────┴───────────┐
- tournament/widgets/about_tab.dart               ▼                       ▼
- match/widgets/tennis_score_panel.dart  [Nền tảng / Nguyên tử]   [Tính năng phức hợp]
                                                 │                       │
                                                 ▼                       ▼
                                         lib/core/widgets/       lib/shared/widgets/
                                         Ví dụ:                  Ví dụ:
                                         - app_action_button     - app_image_viewer
                                         - sporto_header         - report_sheet
                                         - rank_tier_badge       - withdraw_sheet
                                         - score_display
```

### 1. `lib/core/widgets/` — Base / Atomic UI (Dùng chung nền tảng)
- **Đặc điểm:** Là các thành phần giao diện nhỏ, độc lập, theo sát Design System của app (Button, TextField, Header, Badge, Chip, Dialog nhỏ).
- **Quy tắc:**
  - **Không** import trực tiếp Repository hay logic API của feature cụ thể.
  - Nhận dữ liệu qua parameters (`props`), trả tương tác qua callbacks (`onTap`, `onChanged`).
  - Phụ thuộc vào `core/config/app_theme.dart` để lấy màu sắc, typography và khoảng cách.

### 2. `lib/shared/widgets/` — Composite / Cross-Feature UI (Dùng chung phức hợp)
- **Đặc điểm:** Là các BottomSheet, Dialog hoặc màn hình con có tương tác nghiệp vụ xuất hiện ở nhiều module khác nhau.
- **Ví dụ cụ thể:**
  - `report_sheet.dart`: Nút "Báo cáo" xuất hiện ở cả màn hình Chi tiết giải, Chi tiết trận đấu, Trang cá nhân và Chi tiết CLB.
  - `withdraw_sheet.dart`: Nút "Xin rút lui" xuất hiện ở màn hình Đăng ký, Lịch thi đấu và Danh sách đội.
  - `app_image_viewer.dart`: Trình phóng to ảnh xuất hiện khi bấm vào avatar giải, ảnh hoạt động CLB hay ảnh bằng chứng trận đấu.

### 3. `lib/features/<feature_name>/widgets/` — Feature-Specific UI (Nội bộ tính năng)
- **Đặc điểm:** Chỉ phục vụ cho tính năng đó, không có giá trị tái sử dụng ở các màn hình khác.
- **Ví dụ:**
  - `features/community/widgets/club_ranking_widget.dart` (Bảng rank nội bộ CLB).
  - `features/tournament/widgets/bracket_tab.dart` (Tab sơ đồ giải).
  - `features/match/widgets/tennis_score_panel.dart` (Bảng điểm tennis riêng của trận đấu).

---

## 3. Kiến trúc các tầng (Clean Architecture Overview)

Hệ thống tuân thủ nghiêm ngặt nguyên lý **Inversion of Control (IoC)** và **Separation of Concerns (SoC)**:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                              │
│  - Screens (Màn hình hoàn chỉnh điều hướng qua GoRouter)               │
│  - Widgets (Chia nhỏ các thành phần giao diện, tái sử dụng)            │
│  - Controllers / Notifiers (Quản lý UI state, hứng input người dùng)   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ consumes
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          DOMAIN LAYER                                  │
│  - Entities: Thực thể dữ liệu thuần túy (Immutable class)              │
│  - Repository Interfaces: Hợp đồng trừu tượng (Abstract class)         │
│  - Business Rules: Thuật toán xếp nhánh, tính điểm ELO, xếp hạt giống  │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ implements
                                    │
┌───────────────────────────────────┴────────────────────────────────────┐
│                           DATA LAYER                                   │
│  - Data Models: Map dữ liệu JSON ⇄ Entity (fromJson, toJson)           │
│  - Data Sources: Dio HTTP Client (REST API), Socket.IO (Realtime)      │
│  - Local Cache: FlutterSecureStorage (Token), SharedPreferences        │
│  - Repositories Implementation: Thực thi logic gọi API, bắt lỗi HTTP   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Luồng dữ liệu chuẩn (Data Flow)

### 4.1 Luồng truy vấn & hiển thị dữ liệu (Read Flow - Riverpod & REST API)

```text
Người dùng mở màn hình (VD: ClubDetailScreen)
                     │
                     ▼
UI lắng nghe Riverpod Provider: `ref.watch(clubDetailProvider(clubId))`
                     │
                     ▼
Provider gọi Domain Repository Interface: `ICommunityRepository.getClub(clubId)`
                     │
                     ▼
Data Layer thực thi: `ApiCommunityRepository.getClub(clubId)`
                     │
                     ▼
Gửi HTTP Request qua Dio: `GET /api/v1/communities/:id` (kèm Bearer Auth Token)
                     │
                     ▼
Backend trả về JSON Response ──► Data Model parse `CommunityModel.fromJson(json)`
                     │
                     ▼
Trả về Entity thuần `Community` cho Provider
                     │
                     ▼
Provider phát tín hiệu State:
  • `AsyncLoading`: UI hiển thị Shimmer loading
  • `AsyncError`: UI hiển thị CustomErrorWidget (kèm nút thử lại)
  • `AsyncData(club)`: UI render nội dung chi tiết
```

### 4.2 Luồng cập nhật tỷ số thời gian thực (Real-time Live Score Flow)

```text
Trọng tài bấm "+1 Điểm" trên ScoreStepper
                     │
                     ▼
ScoreController gọi API: `POST /api/v1/matches/:id/points`
                     │
                     ▼
Backend cập nhật Database & Emit WebSocket Event qua Socket.IO:
`socket.emit('match:score_updated', { matchId, scoreTeam1, scoreTeam2, setIndex })`
                     │
                     ▼
App Client (Khán giả/Trọng tài khác) qua `SocketObserver` nhận event
                     │
                     ▼
Tự động cập nhật `matchDetailProvider` trong Riverpod State
                     │
                     ▼
Widget `ScoreDisplay` cập nhật tỷ số ngay lập tức mà không cần reload trang!
```

---

## 5. Quản lý trạng thái (State Management với Riverpod)

Dự án sử dụng **`flutter_riverpod`** làm giải pháp quản lý trạng thái duy nhất.

### 5.1 Các loại Provider thường dùng
1. **`Provider` (Toàn cục / Bất biến):** Dùng để cung cấp các dependencies như `dioProvider`, `dioClientProvider`, `tokenManagerProvider` và repository bindings.
2. **`FutureProvider.family` (Dữ liệu bất đồng bộ 1 lần):** Dùng để load chi tiết giải đấu, thông tin profile người dùng:
   ```dart
   final tournamentDetailProvider = FutureProvider.family<Tournament, String>((ref, id) async {
     return ref.read(tournamentRepositoryProvider).getTournamentById(id);
   });
   ```
3. **`AsyncNotifierProvider` / `NotifierProvider` (State có thay đổi / Tương tác form):** Dùng cho Authentication, Quản lý trận đấu, Tạo giải:
   ```dart
   final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
   ```

### 5.2 Quản lý vòng đời (Lifecycle)
- Các dữ liệu màn hình chi tiết luôn sử dụng `.autoDispose` để giải phóng bộ nhớ khi người dùng rời khỏi màn hình, tránh rò rỉ RAM (Memory Leak).

---

## 6. Điều hướng & Phân quyền (GoRouter & Role Guards)

Hệ thống định tuyến tập trung trong `lib/core/router/app_router.dart` sử dụng **`go_router`**.

### 6.1 Cấu trúc Route chính
- `/`: Màn hình splash, kiểm tra phiên đăng nhập và phiên bản app.
- `/login`, `/register`, `/forgot-password`: Màn hình xác thực tài khoản.
- `/home`: Trang chủ (Bảng tin, Giải đấu nổi bật, Feed trận đấu).
- `/tournaments`: Khám phá & danh sách giải đấu.
- `/tournaments/:id`: Chi tiết giải đấu (Sơ đồ nhánh, Lịch thi đấu, VĐV, Điều lệ).
- `/live/:matchId`: Màn hình theo dõi trực tiếp tỷ số trận đấu.
- `/clubs/:id`: Chi tiết CLB (Bảng tin, Kèo giao lưu, Xếp hạng nội bộ).
- `/profile`: Trang cá nhân, lịch sử ELO, cài đặt.

### 6.2 Phân quyền (Role Guards & Route Protection)
- **Khách (Guest / Chưa đăng nhập):** Có thể xem thông tin giải đấu, kết quả trận đấu, bảng xếp hạng công khai.
- **Yêu cầu đăng nhập:** Khi ấn tham gia giải, tạo CLB, đăng ký thi đấu, hoặc vào hồ sơ cá nhân -> GoRouter tự động chuyển hướng về `/login` kèm tham số `redirect` để quay lại sau khi đăng nhập thành công.
- **Admin / Trọng tài:** Chỉ tài khoản có Role `ADMIN` hoặc được chỉ định làm `REFEREE` cho trận đấu đó mới có quyền truy cập vào màn hình cập nhật tỷ số `/referee/match/:id`.

---

## 7. Tiêu chuẩn thiết kế & Quy tắc lập trình (Best Practices)

1. **Tuân thủ Design System (`AppTheme`):**
   - Tuyệt đối không hardcode màu sắc (VD: `Color(0xFF1D5FE0)`), luôn dùng `AppTheme.primary`, `context.colors.textPrimary`.
   - Sử dụng các hằng số bo góc và khoảng cách chuẩn từ `AppTheme` và `app_spacing.dart`.

2. **Hỗ trợ đa ngôn ngữ (Localization - l10n):**
   - Toàn bộ chuỗi văn bản hiển thị trên UI phải thông qua `AppLocalizations.of(context)`. Không hardcode tiếng Việt hay tiếng Anh trực tiếp trong widget.

3. **Xử lý Responsive & Safe Area:**
   - Sử dụng `SafeArea` cho các màn hình có thanh điều hướng hoặc nút bấm dưới đáy.
   - Với màn hình tablet hoặc máy tính bảng, dùng `AppResponsive` hoặc `ResponsiveLayout` để giới hạn chiều rộng tối đa (`maxWidth: 600 - 800px`), tránh vỡ bố cục.

4. **Tối ưu hiệu năng hiển thị:**
   - Với danh sách động (trận đấu, VĐV, bài viết), luôn dùng `ListView.builder` hoặc `CustomScrollView` với `SliverList` thay vì `Column(children: [...])`.
   - Sử dụng `const` constructor cho tất cả các widget tĩnh để tránh Flutter render lại không cần thiết.

---

## 8. Inventory thư mục và file thực tế (source map)

Phần này là danh mục chi tiết để tra cứu nhanh. Tên file bên dưới được đối
chiếu từ source hiện tại; khi thêm file mới phải cập nhật section này trong
cùng change nếu file làm thay đổi boundary kiến trúc.

### 8.1 Core inventory

```text
lib/core/config/
├── app_constants.dart
├── app_spacing.dart
├── app_theme.dart
├── app_typography.dart
└── global_error_handler.dart

lib/core/di/
├── core_di_providers.dart
├── di.dart
├── repository_providers.dart
├── socket_providers.dart
└── usecase_providers.dart

lib/core/dialogs/
└── confirm_dialog.dart

lib/core/extensions/
├── animation_extensions.dart
├── match_extensions.dart
└── string_extensions.dart

lib/core/router/
└── app_router.dart

lib/core/services/
├── api_response.dart
├── app_logger.dart
├── app_update_service.dart
├── bracket_graph_service.dart
├── chat_socket_service.dart
├── device_fingerprint_storage.dart
├── dio_client.dart
├── draw_service.dart
├── excel_export_service.dart
├── match_socket_service.dart
├── penalty_service.dart
├── push_notification_service.dart
├── socket_service.dart
└── token_manager.dart

lib/core/strategy/
└── penalty_strategy.dart

lib/core/utils/
├── bracket_generator.dart
├── cursor_pagination.dart
├── date_formatter_utils.dart
├── date_parser.dart
├── elo_helpers.dart
├── elo_tier.dart
├── error_parser.dart
├── match_round_label.dart
├── match_visibility.dart
├── navigation_helpers.dart
├── rank_tier_colors.dart
├── ranking_query_helpers.dart
├── status_helpers.dart
├── tennis_game_point_display.dart
├── token_generator.dart
├── tournament_location_formatter.dart
└── vietnam_address_parser.dart

lib/core/widgets/
├── app_action_button.dart
├── app_bottom_nav.dart
├── app_focusable.dart
├── app_icons.dart
├── app_info_dialog.dart
├── app_responsive.dart
├── app_share_modal.dart
├── app_text_field.dart
├── app_update_gate.dart
├── club_network_image.dart
├── countdown_timer.dart
├── custom_error_widget.dart
├── floating_bottom_nav.dart
├── form_section.dart
├── image_crop_dialog.dart
├── info_chip.dart
├── province_picker.dart
├── rank_tier_badge.dart
├── responsive_layout.dart
├── score_display.dart
├── score_stepper.dart
├── socket_observer.dart
├── sport_filter_chips.dart
├── sport_icon_widget.dart
├── sporto_brand_fallback.dart
├── sporto_header.dart
├── status_indicator.dart
├── status_segment.dart
├── tournament_avatar.dart
└── match_card/

lib/shared/widgets/
├── app_image_viewer.dart
├── report_sheet.dart
└── withdraw_sheet.dart
```

### 8.2 Domain, data và provider inventory

```text
lib/domain/entities/
├── app_notification.dart       ├── auth_session.dart
├── community.dart              ├── elo_history_log.dart
├── elo_tier.dart               ├── lite_tournament_create_result.dart
├── match.dart                  ├── match_event.dart
├── organizer_lite.dart         ├── organizer_ops.dart
├── penalty.dart                ├── ranking.dart
├── region.dart                 ├── saved_tournament.dart
├── standing.dart               ├── team.dart
├── token.dart                  ├── tournament.dart
├── tournament_registration.dart├── tournament_sponsor.dart
├── tournament_workspace.dart   ├── user.dart
└── violation_report.dart

lib/domain/repositories/
├── auth_repository.dart                  ├── community_repository.dart
├── community_search_repository.dart      ├── community_social_repository.dart
├── live_session_repository.dart           ├── local_session_repository.dart
├── match_repository.dart                  ├── ranking_repository.dart
├── region_repository.dart                 ├── report_repository.dart
├── session_repository.dart                 ├── team_repository.dart
├── token_repository.dart                  ├── tournament_repository.dart
└── user_repository.dart

lib/domain/services/
├── score_validator.dart
└── sport_rule_service.dart

lib/domain/usecases/auth/
├── clear_session_use_case.dart             ├── login_with_email_use_case.dart
├── login_with_google_use_case.dart          ├── register_with_email_use_case.dart
├── restore_saved_invite_token_use_case.dart ├── save_invite_token_use_case.dart
└── validate_invite_token_use_case.dart

lib/domain/usecases/tournament/
├── create_tournament_use_case.dart
├── delete_tournament_use_case.dart
├── finalize_tournament_use_case.dart
├── publish_tournament_draw_use_case.dart
└── reset_tournament_draw_use_case.dart

lib/data/models/
├── app_models.dart                 ├── camera_device_model.dart
├── chat_models.dart                ├── club_match_session_model.dart
├── club_notification_pref_model.dart
├── community_invite_model.dart     ├── community_member_model.dart
├── community_ranking_model.dart    ├── community_search_models.dart
├── community_social_models.dart    ├── community_tournament_model.dart
├── gallery_image_model.dart        ├── live_session_model.dart
├── match_event_model.dart          ├── match_model.dart
├── payment_model.dart              ├── penalty_model.dart
├── ranking_model.dart              ├── saved_tournament_model.dart
├── standing_model.dart             ├── team_model.dart
├── token_model.dart                ├── tournament_model.dart
└── user_model.dart

lib/data/repositories/api/
├── api_auth_repository.dart              ├── api_club_match_session_repository.dart
├── api_community_repository.dart         ├── api_community_search_repository.dart
├── api_community_social_repository.dart  ├── api_live_session_repository.dart
├── api_match_repository.dart             ├── api_notification_repository.dart
├── api_payment_repository.dart            ├── api_ranking_repository.dart
├── api_region_repository.dart             ├── api_report_repository.dart
├── api_team_repository.dart              ├── api_token_repository.dart
├── api_tournament_repository.dart         └── api_user_repository.dart

lib/data/repositories/firebase/
└── (Firebase boundary; implementation được bổ sung khi integration bật)

lib/data/repositories/local/
├── app_session_repository.dart
└── shared_prefs_local_session_repository.dart
```

Provider cấp app ở `lib/providers/` gồm:

```text
app_providers.dart                    auth_provider.dart
category_provider.dart                club_match_session_provider.dart
community_provider.dart               lite_management_notifier.dart
live_session_provider.dart             locale_provider.dart
match_control_notifier.dart           my_tournament_workspace_provider.dart
network_providers.dart                 notification_provider.dart
organizer_lite_provider.dart           organizer_ops_provider.dart
query_providers.dart                   ranking_provider.dart
regions_provider.dart                  report_provider.dart
saved_tournaments_provider.dart        sport_rule_provider.dart
standings_provider.dart                 team_notifier.dart
theme_provider.dart                     token_management_notifier.dart
tournament_action_notifier.dart         tournament_result_provider.dart
user_provider.dart
```

### 8.3 Feature inventory

Tất cả 23 feature đang tồn tại trong source:

```text
features/admin/             screens/
features/auth/              screens/, widgets/
features/bracket/           layout/, models/, screens/, utils/, widgets/
features/chat/              screens/, widgets/, read_receipt_state.dart
features/community/         providers/, screens/, social/, widgets/
                            social/widgets/
features/dashboard/         screens/
features/explore/           widgets/
features/football_team/     screens/
features/home/              screens/, widgets/
features/lite/              screens/, widgets/
features/live/              screens/
features/match/             notifiers/, screens/, utils/, widgets/
features/notification/      screens/
features/organizer_ops/     screens/
features/payment/           screens/
features/profile/           screens/, utils/, widgets/
features/rankings/          screens/, widgets/
features/referee/           screens/
features/register/          screens/
features/reports/           screens/
features/series/             screens/
features/teams/              screens/
features/tournament/        screens/, widgets/
```

Quy ước cụ thể:

- `community/screens/` chứa club detail, club search, create/edit/manage,
  club tournaments, match sessions và invite screens.
- `community/social/` là bounded area cho bảng tin, bài viết, gallery và social
  interaction; `community/social/widgets/` không dùng cho chat.
- `bracket/layout/`, `bracket/models/`, `bracket/utils/` chỉ phục vụ render và
  thuật toán bracket; không thay thế `data/models`.
- `match/notifiers/` sở hữu state điều khiển trận; `match/utils/` là helper
  riêng match; score UI đặt trong `match/widgets/` nếu không đủ generic để lên
  core.
- `profile/utils/` và `profile/widgets/` chỉ dành cho profile; ELO dùng chung
  toàn app vẫn lấy component từ core/rankings theo đúng scope.

### 8.4 Backend companion inventory

Backend sibling `HethongBackendApi_QuanlyGiaiDau/src/` có các thư mục thật sau:

```text
common/       config/       database/       providers/
modules/
├── admin                  ├── advertisements
├── ai                     ├── app-version
├── audit                  ├── auth
├── categories             ├── chat
├── club-match-sessions    ├── communities
├── firebase               ├── football-teams
├── livestream              ├── matches
├── notifications          ├── payments
├── rankings               ├── regions
├── series                 ├── social
├── sponsors               ├── tournaments
├── upload                 ├── users
└── venues
```

`common/` chứa constants/decorators/DTO/exceptions/filters/guards/helpers và
interceptors; `database/` chứa schema/migration/seed; `providers/` chứa
mail/Redis/storage. Backend module là owner của permission, validation,
transaction, ELO, payment, upload và realtime contract.

## 9. Cách duy trì tài liệu

- Khi thêm thư mục hoặc module, cập nhật cây thư mục và inventory trong cùng
  change, kèm lý do boundary.
- Khi đổi route, provider, repository interface, DTO, socket event hoặc
  ownership, cập nhật các phần route/data flow/contract liên quan trước khi
  merge.
- Khi đổi widget dùng chung, rà import của tất cả consumer; không chỉ sửa tên
  thư mục mà bỏ qua dependency edge.
- Khi file được generate (`l10n`, `graphify-out`), cập nhật từ source generator;
  không coi output sinh tự động là nơi định nghĩa kiến trúc.
- Mọi thay đổi có API, realtime, auth, payment, upload, AI hoặc cross-platform
  phải ghi rõ impact, error state, rollback và evidence trong change workspace.
