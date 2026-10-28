## ADDED Requirements

### Requirement: Khối Liên hệ ở tab Tổng quan

Tab Tổng quan SHALL hiện khối "Liên hệ" ngay dưới khối Ban tổ chức khi `contactInfo` có nội dung được phép hiển thị, và MUST NOT thay đổi bố cục hay thành phần sẵn có của tab.

#### Scenario: Chế độ nhập tay luôn hiện
- **WHEN** `displayMode` là `MANUAL`, `organizerName` và `phone` có giá trị, `hidden` vắng, người xem không phải quản lý
- **THEN** khối Liên hệ hiện tên và điện thoại, không hiện email

#### Scenario: Chế độ hồ sơ đang công khai
- **WHEN** `displayMode` là `PROFILE` (hoặc vắng), `hidden` đúng bằng `false`, có `phone` và `email`
- **THEN** khối Liên hệ hiện điện thoại và email

#### Scenario: Chế độ hồ sơ đang ẩn với người xem
- **WHEN** `displayMode` là `PROFILE` (hoặc vắng), `hidden` vắng hoặc `true`, người xem không phải quản lý
- **THEN** không vẽ khối Liên hệ và không có SĐT/email nào xuất hiện trong cây widget

#### Scenario: Quản lý thấy cả khi ẩn
- **WHEN** người xem là quản lý (có nút con mắt) và `hidden` khác `false`, có `phone`
- **THEN** khối Liên hệ hiện điện thoại kèm dòng "Đang ẩn với người xem"

### Requirement: Dữ liệu liên hệ trống hoặc sai kiểu

Hệ thống SHALL không vẽ khối Liên hệ khi không còn giá trị nào để hiện và MUST NOT ném lỗi với `contactInfo` null, thiếu khoá hoặc sai kiểu.

#### Scenario: Chuỗi rỗng và khoảng trắng
- **WHEN** `phone` và `email` chỉ gồm khoảng trắng hoặc không phải chuỗi
- **THEN** không vẽ khối Liên hệ và không có lỗi

#### Scenario: Màn hẹp
- **WHEN** email dài hiển thị ở viewport 320 dp
- **THEN** văn bản xuống dòng, không có RenderFlex overflow
