# camera-tab-merge Specification

## Purpose
Ban tổ chức quản lý camera của giải ở một chỗ: tab Camera trong màn quản lý giải. Mục "Phát trực tiếp" mở thẳng tab này, khối trận chỉ liệt kê trận chưa có sân, popup sân gom việc đổi, xoá, lấy QR camera và sửa URL phát.

## Requirements

### Requirement: Tab Camera là nơi duy nhất quản lý camera

Ứng dụng SHALL đưa mọi thao tác camera của giải (gán/đổi camera cho sân, QR stream key, xoá camera, URL phát, kiểm tra tín hiệu) vào tab Camera; mục "Phát trực tiếp" ở menu quản lý MUST mở tab Camera thay vì một màn riêng có danh sách camera.

#### Scenario: Mở "Phát trực tiếp" từ menu quản lý

- **WHEN** ban tổ chức bấm mục "Phát trực tiếp" trong menu quản lý
- **THEN** tab Camera được chọn và không có màn danh sách camera riêng nào mở ra

#### Scenario: Khối trận chỉ còn trận chưa có sân

- **WHEN** mọi trận chưa xong đều đã được xếp sân và không có lọc nào bật
- **THEN** tab Camera không hiện khối "Trận chưa có sân"

#### Scenario: Popup sân gọn

- **WHEN** ban tổ chức mở popup một sân đã gán camera PUSH
- **THEN** popup có một dòng camera với nút Đổi và nút QR, ô URL nằm thu gọn trong "Sửa URL phát", và không có dòng "Đang chiếu"
