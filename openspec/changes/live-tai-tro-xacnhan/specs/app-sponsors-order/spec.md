## ADDED Requirements

### Requirement: Sắp xếp nhà tài trợ bằng kéo thả
The sponsors management screen SHALL let the organizer reorder sponsors by dragging a handle and SHALL persist the new order by updating `displayOrder` of each sponsor whose position changed.

#### Scenario: Kéo một nhà tài trợ lên đầu
- **WHEN** the organizer drags the second sponsor above the first
- **THEN** the app sends `displayOrder` 0 for the dragged sponsor and 1 for the other one, and no other field

### Requirement: Công tắc hiển thị công khai trên từng hàng
Each non-archived sponsor row SHALL show a switch that sets `status` to `PUBLISHED` with `isPublic` true when on, and `DRAFT` with `isPublic` false when off.

#### Scenario: Tắt hiển thị
- **WHEN** the organizer turns off the switch of a public sponsor
- **THEN** the app updates that sponsor with `status` DRAFT and `isPublic` false

### Requirement: Lưu trữ bằng vuốt trái có xác nhận
Swiping a sponsor row to the left SHALL ask for confirmation before archiving it.

#### Scenario: Huỷ xác nhận
- **WHEN** the organizer swipes a row left and cancels the confirmation
- **THEN** the sponsor is not archived and stays in the list

### Requirement: Xem trước trang công khai
The screen SHALL offer a preview of the public sponsors page that lists only sponsors that are published, public and not archived.

#### Scenario: Mở xem trước
- **WHEN** the organizer taps the preview row
- **THEN** a sheet lists only the public sponsors
