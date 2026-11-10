## Why
Luồng quản lý giải đấu của Ban tổ chức trên App Flutter chưa có E2E thật. Bộ `integration_test/` hiện có 19 file `flow_*_test.dart` gần như xanh giả (bọc `if (finder.evaluate().isNotEmpty)`, nhiều file 0 `expect`), `organizer_flow_test.dart` chỉ đi tới bước bốc thăm và xem sơ đồ. Nhập điểm, khai mạc, kết thúc giải, các thể thức, sân/khung giờ, cài đặt (nhà tài trợ, trọng tài, tài chính) và xóa giải chưa được kiểm trên emulator với Backend thật. Web đã có hành trình tương ứng (`test/e2e/journey-tournament.spec.ts`). Người dùng yêu cầu phủ mọi nút của luồng quản lý theo đúng tiến trình vòng đời, từ A đến Z như Web.

## What Changes
- Thêm `integration_test/support/organizer_journey.dart`: hàm dùng chung (đăng nhập BTC, dựng giải bằng API, mở hub, chuyển tab, bấm theo key) để các file hành trình không lặp mã.
- Mở rộng `integration_test/support/backend_api.dart`: `startTournament`, `completeTournament`, `scoreMatch` (chọn bên thắng), `getTournament`, `listVenues`, `listSponsors`.
- Thêm 4 file hành trình theo thứ tự vòng đời, mỗi file dùng app thật + Backend thật, `expect` chắc chắn, mỗi nút một bước có ảnh `shot()`:
  - `organizer_setup_journey_test.dart` (TC-QLGD-APP-01..19): tạo giải nhanh, sửa tổng quan, nội dung thi đấu (thêm, sửa, cấu hình vòng, khoá đăng ký, đăng ký hàng loạt, xóa), danh sách VĐV (thêm khách, tìm tài khoản, ghép đôi, tự ghép, đặc cách, VĐV ảo, mở Nhập Excel), chi tiết VĐV (duyệt, từ chối, check-in, phí, ghi chú, liên hệ).
  - `organizer_run_journey_test.dart` (TC-QLGD-APP-20..39): vòng đời (công bố, mở/đóng/mở lại đăng ký, khai mạc), bốc thăm (từng đội, hiện tất cả, làm lại, lưu và bắt đầu), tạo/xóa bracket, tab Kết quả (lọc, tìm, nhập điểm inline, thêm set, cảnh báo hòa, chốt lại), bàn điểm live, kết thúc giải, trang công khai.
  - `organizer_formats_journey_test.dart` (TC-QLGD-APP-40..59): vòng tròn, loại kép, vòng bảng (phân bảng), Swiss (ghép cặp, hoàn tác), vận hành giai đoạn, hạt giống và tự xếp hạt giống.
  - `organizer_schedule_settings_journey_test.dart` (TC-QLGD-APP-60..79): sân, khung giờ, xếp lịch (chọn ô, sheet hành động trận, xếp nhiều trận), nhà tài trợ, trọng tài, tài chính, chia sẻ, xuất dữ liệu, xóa giải.
- Cập nhật `integration_test/README.md`.

## Out of scope
- Quay video emulator: workflow `test-runner.yml` (repo `babydanh/agent-orchestrator`) chưa có `screenrecord`; chỉ làm khi người dùng cho phép sửa repo đó. Ảnh từng bước vẫn chụp bằng `shot()`.
- Sửa 19 file `flow_*_test.dart` xanh giả: để change riêng.
- Không sửa code sản phẩm, không đổi endpoint hay field. Test đỏ vì bug thật thì ghi lại và báo, không sửa trong change này.
- Tài khoản test hardcode trong `backend_api.dart`: giữ nguyên, chỉ nêu trong báo cáo.
- Những thứ không thao tác được bằng giao diện thuần trên emulator: file picker Excel (chỉ kiểm mở/đóng sheet), DatePicker/chọn tỉnh/upload ảnh (dựng bằng API), kéo-thả (dùng đường thay thế bằng chạm), thanh toán phí công bố (App chặn, làm ở Web). Nút nào không bấm được thì test ghi rõ lý do bằng `markTestSkipped`-tương đương có thông báo, không nuốt im lặng.
- Không thêm package.

## Capabilities
### New Capabilities
- `app-e2e-quan-ly-giai`: bộ integration test hành trình quản lý giải đấu của Ban tổ chức trên App.

### Modified Capabilities
(không)

## Impact
- Chỉ thêm hoặc sửa file dưới `integration_test/`; repo khác không bị ảnh hưởng.
- Chạy cloud: `cloud-test-runner.py run --target app-e2e --app-ref app-e2e-quan-ly-giai --specs integration_test/<file>_test.dart`; nhánh phải đã push, mỗi lần một run vì mỗi file là một lần Gradle build.
