## Why

Khu quản lý giải của Web có tab **Kết quả** (bảng nhập điểm theo vòng) và thanh **Tiến trình** bấm vào từng bước thì mở popup việc cần làm. App chưa có hai thứ này:

- Hub quản lý của App chỉ có 6 tab (Tổng quan, Nội dung, VĐV, Sơ đồ, Lịch, Cài đặt), không có tab Kết quả. Bảng trận `ResultsMatchBoard` đã có nhưng chỉ nằm ở màn công khai của giải.
- `LifecycleStepBar` ở App không bấm được (không có callback), nên ban tổ chức không xem được mỗi bước còn thiếu gì, phải tự đoán rồi mò từng tab.

## What Changes

- Thêm tab **Kết quả** vào hub quản lý, dùng lại `ResultsMatchBoard` với quyền quản lý, thêm 3 chip lọc còn thiếu so với Web (Chưa xong, Trễ giờ, Tranh chấp) và cho phép mở sẵn một bộ lọc từ nơi khác.
- Bấm vào từng bước của thanh tiến trình mở popup như Web: vòng phần trăm, danh sách "việc cần làm" có nút "Đi tới", và phần "Theo từng nội dung" (tìm, lọc "Chỉ hiện thiếu").
- Thêm phần tính số liệu từng bước (port rút gọn luật của Web `tournament-step-summary`) thành hàm thuần Dart có test.
- Thêm chuỗi vi/en cho toàn bộ phần trên.

## Out of scope

- Không đổi Backend, không đổi Web, không thêm endpoint (mọi dữ liệu lấy từ endpoint đã có).
- Không làm lại popup xác nhận "Khai mạc giải", "Hoàn tất giải đấu" (App đã có `LifecycleOpeningSheet`, `LifecycleEndSheet`); việc đối chiếu chúng với Web để change khác.
- Không làm khối nháp/công bố giải, nút "Xuất sổ làm việc giải đấu", làm mới số liệu mỗi 30 giây, và không đổi popup "Nhập điểm" (đã có `match_score_entry_chooser`).

## Capabilities

### New Capabilities
- `management-results`: tab Kết quả trong hub quản lý giải.
- `tournament-step-popups`: popup chi tiết từng bước của thanh tiến trình.

### Modified Capabilities
(không có)

## Impact

- Sửa: `tournament_management_hub_screen.dart`, `tournament_management_section_screen.dart` (chỗ dựng `LifecycleStepBar`), `lifecycle_stepper.dart`, `results_match_board.dart`, `results_rounds.dart`, hai file `app_vi.arb` / `app_en.arb` và file sinh `app_localizations*.dart`.
- Tạo: `lib/features/tournament/utils/tournament_step_summary.dart`, `lib/features/tournament/widgets/step_detail_popup.dart` và các test tương ứng.
- Rủi ro: luật đếm "Trễ giờ", "Tranh chấp", "Thiếu" phải khớp Web; sai luật thì số liệu hai nền tảng lệch nhau. Mỗi luật có test đối chiếu với Web.
