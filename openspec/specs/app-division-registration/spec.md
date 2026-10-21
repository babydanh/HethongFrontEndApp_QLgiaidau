# app-division-registration Specification

## Purpose
App cho VĐV đăng ký theo trạng thái mở/đóng của từng nội dung do server trả, kể cả khi giải đang diễn ra; server cũ thì tự tính theo hạn như trước.

## Requirements

### Requirement: App đăng ký theo trạng thái từng nội dung

The app SHALL let athletes pick only divisions whose `registrationOpen` is true and SHALL show the closed reason for the others. The tournament intro screen SHALL show the register action while at least one division is open, including when the tournament is in progress. When the server does not send `registrationOpen`, the app SHALL fall back to its current deadline and capacity checks.

#### Scenario: Tournament in progress with one open division

- **WHEN** the tournament is in progress and only division B is open
- **THEN** the intro screen shows Đăng ký and the register screen offers only B

#### Scenario: All divisions closed

- **WHEN** every division has `registrationOpen` false
- **THEN** the intro screen hides Đăng ký and the register screen lists each division with its closed reason

#### Scenario: Older server

- **WHEN** the division payload has no `registrationOpen`
- **THEN** the app decides from `effectiveRegistrationEndDate` and capacity as before
