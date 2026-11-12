## Why
Trong tab Trận đấu của buổi Social, sau khi tạo trận host không thấy nút bấm điểm: hộp thoại kết quả mở với `showScoreboardAction: false` (chỉ còn "Lưu kết quả thủ công"), và thẻ trận không còn nút nào (commit 6c80103e đã bỏ nút "Bấm điểm").

## What Changes
- Sau khi tạo trận, hộp thoại kết quả hiện "Mở bảng điểm" theo cùng điều kiện với chạm thẻ (trận chưa COMPLETED và đã đăng nhập); chọn thì mở thẳng bảng bấm điểm live.
- Thẻ trận có nút "Bấm điểm" (icon scoreboard, cao 44) khi trận chưa COMPLETED và đã đăng nhập; bấm mở thẳng bảng bấm điểm live, chống bấm đúp. Chạm thẻ vẫn mở hộp thoại kết quả.
- i18n: thêm `social_matchScoreNow` ở `app_vi.arb` + `app_en.arb`.

## Out of scope
- Không đổi quyền: Backend là chốt (MATCH_SCORE_PERMISSION_REQUIRED hiện trong bảng bấm điểm). Không sửa Backend, endpoint, package.

## Capabilities
### New Capabilities
- `social-match-scoring`: lối vào bấm điểm trận trong tab Trận đấu của buổi Social.

### Modified Capabilities
(không)

## Impact
- `lib/features/social/widgets/match_tab/social_match_tab.dart`, `lib/l10n/app_{vi,en}.arb` (+ code sinh), `test/features/social/social_match_tab_test.dart`, `integration_test/social_run_journey_test.dart` (TC-SOCIAL-APP-11).
