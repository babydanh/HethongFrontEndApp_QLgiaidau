## Why
Web chia hai tab công khai rõ ràng: "Đang diễn ra" là bảng trận (hộp đỏ "Đang đấu" rồi mỗi vòng một hộp, có lọc/tìm/nhảy vòng, avatar và logo đội), còn "Kết quả" chỉ là bục vinh danh kèm nút chia sẻ. App đang trộn: tab "Đang diễn ra" chỉ liệt kê thẻ trận live, tab "Kết quả" chứa bảng trận rồi mới tới trao thưởng, hàng trận không có avatar/logo.

## What Changes
- Tab "Đang diễn ra" dùng bảng trận như Web: chip lọc (Tất cả / Đang đấu / Sắp tới / Đã xong), ô tìm tên VĐV, menu "Tới vòng", hộp "Đang đấu" trên cùng, mỗi vòng một hộp; hàng trận có avatar VĐV hoặc logo đội, điểm ngang hàng với từng bên, giờ · sân.
- Mã trận: Ban tổ chức (`canManage`) thấy `#V…`; người xem thấy số thứ tự trong hộp, giống Web.
- Bấm hàng đang đấu mở phòng live; Ban tổ chức giữ nút nhập điểm (hộp chọn có sẵn) và nút xếp lịch có sẵn.
- Tab "Đang diễn ra" hiện khi giải đang thi đấu hoặc có trận live (như Web), không chỉ khi có trận live.
- Tab "Kết quả" bỏ bảng trận, chỉ còn bục vinh danh (Quán quân / Á quân / Hạng 3) và một icon chia sẻ gọn.

## Out of scope
- Không làm ô nhập điểm ngay trên hàng (hộp chọn nhập điểm của App đã có, giữ nguyên).
- Không đổi API, DTO, màn phòng live, hay màn quản lý (hub) giải.

## Capabilities
### New Capabilities
- `tournament-live-results-tabs`: bố cục tab Đang diễn ra và Kết quả của màn chi tiết giải.
### Modified Capabilities
(không)

## Impact
- `lib/features/tournament/widgets/{live_tab,results_tab,results_match_board}.dart`, `lib/core/participants/participant_display.dart`, `lib/features/tournament/screens/tournament_intro_screen.dart`, `lib/l10n/app_{vi,en}.arb`, test tương ứng.
