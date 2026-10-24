# app-multi-division-registration Specification

## Purpose
Màn đăng ký giải trên App xét đơn đăng ký theo từng nội dung (đọc `GET /tournaments/:id/my-registrations`): đơn ở nội dung khác không chặn việc đăng ký nội dung đang chọn, còn trạng thái, thanh toán và rút lui chỉ hiện cho đúng nội dung đã đăng ký.

## Requirements

### Requirement: Registration state is scoped to a tournament division

The App MUST show an existing registration's status and actions only when its division is selected. An existing registration in another division MUST NOT prevent selecting or submitting a registration for the selected division. A registration already present in the selected division MUST continue to prevent a second client-side submission.

#### Scenario: User has an existing registration in another division

- **WHEN** the user opens the tournament registration screen with a different division selected
- **AND** `GET /tournaments/:id/my-registrations` returns a registration for the user's other division
- **THEN** the App shows the selected division's registration form
- **AND** the user can choose that other division from the existing-registration view

#### Scenario: User selects the division with an existing registration

- **WHEN** the selected division has a non-closed registration
- **THEN** the App shows that registration's existing status and payment/withdrawal actions
- **AND** a second submit for that division is blocked

#### Scenario: Registration is withdrawn or otherwise closed

- **WHEN** the selected division's registration has status `WITHDRAWN`, `REJECTED`, `KICKED`, or `EXPIRED`
- **THEN** the App does not treat it as an active registration blocking a new application

### Requirement: Existing registration endpoint remains compatible

The App change MUST NOT alter the behavior or contract of `GET /tournaments/:id/my-registration`. The new list consumer MUST read the success envelope's `data` array, whose elements use the existing my-registration payload shape and identify the division through `participant.tournamentDivisionId`.

#### Scenario: Existing endpoint behavior remains unchanged

- **WHEN** an older App version requests `GET /tournaments/:id/my-registration`
- **THEN** it continues to receive the existing single-registration response shape
