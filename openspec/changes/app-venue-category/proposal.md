## Why
Backend vừa có danh bạ ~3.000 sân 5 môn, tham số tuỳ chọn `categoryId` cho `GET /social-locations/search` và trường `isVerified` ở phản hồi. App chưa gửi `categoryId` nên tạo/sửa buổi giao lưu môn Pickleball vẫn có thể gợi ý sân bóng đá, và không phân biệt sân đã xác minh.

## What Changes
- `ISocialLocationRepository.search` thêm tham số tên tuỳ chọn `String? categoryId`; `BackendSocialLocationRepository` chỉ gửi `categoryId` khi khác null.
- Màn tạo/sửa buổi giao lưu truyền `CategoryModel.id` của môn đang chọn xuống `SocialLocationFlow`; đổi môn thì kết quả cũ bị bỏ và tìm lại.
- `SocialPlace.isVerified` (mặc định `false`), đọc từ phản hồi; dòng gợi ý hiện nhãn "Đã xác minh".
- Khi có `bias`: sắp theo khoảng cách, nhưng sân đã xác minh đứng trước nếu chênh lệch dưới 200 m.

## Out of scope
Backend, Web, giao diện bản đồ, nguồn gợi ý ngoài danh bạ nội bộ. Hybrid/Api (Photon) repo bỏ qua `categoryId` có chủ ý.

## Capabilities
### Modified Capabilities
- `social-venue-search`: tìm sân theo môn, ưu tiên sân đã xác minh.

## Impact
`lib/domain/repositories/social_location_repository.dart`, ba repo cài đặt, `lib/data/models/social_place.dart`, `social_location_flow.dart`, `create_social_screen.dart`, arb vi/en; test `test/features/social_location_flow_test.dart`, `test/backend_social_location_repository_test.dart`.
