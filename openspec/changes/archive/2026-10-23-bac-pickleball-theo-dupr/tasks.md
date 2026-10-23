# Tasks

## 1. Entity và hàm chọn bậc

- [x] 1.1 Thêm `tierSource`, `tierAvailable` (nullable) vào `PlayerRanking`, `UserRankResponse` (`lib/domain/entities/ranking.dart`) và `tierSource`, `minValue`, `maxValue` (`double?`) vào `EloTier` (`lib/domain/entities/elo_tier.dart`), parse cả camelCase và snake_case như các field hiện có. Thêm hàm `resolveDisplayTier` theo design D1. Test `test/core/utils/display_tier_test.dart`: `DUPR` + `tierAvailable: true` + `High Tier C` + ELO 1100 → `HTC`; `DUPR` + `tierAvailable: false` → `null`; `ELO` + `tierName` rỗng + ELO 1450 → bậc suy từ ELO; JSON thiếu `tierSource` → như `ELO`; `EloTier.fromJson` đọc `minValue: 3.5`. Xong khi `flutter test --no-pub test/core/utils/display_tier_test.dart` pass (cần `.env`: `cp .env.example .env`, không commit).

## 2. Widget

- [x] 2.1 `EloTierBadge`, `RankTierBadge` và badge avatar (`floating_bottom_nav.dart:213-217`) dùng `resolveDisplayTier`, không render khi `null`; cập nhật các màn `leaderboard_screen.dart`, `profile_screen.dart`, `user_profile_screen.dart`, phần rank công khai của `user_profile_bottom_sheet.dart` để truyền `tierSource`, `tierAvailable`. Widget test: rank `DUPR` + `tierAvailable: false` không có badge; rank `ELO` có badge như cũ. Xong khi `flutter test --no-pub test/features/rankings/tier_display_widgets_test.dart` pass.
- [x] 2.2 Ẩn "còn X ELO để lên …" ở `elo_progress_card.dart` khi `tierSource = DUPR`. Widget test hai ca `DUPR` và `ELO` 1450. Xong khi `flutter test --no-pub test/features/rankings/tier_display_widgets_test.dart` pass.
- [x] 2.3 `tier_legend_view.dart` hiện khoảng DUPR, không có Tier S, kèm dòng "Bậc theo DUPR" khi bậc có `tierSource: 'DUPR'`; thêm key vào `lib/l10n/app_vi.arb` và `app_en.arb`, chạy `flutter gen-l10n`. Widget test: 8 bậc DUPR hiện `High Tier C` 3.50–3.99; danh sách rỗng hiện trạng thái trống. Xong khi `flutter gen-l10n` exit 0 và `flutter test --no-pub test/features/rankings/tier_display_widgets_test.dart` pass.

## 3. Kiểm tổng

- [x] 3.1 Chạy `flutter analyze --no-pub lib/domain/entities lib/core/utils lib/core/widgets lib/features/rankings lib/features/profile` không có lỗi mới, và `flutter test --no-pub` các file test của task 1.1, 2.1, 2.2, 2.3 pass.

## Workflow follow-up

- Gộp sau Backend change `bac-pickleball-theo-dupr`, bằng `merge-lane.py <worktree> --check "python C:/Users/GIGABYTE/.omp/scripts/openspec-gate.py"`. Archive sau khi gộp.
- Admin chỉ bật nguồn `DUPR` cho pickleball sau khi bản App này đã phát hành.
