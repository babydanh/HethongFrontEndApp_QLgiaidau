## Why

Web ẩn khối "người sáng lập / Ban tổ chức" mặc định (`contactInfo.hidden` vắng hoặc `true` = ẩn, chỉ `false` mới hiện; `displayMode: MANUAL` cũng ẩn). App bỏ qua cờ này nên vẫn hiện tên và avatar người tạo giải.

## What Changes

- Thêm getter `Tournament.showFounder` phản chiếu `isFounderHidden` của Web.
- Ba tab chi tiết giải (`intro_tab`, `overview_tab`, `about_tab`) chỉ vẽ khối người sáng lập khi `showFounder` là true; huy hiệu môn ở `about_tab` vẫn giữ.

## Out of scope

- Nút bật/tắt con mắt ở App (Web có ở trang quản lý) — chưa yêu cầu.
- Backend: `GET /tournaments/:id` vẫn trả `creator`/`organizer`/`createdBy` bất kể cờ; sửa là đổi hợp đồng API, làm change riêng.
- Logic quyền dựa trên `creatorId` giữ nguyên.

## Capabilities

### New Capabilities

- `app-founder-visibility`: App tôn trọng cờ ẩn người sáng lập như Web.

### Modified Capabilities

(không)

## Impact

`lib/domain/entities/tournament.dart`, `lib/features/tournament/widgets/{intro,overview,about}_tab.dart`, test tương ứng.
