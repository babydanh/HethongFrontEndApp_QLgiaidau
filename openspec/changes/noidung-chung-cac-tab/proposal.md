## Why

Các tab trong hub quản lý giải chọn "nội dung thi đấu" mỗi nơi một kiểu và không nhớ nhau: Bảng đấu dùng `DivisionStrip` nhưng giữ lựa chọn riêng; Lịch có dải chip ở vận hành nhưng lưới sân lại dùng thêm một dropdown riêng; Vận động viên dùng danh sách thu gọn (accordion); màn Kết quả công khai tự dựng danh sách chọn. Chọn "Đôi Nam" ở Bảng đấu rồi sang Lịch thì lại về nội dung đầu tiên. Hai change trước (`division-strip`, `division-strip-het`) đã hoãn đúng các phần này.

## What Changes

- Hub quản lý giữ **một** `selectedDivisionId` dùng chung cho tab Bảng đấu, Lịch và Vận động viên; đổi ở tab nào thì các tab còn lại theo.
- Lưới sân của tab Lịch bỏ dropdown nội dung riêng, dùng `DivisionStrip`.
- Tab Vận động viên đổi từ accordion theo nội dung sang `DivisionStrip` + nội dung của nội dung đang chọn (cùng các nút thêm/nhập/ghép như hiện có).
- Màn Kết quả công khai bỏ danh sách chọn tự dựng, dùng `DivisionStrip`.

## Out of scope

- Không thêm tab "Kết quả" vào hub quản lý (giả định A đã đề xuất; đổi ý thì mở change riêng).
- Tab Nội dung (danh sách để sửa nội dung) giữ accordion; hộp chọn nội dung của Lite; thanh icon sửa/khoá/xoá khi bấm giữ chip.
- Backend, schema, chuỗi l10n mới (dùng lại "Tất cả"/"Quản lý" có sẵn).

## Capabilities

### New Capabilities
- `division-shared-selection`: lựa chọn nội dung thi đấu dùng chung giữa các tab quản lý.

### Modified Capabilities
(không)

## Impact

- `lib/features/tournament/screens/tournament_management_hub_screen.dart`
- `lib/features/bracket/screens/bracket_view_screen.dart`
- `lib/features/organizer_ops/screens/organizer_ops_screen.dart`, `lib/features/tournament/widgets/tournament_schedule_court_grid.dart`, `lib/features/tournament/screens/schedule_fullscreen_screen.dart`
- `lib/features/tournament/widgets/tournament_management_athletes_tab.dart`
- `lib/features/tournament/screens/tournament_intro_screen.dart`
- Test: `tournament_management_hub_screen_test.dart`, `athletes_tab_actions_test.dart`, test lưới lịch, test mới cho phần chia sẻ.
