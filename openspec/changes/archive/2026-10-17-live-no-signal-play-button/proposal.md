# Proposal

## Why

Màn chi tiết trận đấu (`live_score_screen.dart`) vẽ một nút play trang trí cố định ở giữa khung video (khối `Center` dòng 1796–1815, comment "simulating ready state"). Nút này không gắn callback và không phụ thuộc trạng thái. Khi chưa có stream, `LiveVideoBox` hiển thị `_NoSignalBox` (biểu tượng camera + "Chưa có tín hiệu phát trực tiếp") và nút play giữa chồng lên trên, nên người dùng thấy hai biểu tượng. Khi có stream, trình phát thật (`live_video_player.dart:254-255`) đã có nút Phát/Tạm dừng riêng, nên nút giữa là thứ thừa.

## What Changes

- Xoá khối `Center` nút play trang trí ở giữa khỏi `Stack` của khung video trong `lib/features/match/screens/live_score_screen.dart`. Không thêm điều kiện hiển thị.
- Thanh điều khiển dưới (`Positioned`, dòng 1721–1794 của `origin/main`) cũng bị xoá: icon play không có callback, thời gian `'02:40'`/`'--:--'` và badge `1080p 60fps` là chuỗi cứng, icon volume và fullscreen không có callback. Trình phát thật đã có Phát/Tạm dừng và Tắt/Bật tiếng khi có URL.
- Thêm widget test hành vi `test/match/live_score_video_panel_test.dart`: khi không có playback, khung video không còn `Icons.play_arrow_rounded` nào. Trước khi sửa, số icon là hai (nút giữa và nút ở thanh dưới).
- Sửa lỗi layout có sẵn ở bảng điểm (`_liveScoreOverlay`, `_liveScoreRow`) để widget test chạy được: ô tên cố định 132px thay `ConstrainedBox`, `Column` bỏ `stretch` ngang, `IntrinsicHeight` quanh hàng điểm. Hình dạng giữ nguyên.
- Thêm key ARB `userProfileViewProfileOf` (vi/en) để sửa lỗi compile có sẵn ở `origin/main` (`user_avatar_tap.dart:311`). Không thêm chuỗi hiển thị mới.

### Out of scope (KHÔNG làm)

- Không thêm điều khiển mới cho trạng thái chưa có luồng; trình phát thật chỉ hiện khi có URL.
- Không sửa `LiveVideoBox`, `LiveVideoPlayer`, `_NoSignalBox`, icon camera hay asset.
- Không làm thống kê đối đầu (H2H): web chỉ khai `h2hStat?` tùy chọn, backend và `lib/domain` không có nguồn dữ liệu. Không đổi `_buildH2hOverlay`.
- Không sửa sơ đồ nhánh đấu (bracket) hay pan `InteractiveViewer` (đang là thay đổi chưa commit ở repo chính, thuộc phạm vi khác).
- Không sửa hunk nào khác trong `live_score_screen.dart`; không chuyển 10 file feature untracked (import Excel) của phiên khác.
- Không sửa `openspec/config.yaml` (lỗi YAML có sẵn ở `origin/main`, CLI bỏ qua rule `specs` và guidance `archive`).
- Không sửa test đang đỏ `test/core/utils/elo_tier_test.dart`.

## Capabilities

### New Capabilities

- `live-score-video-panel`: hành vi khung video trên màn chi tiết trận đấu khi chưa có luồng phát trực tiếp.

### Modified Capabilities

(không có: `openspec/specs/` hiện rỗng)

## Impact

- File sửa: `lib/features/match/screens/live_score_screen.dart` (xoá khối `Center` dòng 1796–1815 và thanh dưới dòng 1721–1794 theo `origin/main`).
- File mới: `test/match/live_score_video_panel_test.dart` (widget test) và `openspec/changes/live-no-signal-play-button/`.
- Repo khác: không ảnh hưởng Backend API hay Web; không đổi endpoint hay field nào.
- Deploy: thay đổi nằm trong bản build app; không đổi cấu hình build.
