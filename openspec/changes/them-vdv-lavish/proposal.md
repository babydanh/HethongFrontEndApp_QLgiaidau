## Why

Popup "Thêm VĐV" (tab VĐV) còn dùng giao diện Material cũ, lệch với các popup đã chuyển sang kiểu Lavish. Ngoài ra khi ban tổ chức nhập tay một email đã thuộc tài khoản Sporto, Backend trả 409 `EMAIL_BELONGS_TO_ACCOUNT` ("hãy chọn tài khoản đó thay vì nhập tay") nhưng App chỉ hiện một câu lỗi thoáng qua, không chỉ đường sang tab chọn tài khoản.

## What Changes

- Vẽ lại hai tab của `AddAthleteSheet` theo bộ Lavish: chip chọn tab, ô tìm xám, hàng ứng viên dạng `LavishRow` (nhãn nguồn Bạn bè/CLB/Email và "Đã thêm" dạng pill), công tắc Ghép đôi bằng `LavishSwitch`, nút `LavishButton`.
- Tab "Nhập tên": khi Backend trả 409 `EMAIL_BELONGS_TO_ACCOUNT` hiện dải báo "Email này là tài khoản Sporto" kèm nút "Tìm tài khoản này"; bấm nút chuyển sang tab "Bạn bè & CLB" và tìm sẵn theo email đó.
- Giữ nguyên mọi `ValueKey` hiện có và luồng gọi API.

## Out of scope

- Backend, hợp đồng API, luật thêm VĐV.
- Các popup khác của tab VĐV (Nhập Excel, Ghép đôi, Tự ghép, Mock, Wildcard, chi tiết VĐV).
- Thêm widget mới vào `lavish_kit.dart`.
- Tự gắn tài khoản cho email nhập tay (Backend không làm việc này).

## Capabilities

### New Capabilities
- `add-athlete-lavish`: giao diện Lavish và lối đi từ email trùng tài khoản sang tìm tài khoản.

### Modified Capabilities
(không)

## Impact

- `lib/features/organizer_ops/screens/add_athlete_sheet.dart`
- `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (+ file sinh bởi `flutter gen-l10n`)
- `test/organizer_ops/add_athlete_entry_test.dart`
