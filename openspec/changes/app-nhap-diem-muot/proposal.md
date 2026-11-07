## Why
Người chấm bấm "+/−" trên App thấy số điểm giật (nhảy lùi rồi nhảy lại) và các thông báo "thành công/thông tin" nổi lên che nút "+" của đội dưới. Audit (đọc code, 2026-11-07) tìm ra: bản chụp từ server (socket/poll/echo của lần ghi court-state) đè lên điểm vừa bấm chưa kịp gửi, và panel rebuild cả khối mỗi khi dữ liệu trận về dù tên/đội hình không đổi.

## What Changes
- `ScorePanelNotifier._updateStateFromMatch`: khi còn lần bấm chưa gửi (`_liveSyncPending` hoặc bóng đá đang chờ gửi) thì bỏ bản chụp server có điểm khác, trừ khi trận đã kết thúc ở server. Phản hồi của lần ghi sẽ đồng bộ lại.
- Bỏ toast "Team X won the rally but the other team is serving..." (pickleball side-out) và 2 toast "đã ghi phạt" ở màn chấm điểm live. Giữ toast lỗi và cảnh báo từ chối thao tác của bóng đá.
- `rally_score_panel.dart`, `tennis_score_panel.dart`: chỉ theo dõi tên đội và số người mỗi đội thay vì cả `AsyncValue` của trận.

## Out of scope
- Web (làm ở change riêng bên repo Web).
- Ghi court-state song song của pickleball (`PickleballCourtNotifier._persist`) và bộ lọc phiên bản của poll 12 giây: cần xác nhận phía Backend có tăng revision khi PATCH court-state hay không.
- Rebuild của `pickleball_court_panel.dart`, `football_score_panel.dart`, `official_score_modal.dart`.
- Khoá i18n `cbdPbReceiverWon*`, `livePenaltyRecorded*` để nguyên (không động vào ARB).

## Capabilities
### New Capabilities
- `app-nhap-diem-muot`: nhập điểm App không nhảy lùi, không toast che nút.

### Modified Capabilities
(không)

## Impact
- Chỉ App Flutter, không đổi endpoint hay field Backend.
- Test đổi: `test/match/pickleball_court_panel_actions_test.dart` (toast → không có toast), `integration_test/xem_bam_diem_pickleball_test.dart` (bỏ chờ toast).
- Thêm `applyMatchSnapshot` (`@visibleForTesting`) để test tái hiện lỗi.
