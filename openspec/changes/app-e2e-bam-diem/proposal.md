## Why
Cách bấm điểm các môn trên App (pickleball side-out, cầu lông, bóng bàn, tennis, bóng đá) mới chỉ có widget test không có hình. Người dùng cần bộ test chạy trên emulator Android, bấm đủ kiểu theo từng luật, có ảnh từng bước để xem lại như bản Web (TC-CBD-E2E-01..08).

## What Changes
- Thêm 4 file `integration_test/xem_bam_diem_*_test.dart` (pickleball, rally gồm cầu lông và bóng bàn, tennis, bóng đá) dùng notifier thật, repository ghi giả, không cần Backend.
- Thêm `integration_test/support/bam_diem.dart`: repo ghi giả, hàm dựng trận, hàm mở panel, hàm bấm theo nhãn.
- Mỗi bước bấm có ảnh chụp qua `XemShooter` (ảnh cuối lượt nằm trong report cloud).

## Out of scope
- Quay video emulator: workflow `test-runner.yml` (repo `babydanh/agent-orchestrator`) chưa có bước `screenrecord`; làm riêng sau, cần bạn cho phép sửa repo đó.
- Không đụng Backend thật, không sửa code sản phẩm; test đỏ vì bug thật thì ghi lại và báo, không sửa trong change này.
- Không thêm package.

## Capabilities
### New Capabilities
- `app-e2e-bam-diem`: bộ integration test bấm điểm mọi môn trên emulator.

### Modified Capabilities
(không)

## Impact
- Chỉ thêm file dưới `integration_test/`; repo khác không bị ảnh hưởng (không đổi endpoint hay field).
- Chạy cloud: `cloud-test-runner.py run --target app-e2e --app-ref app-e2e-bam-diem --specs integration_test/xem_bam_diem_*_test.dart` (nhánh phải đã push).
