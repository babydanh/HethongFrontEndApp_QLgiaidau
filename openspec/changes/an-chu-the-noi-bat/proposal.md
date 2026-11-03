## Why
Chủ giải bấm mắt "ẩn chữ trên banner" nhưng thẻ nổi bật ở trang chủ vẫn hiện tên giải: App không đọc cờ `hideFeaturedCardText` ở thẻ này (chỉ trang chi tiết đọc, và chỉ bỏ lớp mờ).

## What Changes
- `HomeFeaturedTournament` đọc `hideFeaturedCardText` từ API trang chủ (mặc định `false`).
- `FeaturedTournamentBannerCard` không vẽ tên giải và lớp mờ tối khi cờ bật; huy hiệu môn và trạng thái đăng ký giữ nguyên.

## Out of scope
- Không đổi mắt ở màn Quản lý (đã lưu đúng). Không đổi thẻ kết quả `TournamentCardWithBanner`.
- Backend trả cờ là change cùng tên ở repo Backend; khi Backend chưa deploy, App coi như `false` (hành vi cũ).

## Capabilities
### New Capabilities
- (không)

### Modified Capabilities
- `home-featured-card`: ẩn tên giải theo cờ của chủ giải.

## Impact
- Sửa `lib/data/models/home_projection.dart`, `lib/features/home/widgets/featured_tournament_banner_card.dart`; test `test/features/featured_card_hide_text_test.dart`.
