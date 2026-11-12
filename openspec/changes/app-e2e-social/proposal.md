## Why
Tính năng Social (buổi giao lưu) trên App mới có widget test, chưa có kịch bản chạy trên emulator với Backend thật. Cần E2E phủ luồng tạo buổi, Khám phá, chi tiết, người tham gia, trận đấu, trò chuyện, thanh toán, sửa/huỷ và quyền (TC-SOCIAL-APP-01..18), có ảnh từng bước.

## What Changes
- Thêm 3 file `integration_test/social_{create,run,chat}_journey_test.dart` (emulator Android + Backend thật + Postgres + Redis, chạy trên cloud).
- Thêm `integration_test/support/social_journey.dart`: client API Social, đăng nhập bằng form, mở buổi, bấm tab, chụp ảnh `shot()`.
- Thêm `integration_test/README.md` mục Social.

## Out of scope
- Không sửa `lib/`, endpoint, field, package; không sửa `support/backend_api.dart` và `organizer_journey.dart`.
- Ghim vị trí trên bản đồ, gửi/dán ảnh (hộp chọn ảnh hệ thống) và chia sẻ (hộp chia sẻ hệ thống) không điều khiển được trên emulator: test skip có lý do trong tên.
- Bug sản phẩm tìm thấy chỉ ghi lại, không sửa trong change này.

## Capabilities
### New Capabilities
- `app-e2e-social`: bộ integration test luồng Social trên emulator.

### Modified Capabilities
(không)

## Impact
- Chỉ thêm file dưới `integration_test/` và `openspec/`. Chạy cloud: workflow `test-runner.yml` (repo `babydanh/agent-orchestrator`) target `app-e2e`, từng file một.
