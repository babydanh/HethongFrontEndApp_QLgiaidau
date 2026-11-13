## Why

Màn chấm điểm cầu lông và tennis của App chỉ có hai thẻ điểm và một dòng chữ "● GIAO · ô phải · VĐV 1". Trọng tài không thấy ai đứng ô nào, ai nhận, và dòng GIAO biến mất khi bấm `−` hoặc tải lại màn (`score_panel_notifier.dart` `rallyRemovePoint` xoá `lastWinner/swaps`). Tennis chỉ biết **đội** giao, không biết VĐV nào của đôi giao. Pickleball đã có màn sân (ô tên VĐV, chip GIAO đúng người, Hoàn tác nhiều lần); người dùng muốn cầu lông và tennis chấm điểm theo cùng kiểu, đúng luật từng môn.

Mock đã duyệt: `C:\Users\GIGABYTE\.lavish\app-bam-diem-cau-long-tennis-san.html` (mục 4b), phương án người dùng chọn: sân to như pickleball, giữ `−` là chỉnh tay (A).

## What Changes

- Màn chấm điểm **cầu lông** và **tennis** (trận chính thức, không phải Lite) đổi sang sân: nửa trái đội 1 (cam), nửa phải đội 2 (xanh), mỗi ô là một VĐV ở đúng vị trí đứng, chip **GIAO** ở người giao, viền nét đứt **NHẬN** ở ô chéo; dải giữa có lời hô và hai số điểm (khung vàng ở đội giao); thanh dưới có `+`/`−` mỗi đội, Hoàn tác, Đổi sân, `⋯`.
- **Bỏ nút "Đổi giao"** (rally: ai thắng pha thì ăn điểm và cầm giao, app tự chuyển). Thay bằng **chọn người giao đầu**: bấm vào ô VĐV lúc 0-0 (và mục `⋯` "Chọn người giao" để sửa).
- **Hoàn tác** nhiều lần, trả lại đúng điểm, người giao, người nhận.
- Chip nhắc luật: cầu lông (điểm set, điểm vàng 29-29, nghỉ 60 giây, đổi sân), tennis (Game point, Deuce, lợi thế, tie-break đổi giao mỗi 2 điểm, đổi sân sau game lẻ).
- Tennis đôi: biết **VĐV nào** giao (hai người luân phiên mỗi lượt giao của đội).
- **Kéo thả và bấm thao tác** dùng lại đúng luật của pickleball (`resolveCourtDrop`, `CourtDraggable`, `CourtDropOutline`, `courtPlayerActions`): nhấn giữ VĐV kéo lên đồng đội = đổi ô phải/trái (chỉ đôi), kéo sang nửa sân kia = đổi sân, nhấn giữ chip GIAO kéo sang VĐV khác = đổi người giao. Mọi thao tác ghi qua notifier, Hoàn tác được, có bản bấm tương đương cho TalkBack.
- **Trận đơn** chạy đúng: không có đổi ô, người giao đứng ô theo điểm chẵn lẻ của đội giao, người nhận đứng ô chéo.
- **Pickleball** (sửa kèm, người dùng yêu cầu): hiện **NHẬN** ở ô chéo trận đôi; trận đơn người nhận đứng ô chéo người giao thay vì theo điểm của chính mình.

## Out of scope

- Bóng bàn (cùng dùng `RallyScorePanel`) và trận Lite/Super Lite: giữ panel hiện tại.
- Đổi luật kéo thả của pickleball (chỉ dùng lại; pickleball chỉ thêm NHẬN và sửa ô người nhận trận đơn).
- Lưu người giao / lịch sử điểm lên Backend; Web viewer không hiện chip GIAO. Sau khi tải lại màn: cầu lông ẩn GIAO tới điểm kế (như hiện tại), tennis vẫn suy được đội giao từ số game.
- Tennis: đổi thứ tự giao trong đôi giữa các set (mặc định giữ thứ tự cũ; sửa qua `⋯` "Chọn người giao").

## Capabilities

### New Capabilities
- `racket-court-scoring`: màn chấm điểm theo sân cho cầu lông và tennis (hiển thị người giao/nhận, chọn người giao đầu, Hoàn tác, chip luật).

### Modified Capabilities
- `pickleball-court-scoring`: thêm người nhận (NHẬN) và vị trí người nhận trận đơn; luật kéo thả, trái bóng, Hoàn tác giữ nguyên.

## Impact

- Repo App only. Backend/Web: **không** đổi endpoint hay field (live sync vẫn gửi điểm như cũ qua `_scheduleLiveSync`).
- Code: `lib/features/match/utils/pickleball_court.dart` (thêm người nhận), `lib/features/match/widgets/{pickleball_court_scoreboard,pickleball_court_panel}.dart` (vẽ NHẬN), `lib/domain/services/{rally_serve_rules,tennis_rules}.dart`, `lib/features/match/notifiers/{score_panel_state,score_panel_notifier,score_panel_tennis}.dart`, widget mới `lib/features/match/widgets/racket_court_*.dart`, mount ở `official_score_modal.dart`, `lib/l10n/app_{vi,en}.arb`.
- Test cũ `test/match/rally_score_panel_serve_test.dart`, `tennis_score_panel_test.dart` và `integration_test/xem_bam_diem_{rally,tennis}_test.dart` đang khẳng định giao diện cũ; sửa đúng chỗ, giữ ID test cũ.
