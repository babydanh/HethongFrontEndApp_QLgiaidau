# Design

## Context

Xem `proposal.md`. Hiện tại `EloTierBadge` luôn gọi `resolveEloTier(elo, tierName)` (`lib/features/rankings/widgets/elo_tier_badge.dart:38-56`), `getShortTierCode` suy mã từ ELO khi thiếu tên (`lib/core/utils/elo_tier.dart:64-89`), ngưỡng ELO nằm ở `lib/core/utils/elo_helpers.dart:35-45`, tiến độ ở `elo_helpers.dart:139-188`. `EloTier` parse `minElo`/`maxElo` thành `int` (`lib/domain/entities/elo_tier.dart:23-31`).

## Goals / Non-Goals

**Goals:** một hàm quyết định "có bậc hay không" theo `tierSource`, mọi widget badge và tiến độ dùng chung.

**Non-Goals:** không đổi màu, mã viết tắt, tên bậc; không đụng bậc CLB.

## Decisions

### D1. Hàm `resolveDisplayTier(tierName, elo, tierSource)` trả `null` ở nguồn DUPR thiếu tên

Đặt cạnh `resolveEloTier`; `EloTierBadge`, `RankTierBadge` và badge avatar gọi hàm này và không render khi `null`. Phương án bỏ: thêm cờ ở từng widget, dễ sót chỗ còn suy từ ELO.

### D2. `tierSource` nullable trong entity, thiếu thì coi là `ELO`

JSON từ Backend cũ không có field này, nên App phát hành trước Backend vẫn an toàn.

### D3. `EloTier` thêm `minValue`, `maxValue` kiểu `double?` và `tierSource`

Giữ `minElo`/`maxElo` như cũ cho nguồn `ELO`. `tier_legend_view.dart` chọn khoảng hiển thị theo `tierSource`: `ELO` dùng `minElo`–`maxElo`, `DUPR` dùng `minValue`–`maxValue` với 2 chữ số lẻ.

## Risks / Trade-offs

- [Sót màn còn tự suy từ ELO] → Grep mọi chỗ gọi `resolveEloTier`, `getShortTierCode`, `getEloTierProgress`; có widget test cho badge, tiến độ và chú giải.
- [Bản App cũ trên máy người dùng vẫn hiện badge theo ELO sau khi bật DUPR] → Chỉ bật nguồn DUPR sau khi bản App này đã phát hành và đa số đã cập nhật; ghi trong checklist bật của Backend.
