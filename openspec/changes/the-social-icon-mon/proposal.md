## Why

Thẻ buổi giao lưu trên App thể hiện môn bằng icon Material rời rạc (vòng tròn CLB ở đầu + icon outline ở cột phải). Chủ repo muốn chỉ dùng icon SVG của môn, đặt ở ĐẦU thẻ, cả ở danh sách kèo lẫn kết quả tìm kiếm.

## What Changes

- Thêm `SocialSessionSportIcon` (SVG của môn qua `SportChoiceTile.buildSportIcon`, 32dp, `Semantics` + `Tooltip` = tên môn).
- `SocialSessionCard`: icon môn ở đầu thẻ thay vòng tròn logo; bỏ icon outline ở cột phải. Giữ tiêu đề, chip hình thức, sân, số chỗ, khoảng cách.
- Tìm kiếm toàn cục, scope Kèo (`_sessionRow`): dùng cùng icon làm leading thay avatar CLB.

## Out of scope

- Không đổi Backend/API, không thêm asset/package; thẻ kèo trong tab hoạt động CLB (`club_activity_tab`) giữ nguyên.

## Capabilities

### New Capabilities
- `social-session-card-sport-icon`: thẻ buổi giao lưu trên App thể hiện môn bằng icon SVG ở đầu thẻ.

## Impact

- `lib/features/social/widgets/social_session_sport_icon.dart` (mới), `social_session_card.dart`, `lib/features/home/widgets/global_search_screen.dart`, test `test/features/social/social_session_sport_icon_test.dart`, `test/features/global_search_sessions_scope_test.dart`.
