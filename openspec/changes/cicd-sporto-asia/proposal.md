## Why

Repo `babydanh/agent-orchestrator` (CI/CD trung tâm, public) bị GitHub khoá ngày 2026-11-25, nên hai job test của App (`test-app`, `test-app-e2e` trong `test-runner.yml` của repo đó) không chạy được nữa. Các repo đã chuyển sang org `sporto-asia` (private, có phút Actions): mỗi repo tự test chính nó bằng workflow trong `.github/workflows/` của mình.

## What Changes

- Thêm `.github/workflows/cloud-test.yml` (chỉ `workflow_dispatch`), cùng tên input và cùng mẫu `run-name` (`#<request_id>`) với `test-runner.yml` cũ để `~/.omp/scripts/cloud-test-runner.py` gửi y hệt. Hai job giữ id: `test-app` (target `app`) và `test-app-e2e` (target `app-e2e`, emulator Android API 34 + Backend thật).
- App checkout bằng token mặc định; Backend (`sporto-asia/HethongBackendApi_QuanlyGiaiDau`, ref `backend_ref`) và kho Allure `sporto-asia/qlgd-e2e-archive` dùng secret `QLGD_CI_TOKEN`.
- Chép script hỗ trợ E2E vào `scripts/ci-e2e/`: `flutter_json_to_allure.py`, `app_video_clips.py`, `allure_archive.py` cùng test Python của chúng; kho mặc định đổi sang `sporto-asia/qlgd-e2e-archive`.
- Cập nhật `docs/README.md` trỏ tới workflow mới.

## Out of scope

- Không sửa `ci.yml`, `deploy-ios.yml`, `secret-scan.yml`.
- Không chép `app_ui_runner.py`, `flutter_to_allure.py` (chỉ job itservice dùng), không port job khác của `test-runner.yml`, không có `schedule:`.
- Không đổi `cloud-test-runner.py` (đã trỏ `sporto-asia` + `cloud-test.yml`).

## Impact

- Repo khác: chỉ đọc Backend `HethongBackendApi_QuanlyGiaiDau` (checkout) và ghi Release của `qlgd-e2e-archive`; không đổi endpoint hay field nào.
- Secret cần có ở repo App: `QLGD_CI_TOKEN` (đọc Backend, ghi `qlgd-e2e-archive`).
