# Handoff App: the-social-icon-mon

## Đã làm
- `lib/features/social/widgets/social_session_sport_icon.dart` (mới): SVG môn 32dp, `Semantics(image)` + `Tooltip` = tên môn (sportName, rỗng thì i18n theo slug).
- `lib/features/social/widgets/social_session_card.dart`: icon môn ở ĐẦU thẻ (bên trái, thay vòng tròn logo); bỏ icon outline Material cột phải; chip hình thức giữ nguyên. Thẻ không cao thêm (icon 32 < vòng tròn cũ 44).
- `lib/features/home/widgets/global_search_screen.dart` (`_sessionRow`): leading = cùng icon thay avatar CLB.
- Test: `test/features/social/social_session_sport_icon_test.dart` (TC-SOCIAL-ICON-01..03), `test/features/global_search_sessions_scope_test.dart` (TC-SOCIAL-ICON-04).

## Kiểm (mã thoát thật)
- Test mới trước khi viết widget: đỏ (thiếu `SocialSessionSportIcon`); sau sửa: 3/3 xanh.
- `flutter test --no-pub test/features/social test/features/global_search_sessions_scope_test.dart ...`: 61 pass, exit 0.
- `flutter analyze --no-pub lib/features/social lib/features/home/widgets/global_search_screen.dart test/features/social test/features/global_search_sessions_scope_test.dart`: 0 error, 0 warning; 41 info `deprecated_member_use` (import `material.dart`) có sẵn ở Flutter 3.50 nên exit 1. `openspec validate --strict`: exit 0.
- Máy cài Flutter 3.50 stable ở /data/home/flutter; tạo `.env` rỗng (git-ignored) chỉ để test chạy được.

## Ghi chú
- Chưa chụp ảnh thiết bị. Vị trí icon: đầu thẻ, bên trái tiêu đề.
- Thẻ kèo trong tab hoạt động CLB (`club_activity_tab._buildClubSocialSessionCard`) là widget riêng, không có chip môn, giữ nguyên.
- `pickleball` vẫn dùng `pickleball.png` theo `SportChoiceTile.buildSportIcon` (chưa đổi sang svg để không đụng chỗ khác).
