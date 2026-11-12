# Handoff: app-venue-category
Cập nhật: 2026-11-12 · bởi: claude · nhánh: cloud/danh1-app-venue-category · OpenSpec: app-venue-category

## Mục tiêu
Tìm sân theo môn đang chọn (gửi `categoryId`), ưu tiên sân đã xác minh. Xem `proposal.md`.

## Trạng thái
- Xong: repository + interface + 3 cài đặt + fake test; `SocialPlace.isVerified`; truyền môn từ `create_social_screen`; nhãn "Đã xác minh"; test TC-VENUE-01..10 xanh (`cloud-flutter test --no-pub test/features/social_location_flow_test.dart test/backend_social_location_repository_test.dart`, exit 0, 15 test).
- Đang dở: không.
- Tiếp theo: khi staging nạp dữ liệu sân, thử tay tạo buổi Pickleball để xem gợi ý.

## Kết quả bước 2 (môn → uuid)
Có sẵn: `CategoryModel.id` (`lib/providers/category_provider.dart`, từ `GET /categories`). Màn tạo giữ `slug`; `_selectedCategoryId()` tra `id` theo slug trong danh mục đang bật. Môn đã gỡ khỏi danh mục bật → `null` → không lọc theo môn.

## Đã thử
| Cách | Kết quả | Vì sao |
|---|---|---|
| Sắp xếp xác minh-trước khi chênh < 200 m bằng comparator từng cặp | thành công | TC-VENUE-04/05. Không bắc cầu tuyệt đối nhưng tối đa 10 mục, `List.sort` không ném lỗi |
| `social_nearby_filter.dart` truyền `categoryId` | bỏ có chủ ý | bộ lọc gần đây không gắn với một môn |
| Hybrid/Api (Photon) dùng `categoryId` | bỏ có chủ ý | Photon không có danh mục; có comment |

## Ràng buộc đang có
- Không sửa Backend/Web; tham số mới chỉ tuỳ chọn có tên (nguồn: yêu cầu).
- Staging chưa có dữ liệu sân nên test dùng adapter/fake.

## Ràng buộc thay đổi lần này
- Không đổi (đã so).

## Câu hỏi còn mở
- Không. (`flutter analyze` thư mục đã sửa còn cảnh báo/info cũ ở file khác, không do thay đổi này.)
