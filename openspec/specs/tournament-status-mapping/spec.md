# tournament-status-mapping Specification

## Purpose
Ánh xạ trạng thái giải từ Backend sang trạng thái hiển thị trên App; chỉ REGISTRATION_OPEN được coi là đang mở đăng ký.

## Requirements

### Requirement: Chỉ trạng thái tường minh được coi là đang mở đăng ký
App MUST coi giải là "đang mở đăng ký" khi và chỉ khi trạng thái là `REGISTRATION_OPEN`. `PUBLISHED`, `ACTIVE`, `OPEN`, `REGISTRATION`, `REGISTER_OPEN` và mọi chuỗi chỉ vì chứa `REGIST` hoặc `OPEN` MUST NOT được coi là đang mở đăng ký.

#### Scenario: Trạng thái chuẩn
- **WHEN** trạng thái là `REGISTRATION_OPEN`
- **THEN** giải được coi là đang mở đăng ký

#### Scenario: Trạng thái cũ hoặc không có trong backend
- **WHEN** trạng thái là `PUBLISHED` hoặc `ACTIVE`
- **THEN** giải KHÔNG được coi là đang mở đăng ký

#### Scenario: Chuỗi lạ chứa từ khoá
- **WHEN** trạng thái là `SOMETHING_OPEN_LATER`
- **THEN** giải không được coi là đang mở đăng ký, và nhãn hiện đúng `something_open_later` thay vì "Sắp diễn ra"

#### Scenario: Không có trạng thái
- **WHEN** trạng thái là null hoặc chuỗi rỗng
- **THEN** giải được coi là "sắp diễn ra" như trước
