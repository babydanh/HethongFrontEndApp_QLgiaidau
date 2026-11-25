## ADDED Requirements

### Requirement: Repo App tự chạy cloud test của chính nó

Repo App MUST có workflow `.github/workflows/cloud-test.yml` chạy bằng `workflow_dispatch`, nhận cùng tên input với `test-runner.yml` cũ (`target_project`, `custom_branch`, `web_ref`, `backend_ref`, `app_ref`, `specs`, `request_id`, `fail_fast`, `seed`, `no_report`) và đặt `run-name` chứa `#<request_id>`. Job `test-app` SHALL chạy với target `app`; job `test-app-e2e` SHALL chạy với target `app-e2e`, checkout Backend bằng `QLGD_CI_TOKEN` và lưu kho Allure vào `<owner>/qlgd-e2e-archive`.

#### Scenario: Dispatch target app-e2e có request_id

- **WHEN** `cloud-test-runner.py` dispatch `cloud-test.yml` với `target_project=app-e2e` và `request_id=abc123`
- **THEN** lượt chạy có tên chứa `#abc123`, chỉ job `test-app-e2e` chạy, Backend được checkout từ `backend_ref` (trống thì `main`)

#### Scenario: Spec sai định dạng hoặc thiếu kết quả test

- **WHEN** `specs` chứa file không khớp `integration_test/*_test.dart` hoặc chứa `..`
- **THEN** bước kiểm spec báo `::error::` và job dừng trước khi bật emulator
- **WHEN** test không chạy tới (không có `flutter-test.json`)
- **THEN** bước Allure bỏ qua, không lưu kho và không đổi kết quả job
