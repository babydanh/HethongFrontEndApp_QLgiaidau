## Why
Tab "Camera của giải" trong App tốn chỗ và thiếu nút thao tác: không có nút Bật/Tắt cam hiện sẵn (chỉ nằm trong menu ⋯), chip sân xuống nhiều dòng, thẻ sân cao, dòng trận chưa có sân lặp chip "Chưa có sân", và giải đã kết thúc thì nút ＋ biến mất mà không giải thích.

## What Changes
- Dòng trận có nút "Bật cam" / "Tắt cam" hiện sẵn khi trận có camera hoặc đang LIVE và tab không chỉ-xem.
- Nút ▶ xem live chỉ hiện khi trận có camera hoặc đang LIVE.
- Chip sân thành một hàng cuộn ngang; thẻ sân thấp hơn (padding dọc 12 → 8).
- "Trận chưa có sân" không lặp chip "Chưa có sân".
- Tab chỉ-xem hiện dòng "Chỉ xem · Giải đã kết thúc nên không thêm được camera."

## Out of scope
- Cho phép tạo camera ở giải đã kết thúc (đổi luật nghiệp vụ).
- Tối ưu `/venues` và polling `manage/matches` ở Backend.
- Bỏ mục Bắt đầu/Dừng trong menu ⋯ (giữ để không đổi hành vi cũ).

## Capabilities
### New Capabilities
- `camera-tab-compact`: bố cục gọn và nút Bật/Tắt cam của tab Camera trong App.

### Modified Capabilities
(không)

## Impact
- `lib/features/tournament/widgets/{camera_match_row,camera_tab_header,camera_court_card}.dart`, `lib/features/tournament/screens/tournament_management_camera_section.dart`, `lib/l10n/app_{vi,en}.arb` (+ generated).
