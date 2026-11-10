## Why
Màn chi tiết buổi giao lưu hiện avatar của host hai lần: một ở thẻ Host, một ở đầu hàng người tham gia ngay dưới.

## What Changes
- Hàng người tham gia chỉ liệt kê người khác host; host chỉ hiện ở thẻ Host. Số "x/y" giữ nguyên.

## Impact
- `lib/features/social/widgets/detail_tab/social_details_tab.dart`
- Test: `test/features/social/social_details_tab_test.dart` (TC-GL-AVATAR-01)
