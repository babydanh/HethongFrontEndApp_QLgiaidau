# Proposal

## Why

Run `39123946327` (app ref `1522ff57`, orchestrator `932f3a6`), lần đầu VĐV đơn gửi đăng ký thành công sau khi đã tick đồng ý (change `fix-register-consent-gate-source`). Ca "VĐV đăng ký đơn, được duyệt, xem nhánh và lịch, thấy nhà vô địch" đỏ vì lỗi layout trong `flutter-test.log` (dòng 98–183):

- `RenderCustomMultiChildLayoutBox was given an infinite size during layout`, widget gây lỗi là `Scaffold` tại `tournament_register_screen.dart:1272`.
- Cây widget: `build` trả `Scaffold` (dòng ~886) → `body: SingleChildScrollView` (dòng ~889) → `tAsync.when` → `_buildSuccess(t)` (dòng ~939, ~965) trả về một `Scaffold` nữa. Scaffold lồng trong viewport có chiều cao vô hạn nên không có constraint hợp lệ để layout.

Lỗi chỉ lộ ra từ vòng 3 vì vòng 2 đăng ký bị 400 (chưa tới nhánh thành công). Đây là lỗi app thật: người dùng đăng ký thành công sẽ thấy màn lỗi đỏ thay vì xác nhận. Các lỗi `SCHEDULER LIBRARY` lặp lại trong log là hệ quả của cùng lỗi layout trong các frame sau.

## What Changes

- `lib/features/register/screens/tournament_register_screen.dart`: `_buildSuccess(t)` trả về `Center(...)` (nội dung trực tiếp trong body của Scaffold ngoài) thay vì `Scaffold(backgroundColor: bgDark, body: Center(...))`. Màu nền đã có ở Scaffold ngoài (`backgroundColor: context.colors.bgDark`, dòng ~887), nên giao diện giữ nguyên. Có chú thích lý do.
- Hành vi: nội dung thành công căn giữa theo chiều ngang như trước; không còn căn giữa theo chiều dọc của cả màn vì body nằm trong scroll view có chiều cao vô hạn (không thể căn theo chiều dọc viewport). Đây là đánh đổi bắt buộc khi bỏ Scaffold lồng.

### Out of scope (KHÔNG làm)

- Không đổi `build`, không đổi `_buildForm`, không đổi thông điệp hay trạng thái đăng ký.
- Không đổi màn đôi: `doubles_registration_screen.dart` trả `_buildSuccess(colors)` (dòng ~763) TRƯỚC `Scaffold` ngoài cùng, không lồng, không có lỗi này.
- Không đổi `Expanded` trong hàng trạng thái (dòng ~1343): nằm trong `Row`, hợp lệ.
