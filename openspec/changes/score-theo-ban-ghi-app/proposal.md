## Why

Khi App phát lại bản ghi, bảng điểm trên video đang hiện điểm hiện tại của trận (điểm cuối), không theo diễn biến lúc quay. Backend sắp trả thêm `scoreEvents` trên timeline phát lại (`GET /livestream/matches/{matchId}/replay`); App cần đọc và vẽ bảng điểm đúng giây video, như đã làm cho H2H và Sơ đồ bằng `overlayEvents` (change `replay-overlay-app`).

Phạm vi: **chỉ App**. Hợp đồng Backend (chưa lên main) là nguồn sự thật.

## What Changes

- Model `MatchReplay` đọc thêm `scoreEvents: [{ offsetSec, p1SetsWon, p2SetsWon, scoreDetails }]`; bỏ qua phần tử sai dạng, vắng thì rỗng, danh sách bất biến, sắp theo `offsetSec`.
- Hàm thuần `matchReplayScoreAt(events, seconds)` trả sự kiện cuối có `offsetSec <= seconds`, hoặc null nếu chưa có.
- Màn live/replay: khi đang phát lại và `scoreEvents` không rỗng, bảng điểm trên video lấy `p1SetsWon`/`p2SetsWon`/`scoreDetails` từ sự kiện đó, dùng lại đúng widget bảng điểm hiện có. Trước sự kiện đầu tiên bảng hiện 0-0, chưa có set nào.
- `scoreEvents` rỗng/vắng, hoặc đang xem trực tiếp: giữ hành vi hiện nay.

## Impact

- Code: `lib/data/models/match_playback_model.dart`, `lib/features/match/widgets/match_replay_timeline.dart`, `lib/features/match/screens/live_score_screen.dart`.
- Test: model, hàm thuần, widget phát lại (TC-SCOREREPLAY-APP-01..13).
- Không đổi API, schema, không thêm package, không thêm chuỗi hiển thị.
- Chỉ bảng điểm trên video đổi; phần điểm ở khu thông tin dưới video vẫn là điểm hiện tại của trận.
