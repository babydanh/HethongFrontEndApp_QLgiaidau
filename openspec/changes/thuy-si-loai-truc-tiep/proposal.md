## Why

Backend cho Thụy Sĩ đưa top N vào loại trực tiếp (`swiss.advanceTopN`, route `swiss/advance`, stage thứ hai `Vòng loại trực tiếp`). App hiện coi mọi giải có trận Swiss là Swiss thuần: màn sơ đồ và `PublicBracketView` bỏ qua cây loại trực tiếp, và model `SwissConfig` không biết `advanceTopN` (PATCH stage sẽ làm rơi khóa này).

## What Changes

- `SwissConfig.advanceTopN` (đọc, ghi, giữ nguyên khi PATCH stage); ô "Số đội vào loại trực tiếp" trong editor cấu hình Swiss, khóa sau khi sinh sơ đồ.
- Màn sơ đồ và `PublicBracketView`: khi có cả trận Swiss và trận loại trực tiếp thì hiện hai phần (Thụy Sĩ rồi loại trực tiếp), cây chờ khi chưa có đội; bảng xếp hạng Swiss kẻ đường ngăn sau hạng N.
- Chuỗi `app_vi.arb`/`app_en.arb`.

## Out of scope

- Nút "Đưa vào loại trực tiếp" trong App (BTC bấm trên Web); `bracketType` mới; nhãn/icon thể thức mới; sửa trận.

## Capabilities

### New Capabilities
- `swiss-knockout`: hiển thị và cấu hình Thụy Sĩ có loại trực tiếp trên App.

### Modified Capabilities
- (không)

## Impact

- `lib/domain/entities/swiss.dart`, `lib/features/tournament/widgets/swiss_config_editor.dart`, `lib/features/tournament/screens/tournament_management_divisions_section.dart`, `lib/features/bracket/screens/bracket_view_screen.dart`, `lib/features/bracket/widgets/public_bracket_view.dart`, `lib/features/bracket/widgets/swiss_standings_view.dart`, `lib/features/bracket/utils/bracket_stage_utils.dart`, `lib/l10n/app_{vi,en}.arb`, test tương ứng.
- Backend và Web có change cùng tên và cùng hợp đồng (`design.md`).
