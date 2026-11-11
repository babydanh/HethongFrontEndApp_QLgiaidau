## 1. Hạ tầng dùng chung

- [x] 1.1 Tạo `integration_test/support/social_journey.dart`. Tiêu chí: `flutter analyze --no-pub integration_test` → 0 vấn đề
  - Files: tạo `integration_test/support/social_journey.dart`
  - Phụ thuộc: (không)

## 2. Test từng nhóm (3 file, chạy cloud từng file một)

- [x] 2.1 `social_create_journey_test.dart`: TC-SOCIAL-APP-01..04 (tạo buổi, báo lỗi bắt buộc, chọn sân đã lưu, Khám phá một mốc). Tiêu chí: run cloud xanh
  - Files: tạo `integration_test/social_create_journey_test.dart`
  - Phụ thuộc: sau 1.1
- [x] 2.2 `social_run_journey_test.dart`: TC-SOCIAL-APP-05..12 (chi tiết, Chỉ đường, xin tham gia/rút/duyệt, thêm/xoá người, FULL, avatar host, trận Đôi, Bracket). Tiêu chí: run cloud xanh
  - Files: tạo `integration_test/social_run_journey_test.dart`
  - Phụ thuộc: sau 1.1
- [x] 2.3 `social_chat_journey_test.dart`: TC-SOCIAL-APP-13..18 (chat, sửa/huỷ, thanh toán, quyền, hai ca skip có lý do). Tiêu chí: run cloud xanh
  - Files: tạo `integration_test/social_chat_journey_test.dart`
  - Phụ thuộc: sau 1.1

## 3. Tài liệu

- [x] 3.1 Cập nhật `integration_test/README.md` mục Social
  - Files: tạo/sửa `integration_test/README.md`
  - Phụ thuộc: sau 2.3
