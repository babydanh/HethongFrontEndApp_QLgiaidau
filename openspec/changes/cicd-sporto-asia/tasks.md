## 1. Workflow và script

- [x] 1.1 Thêm `.github/workflows/cloud-test.yml` với `test-app` và `test-app-e2e`, input và `run-name` giống `test-runner.yml`. Tiêu chí: `yaml.safe_load` exit 0 và `bash -n` mọi khối `run:` exit 0
- [x] 1.2 Chép `flutter_json_to_allure.py`, `app_video_clips.py`, `allure_archive.py` + test vào `scripts/ci-e2e/`, bỏ `babydanh`. Tiêu chí: `python -X utf8 -m unittest discover -s scripts/ci-e2e -p "test_*.py"` exit 0
- [x] 1.3 Cập nhật `docs/README.md` (vị trí job E2E). Tiêu chí: không còn nhắc `test-runner.yml` của `agent-orchestrator` cho job App
