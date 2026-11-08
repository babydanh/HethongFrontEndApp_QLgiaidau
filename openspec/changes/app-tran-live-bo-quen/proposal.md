## Why

Trận ONGOING bị bỏ quên (BTC quên bấm Kết thúc) vẫn hiện nhãn LIVE đỏ trên App và người xem tưởng trận còn đấu. Backend (change song song) đã gắn cờ `isStaleLive` (ngưỡng 12 giờ tính ở Backend) và `lastActivityAt` vào response trận, cùng thông báo `MATCH_STALE_LIVE` cho BTC. App cần đọc cờ và hiện đúng. Điểm và status KHÔNG đổi (phương án A).

## What Changes

- `MatchModel` đọc `isStaleLive` (thiếu key = `false`) và `lastActivityAt` (thiếu = `null`); `isLive` giữ nguyên để BTC và màn chấm điểm vẫn coi là trận đang đấu.
- Bộ lọc "live" (`MatchStatusFilter.live`) loại trận stale.
- Người xem: thẻ trận (`LiveMatchCardV2`, thẻ ở `/matches`), màn live theo giải, màn xem trận hiện nhãn "Tạm dừng" thay LIVE; màn live theo giải tách nhóm "Tạm dừng" riêng.
- BTC: thẻ trận ở Vận hành giải và màn xem/chấm điểm hiện lời nhắc "Chưa cập nhật N giờ, hãy kết thúc hoặc hủy trận" (dùng lại nút Kết thúc/Bỏ dở sẵn có, không thêm nút).
- Thông báo `MATCH_STALE_LIVE`: mở đúng trận, icon và màu cảnh báo.
- Không tự tính ngưỡng giờ ở App; chỉ đọc cờ.

## Impact

- Code: `lib/domain/entities/match.dart`, `lib/domain/entities/app_notification.dart`, `lib/core/utils/match_status_filter.dart`, `lib/core/widgets/match_card/`, `lib/features/live`, `lib/features/match`, `lib/features/organizer_ops`, `lib/l10n/*.arb`.
- Phụ thuộc hợp đồng Backend: `isStaleLive`, `lastActivityAt`, type `MATCH_STALE_LIVE`. Backend cũ (thiếu key) cho hành vi như hiện tại.
