## Why

Trên máy thật, ô "Loại điểm" (ô chọn ELO/DUPR) cao hơn ô "Điểm" cạnh nó vì nhãn của ô chọn luôn nổi lên, còn nhãn ô nhập chỉ nổi khi có chữ.

## What Changes

- Các ô nhập tay của popup "Thêm VĐV" luôn để nhãn nổi và cùng chiều cao tối thiểu, nên ô trống hay đã nhập đều bằng nhau.

## Out of scope

- Logic gửi, hàng chờ, Backend.

## Capabilities

### New Capabilities
- `add-athlete-field-height`: chiều cao đồng đều của các ô nhập tay.

### Modified Capabilities
(không)

## Impact

- `lib/features/organizer_ops/screens/add_athlete_sheet.dart`
- `test/organizer_ops/add_athlete_entry_test.dart`
