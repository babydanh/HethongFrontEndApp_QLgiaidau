# Proposal

## Why

Trên trang chi tiết giải, thanh đăng ký (nút "Đăng ký") không bao giờ hiện cho giải đang mở đăng ký. Ca `integration_test/tournament_player_flow_test.dart` (đơn và đôi) chờ nút này và hết 30 giây ở run `39113523342` (ref `06ac57ca`, log `%TEMP%/cloud-test-39113523342-117634491091.log`, dòng ~3671–3692 và ~3788–3809). Lúc đó `GET /tournaments/:id` trả 200, nên lỗi nằm ở phía app, không phải dữ liệu.

Nguyên nhân nằm ở `StatusHelper` (`lib/core/utils/status_helpers.dart`), chuẩn hoá trạng thái bị áp hai lần:

- `Tournament.fromJson` chuẩn hoá `REGISTRATION_OPEN` thành mã nội bộ `registration` và lưu vào `status` (`lib/domain/entities/tournament.dart:257-259, 380`).
- `_buildRegistrationAction` gọi `StatusHelper.isTournamentRegistration(tournament.status)` (`lib/features/tournament/screens/tournament_intro_screen.dart:308-310`). Hàm này chuẩn hoá lần hai: `registration` được viết HOA thành `REGISTRATION`, không khớp nhánh nào.
- Nhánh mặc định gọi `_unknownStatus('registration')`, và vì `registration` thuộc `_internalStatusCodes` nên trả `raw_registration` (`status_helpers.dart:22-23, 41`). Kết quả: `isTournamentRegistration` là false, thanh đăng ký không được dựng.

Cùng lỗi này làm nhãn trạng thái hiển thị `raw_registration` ở mọi nơi dùng `getTournamentStatusLabel` với giá trị đã chuẩn hoá. Mức chắc chắn: đường đi trong mã đã đọc đầy đủ; chưa có ảnh màn hình trên CI để đối chiếu, nên [INFERENCE] mạnh đến khi run xanh.

## What Changes

- `lib/core/utils/status_helpers.dart`: `normalizeTournamentStatus` trả nguyên mã nội bộ đã chuẩn hoá (khớp chữ thường chính xác với `_internalStatusCodes`) trước khi viết hoa. Chuỗi thô như `REGISTRATION` vẫn không được đọc thành đang mở đăng ký (giữ nguyên ràng buộc trong `status_helpers_registration_test.dart`).
- `test/core/utils/status_helpers_registration_test.dart`: thêm test đọc lại mã nội bộ không đổi nghĩa và `isTournamentRegistration` đúng với trạng thái đã chuẩn hoá.

### Out of scope (KHÔNG làm)

- Không đổi `Tournament.fromJson` (vẫn lưu mã nội bộ) để không đổi kiểu dữ liệu của mọi nơi đọc `status`.
- Không đổi giá trị hiển thị tiếng Việt và không đổi Backend.
