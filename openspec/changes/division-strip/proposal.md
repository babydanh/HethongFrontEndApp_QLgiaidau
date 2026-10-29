## Why

Chọn "nội dung thi đấu" đang có nhiều cách viết khác nhau trong App (viên thuốc ở Bảng đấu và Trực tiếp, thẻ cao 76dp ở Vận hành giải, dropdown ở nhiều màn). Web dùng một dải chọn nội dung dùng chung. Bản duyệt trên Lavish: một thanh chip gọn, không icon, không chấm màu.

## What Changes

- Thêm `DivisionStrip`: dải chip nằm ngang, mỗi chip một dòng cao 40dp (vùng bấm 44dp) gồm tên và số VĐV/tối đa. Tự cuộn chip đang chọn vào khung, ẩn khi chỉ có 1 nội dung, tuỳ chọn chip "Tất cả" và chip "Quản lý" cuối thanh (chỉ BTC).
- Thay `DivisionFilterSegment` ở Bảng đấu và Trực tiếp (2 chỗ), và danh sách thẻ trong `_OpsDivisionSelector` ở Vận hành giải.
- Chip "Quản lý" ở tab Bảng đấu của hub mở màn quản lý nội dung có sẵn (`TournamentManagementSection.divisions`).

## Out of scope

- Thanh icon sửa/khoá/xoá khi bấm giữ chip (để sau), dropdown ở banner/Bốc thăm/Ghép lite, tab "Nội dung" riêng, tab Lịch thi đấu (chưa có bộ lọc nội dung trong lưới lịch).
- Backend, schema.

## Capabilities

### New Capabilities
- `division-strip`: dải chọn nội dung thi đấu dùng chung.

### Modified Capabilities
(không)

## Impact

- `lib/features/tournament/widgets/division_strip.dart` (mới); xoá `division_filter_segment.dart` khi hết chỗ dùng
- `lib/features/bracket/screens/bracket_view_screen.dart`, `lib/features/live/screens/live_match_screen.dart`, `lib/features/organizer_ops/screens/organizer_ops_screen.dart`, `lib/features/tournament/screens/tournament_management_hub_screen.dart`
- `lib/l10n/app_vi.arb`, `app_en.arb` (+ file sinh)
- `test/features/division_strip_test.dart` (mới)
