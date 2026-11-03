## Why

Popup "Liên hệ" ở màn Quản lý giải đang chia hai nút lớn "Nhập thông tin BTC" / "Dùng hồ sơ tài khoản", chip loại liên kết xuống hai dòng và một nút "Thêm" riêng. Màn cao khoảng 560 dp, phải cuộn, nhiều chữ. Người dùng muốn gọn hơn, theo bản vẽ Lavish `app-contact-popup.html` (trạng thái B).

## What Changes

- Thay hai nút chọn nguồn bằng một công tắc một dòng "Dùng hồ sơ tài khoản".
- Bật hồ sơ: hiện thẻ nhỏ avatar + tên tài khoản (chỉ đọc), rồi điện thoại và email. Bỏ công tắc "Hiện người sáng lập" trong popup vì con mắt ở dòng người sáng lập tab Tổng quan đã có.
- Loại liên kết là 6 icon tròn một hàng; ô giá trị có nút ✓ nằm trong ô; liên kết đã có hiện icon + giá trị + dấu ✕.
- Ẩn dòng "Chưa có liên kết nào"; rút nhãn nhóm thành "Liên kết".

## Out of scope

- Không đổi dữ liệu gửi lên server (`displayMode`, `hidden`, `organizerName`, `phone`, `email`, các khoá liên kết) và không sửa Backend.
- Không đổi popup cha, không đổi luật bắt buộc nhập tên BTC khi nhập tay.
- Không đổi cờ `hidden` từ popup này; cờ vẫn do con mắt ở tab Tổng quan điều khiển.

## Capabilities

### New Capabilities
- `contact-form`: popup chỉnh liên hệ ban tổ chức gọn một form.

### Modified Capabilities

## Impact

- `lib/features/tournament/widgets/tournament_contact_form.dart`, `tournament_management_section_screen.dart` (truyền tên/ảnh hồ sơ).
- `lib/l10n/app_vi.arb`, `app_en.arb` (bỏ khoá không còn dùng, rút nhãn).
- Test `test/features/tournament/tournament_contact_form_test.dart`, `test/features/tournament_management_hub_screen_test.dart`.
