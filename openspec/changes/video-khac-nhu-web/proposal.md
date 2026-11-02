## Why
Tab "Video khác" ở trang xem live đang đưa cả trận bye và trận đã có người thắng, và bỏ sót trận trạng thái PLAYING. Web (`LiveMatchesTab.tsx`, `isVisibleLiveMatch`) đã loại các trường hợp này.

## What Changes
- `pickLiveSuggestions` dùng đúng điều kiện của Web: coi `PLAYING` là đang diễn ra; bỏ trận bye, trận đã hoàn tất, trận đã có `winnerId`.

## Out of scope
- Không đổi `MatchModel.isLive` (dùng chung nhiều màn).
- Không thêm live của giải khác, không đổi giao diện thẻ.

## Capabilities
### New Capabilities
- `live-viewer-suggestions`: lọc gợi ý "Video khác" theo luật Web.
### Modified Capabilities
(không)

## Impact
- `lib/features/match/widgets/viewer/live_viewer_suggestions.dart`
- `test/features/match/live_viewer_suggestions_test.dart`
