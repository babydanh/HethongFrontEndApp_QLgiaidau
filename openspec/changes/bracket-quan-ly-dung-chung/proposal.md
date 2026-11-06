## Why

App đang có hai bộ vẽ bracket: bản cũ (`SingleElimDiagram`, `DoubleElimDiagram`, `BracketMatchCard`) dùng ở hai màn quản lý, và bản mới (`PlayoffDoubleElimView` + `PlayoffBracketBoard`) đã dùng ở trang công khai với thẻ trận kiểu Web, mỗi trang hai vòng và chuyển trang có hiệu ứng. Người dùng muốn bỏ bản cũ để cả app dùng một bracket, đẹp và mượt. Bản cũ là nơi duy nhất làm kéo thả đổi VĐV và chấm điểm nên bản mới phải học được các việc đó trước khi xóa bản cũ.

## What Changes

- Bracket mới có chế độ "sửa": kéo thả và chạm-chạm đổi VĐV giữa các ô (SWAP/MOVE/ASSIGN/REPLACE qua `bracketSlotOperation`), ô khóa khi trận đang/đã đấu, hàng BYE, viền vàng chung kết, ELO, chip "Chấm điểm".
- Hai màn quản lý (`bracket_view_screen.dart`, `bracket_diagram_screen.dart`) chuyển sang `PlayoffDoubleElimView`; vẫn bọc trong `BracketSlotEditingScope` (khay chờ + hàm thả giữ nguyên).
- Khi đang kéo mà giữ gần mép trái/phải thì tự lật sang vòng kế để thả được qua trang.
- Chuyển động: nhấc/thả VĐV, ô nhận thả, đổi tên khi SWAP/MOVE, đường nối chạy khi có người thắng, tick bật nảy, chấm live nhấp nháy, thẻ hiện lần lượt, nhấn thẻ thu nhẹ; mọi chuyển động tắt khi hệ thống bật giảm chuyển động.
- Xóa `single_elim_diagram.dart`, `double_elim_diagram.dart`, `bracket_match_card.dart` và sửa các test đang gọi chúng. `team_row.dart` giữ lại vì `match_card_detail.dart` và `club_activity_tab.dart` còn dùng.

## Out of scope

- Không đổi API Backend, không đổi hợp đồng `bracketSlotOperation` / `BracketSlotDragData`.
- Không thêm chế độ "Toàn cảnh" (zoom, kéo chéo, xem mọi vòng cùng lúc). Màn toàn màn hình mất zoom/kéo chéo.
- Không đổi trang vòng tròn, Thụy Sĩ, bảng xếp hạng.
- Không thêm package.
- Không đẩy `main`; việc gộp làm sau khi người dùng cho phép.

## Capabilities

### New Capabilities

- `bracket-board-editing`: bracket mới dùng chung cho xem và sửa (kéo thả, chấm điểm, chuyển động).

### Modified Capabilities

(không có; spec chung hiện chưa mô tả bracket)

## Impact

- Repo App: `lib/features/bracket/widgets/` (thẻ, bảng, view, hàng kéo thả, lật trang theo mép), `lib/features/bracket/screens/bracket_view_screen.dart` (quanh dòng 1455–1477), `bracket_diagram_screen.dart` (quanh dòng 241–261).
- Backend / Web: không ảnh hưởng.
- Nhánh khác `app-admin-khong-chap-diem`, `app-admin-khong-chap-diem-sach` cũng sửa `bracket_view_screen.dart` (dòng ~13 và 461–468): vùng không trùng, git tự gộp, nhưng phải gộp cẩn thận.
- Nhánh nền: `playoff-2-vong-moi-trang` (chưa lên `main`), nên nhánh này phải gộp sau hoặc cùng nhánh đó.
