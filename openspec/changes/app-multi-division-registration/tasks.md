## Implementation

- [x] Scope registration lookup and status presentation to the currently selected division.
- [x] Consume the multi-registration endpoint without changing the existing single-registration route or registration POST contract.
- [x] Keep the current division's status/payment/withdrawal flow and expose other active divisions from the existing-registration view.
- [x] Add TC-coded App regression coverage for list loading and division-scoped guards.
- [x] Record App scope and Feature Impact Review in the proposal.

## Verification

- [x] Run `flutter test --no-pub test/registration/tournament_register_multi_division_test.dart`. (2026-10-24: 2/2 pass; cần file `.env` vì pubspec khai làm asset, chạy với `.env` rỗng.)
- [x] Run `flutter analyze --no-pub lib/features/register/screens`. (2026-10-24: 0 error; 1 warning có sẵn trên main ở `doubles_registration_screen.dart:541`, file nhánh này không sửa; còn mục info.)
