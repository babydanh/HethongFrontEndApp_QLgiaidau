## 1. Hạ tầng dùng chung

- [x] 1.1 Tạo `support/bam_diem.dart`: repo ghi giả (`updateScoreDetails` nuốt), `matchFixture({doubles})`, `pumpPanel(tester, panel, state)`, `tapLabel(tester, text)`. Tiêu chí: `flutter analyze --no-pub integration_test/support` → exit 0
  - Files: tạo `integration_test/support/bam_diem.dart`
  - Giao: `Future<void> pumpPanel(WidgetTester tester, Widget panel, ScorePanelState state, {bool doubles = false})` · Nhận: `xemApp`, `XemShooter` từ `support/xem.dart`
  - Chủ file chung: 1.1 giữ file mới; 2.1–2.4 chỉ đọc
  - Phụ thuộc: (không)

## 2. Test từng môn (4 file độc lập, chạy sau 1.1)

- [x] 2.1 `xem_bam_diem_pickleball_test.dart`: TC-CBD-APP-01 đôi Giao 1→Giao 2→đổi giao, 01b đơn đổi giao ngay, 02 Lite rally không có giao bóng. Tiêu chí: `flutter analyze --no-pub integration_test/xem_bam_diem_pickleball_test.dart` → exit 0 và chạy cloud xanh
  - Files: tạo `integration_test/xem_bam_diem_pickleball_test.dart`
  - Giao: (không) · Nhận: `pumpPanel` từ 1.1
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.1
- [x] 2.2 `xem_bam_diem_rally_test.dart`: 03 cầu lông ô phải/trái, 03b 20-20, 04 bóng bàn đổi giao mỗi 2 điểm, 04b 10-10. Tiêu chí: như 1.2
  - Files: tạo `integration_test/xem_bam_diem_rally_test.dart`
  - Giao: (không) · Nhận: `pumpPanel` từ 1.1
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.1
- [x] 2.3 `xem_bam_diem_tennis_test.dart`: 05 15-30-40/Deuce, 05b tie-break 6-6, 06 No-Ad, 07 match tie-break 10 điểm. Tiêu chí: như 1.2
  - Files: tạo `integration_test/xem_bam_diem_tennis_test.dart`
  - Giao: (không) · Nhận: `pumpPanel` từ 1.1
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.1
- [x] 2.4 `xem_bam_diem_bongda_test.dart`: 08 ghi bàn, thẻ vàng×2→đỏ, phạt đền, đổi hiệp, dưới 7 người, ghi bàn ngoài hiệp. Tiêu chí: như 1.2
  - Files: tạo `integration_test/xem_bam_diem_bongda_test.dart`
  - Giao: (không) · Nhận: `pumpPanel` từ 1.1
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.1

## 3. Kiểm tra cuối

- [ ] 3.1 `flutter analyze --no-pub integration_test` rồi push nhánh và chạy cloud. Tiêu chí: `flutter analyze --no-pub integration_test` → exit 0; `cloud-test-runner.py run --target app-e2e --app-ref app-e2e-bam-diem --specs integration_test/xem_bam_diem_pickleball_test.dart integration_test/xem_bam_diem_rally_test.dart integration_test/xem_bam_diem_tennis_test.dart integration_test/xem_bam_diem_bongda_test.dart` → exit 0
  - Files: (không sửa file)
  - Giao: (không) · Nhận: 1.1, 2.1–2.4
  - Chủ file chung: (không)
  - Phụ thuộc: sau 2.1–2.4
