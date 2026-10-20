# Proposal

## Why

Backend (change cùng tên `bac-pickleball-theo-dupr`) cho phép môn pickleball xếp bậc theo DUPR đã liên kết và báo nguồn bậc qua field `tierSource`. App hiện luôn suy bậc từ ELO khi thiếu `tierName` (`lib/features/rankings/widgets/elo_tier_badge.dart:38-56`, `lib/core/utils/elo_tier.dart:64-89`), nên người chưa liên kết DUPR vẫn có badge theo ELO, trái với yêu cầu "chưa có DUPR thì không hiện gì".

## What Changes

- Parse `tierSource` (`ELO` | `DUPR`) ở `PlayerRanking`, `UserRankResponse` (`lib/domain/entities/ranking.dart`) và ở danh sách bậc `EloTier` (`lib/domain/entities/elo_tier.dart`, kèm `minValue`, `maxValue` dạng `double?`).
- Khi `tierSource = DUPR`: chỉ dùng `tierName` của API; `tierName` là `null` thì **không hiện badge bậc** ở bảng xếp hạng, hồ sơ, bottom sheet hồ sơ và badge trên avatar; không suy bậc từ ELO.
- Khi `tierSource = DUPR`: ẩn tiến độ "còn X ELO để lên {bậc}" (`ranking_eloToNext`).
- Chú giải bậc (`tier_legend_view.dart`) ở môn nguồn `DUPR` hiện 8 bậc với khoảng DUPR (`minValue`–`maxValue`), không có Tier S, kèm dòng "Bậc theo DUPR".
- Chuỗi mới có key ở cả `lib/l10n/app_vi.arb` và `app_en.arb`.
- Thiếu `tierSource` (Backend cũ) hoặc `tierSource = ELO`: giữ nguyên hành vi hiện tại.

## Capabilities

### New Capabilities

- `skill-tier-badge`: cách App hiển thị badge bậc, tiến độ lên bậc và chú giải bậc theo nguồn bậc Backend trả về.

### Modified Capabilities

(không có)

## Out of scope

- Bậc CLB: `user_club_rank_provider.dart` và phần CLB của `user_profile_bottom_sheet.dart` vẫn theo ELO, kể cả mặc định `'Low Tier D'`.
- Liên kết tài khoản DUPR, hiển thị số DUPR (change tích hợp DUPR).
- Thứ tự bảng xếp hạng.

## Impact

- Backend: dùng field mới `tierSource`, `tierName` nullable trong `GET /api/v1/rankings`, `GET /api/v1/rankings/user/:userId`, và `tierSource`, `minValue`, `maxValue` của từng phần tử `GET /api/v1/categories/:id/elo-tiers` (Backend change `bac-pickleball-theo-dupr`). App phải phát hành trước khi admin bật nguồn `DUPR`; bản App cũ sẽ vẫn hiện badge suy từ ELO.
- Code App: `lib/domain/entities/ranking.dart`, `lib/domain/entities/elo_tier.dart`, `lib/core/utils/elo_helpers.dart`, `lib/core/utils/elo_tier.dart`, `lib/features/rankings/widgets/elo_tier_badge.dart`, `lib/core/widgets/rank_tier_badge.dart`, `lib/features/rankings/widgets/elo_progress_card.dart`, `lib/features/rankings/widgets/tier_legend_view.dart`, các màn dùng badge (`leaderboard_screen.dart`, `profile_screen.dart`, `user_profile_screen.dart`, `user_profile_bottom_sheet.dart`, `floating_bottom_nav.dart`), `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`.
- Web: change cùng tên trong repo Web.
