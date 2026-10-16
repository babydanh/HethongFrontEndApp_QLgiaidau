# Design

## Context

Khung video của `live_score_screen.dart` là một `Stack` (dòng ~1671). Con đầu là `LiveVideoBox` (dòng 1675), trả về `_NoSignalBox` khi `playbackUrl` rỗng và `LiveVideoPlayer` khi có URL (`lib/features/match/widgets/live_video_box.dart:62-65`). Sau đó là các `Positioned` overlay:

- Thanh điều khiển dưới (`Positioned`, dòng 1721–1794 của `origin/main`): icon play không có callback, thời gian hard-code `'02:40'`/`'--:--'`, badge `1080p 60fps` hard-code, icon volume và fullscreen không có callback. Không có điều kiện bọc; luôn hiển thị.
- Khối `Center` nút play trang trí (dòng 1796–1815): không có callback, không nằm trong `Positioned`, chồng lên cả hai trạng thái.

Trình phát thật đã có nút Phát/Tạm dừng riêng (`live_video_player.dart:254-255`). Xem proposal.md - Why.

Ràng buộc: `openspec/config.yaml` có lỗi YAML sẵn ở `origin/main` làm bỏ qua `rules.specs[1]` và `operations.archive.guidance`. Change này không sửa config.

## Goals / Non-Goals

**Goals:**
- Bỏ nút play trang trí ở giữa khung video khi chưa có luồng; trạng thái no-signal không còn bị chồng icon play.
- Có widget test hành vi (pump widget thật) kiểm khung video không còn icon play nào khi chưa có luồng.

**Non-Goals:**
- Không thêm điều khiển mới cho trạng thái chưa có luồng; trình phát thật chỉ hiện khi có URL.
- Không đổi `LiveVideoBox`, `_NoSignalBox`, `LiveVideoPlayer`, icon camera hay asset.
- Không đổi nhãn no-signal sang l10n: chuỗi `'Chưa có tín hiệu phát trực tiếp'` đang hard-code trong `_NoSignalBox`; đưa vào `.arb` là thay đổi khác phạm vi.

## Decisions

**Xoá hẳn khối `Center`, không thêm điều kiện hiển thị.** Phương án khác: chỉ hiện nút khi có stream. Bị loại vì khi có stream, `LiveVideoPlayer` đã có nút Phát/Tạm dừng, nên điều kiện đó chỉ tạo lại nút trùng.

**Xoá cả thanh điều khiển dưới giả, và assert `findsNothing` trong khung video.** Người dùng yêu cầu xoá thanh dưới vì trông xấu và chồng lên trạng thái no-signal; icon play không có callback, thời gian và badge là chuỗi cứng. Sau khi xoá, không còn icon play nào trong khung, nên assert `findsNothing` trong phạm vi `Stack` gần nhất chứa `LiveVideoBox` là đúng. Phương án chỉ xoá nút giữa đã bị bỏ.

**Test pump `LiveScoreScreen` thật, không test source-text.** Hai file `test/match/live_score_no_fake_elo_test.dart` và `live_score_member_profile_link_test.dart` đều đọc source rồi grep chuỗi, nên không phải tiền lệ để copy. Không có test nào hiện tại pump `LiveScoreScreen`. Vì vậy setup provider là bước khảo sát (task 0.1), không được giả định. Provider màn hình đọc: `singleMatchProvider`, `matchControllerProvider`, `authProvider`, `tournamentProvider`, `viewerCountProvider` (trong `Consumer` khi trận live), `scorePanelNotifierProvider`, `matchPlaybackProvider` (qua `LiveVideoBox`); và `matchSocketServiceProvider` được đọc trong `initState` (dòng 245) nên phải override để không mở socket thật. Nếu setup cần mạng hoặc socket thật, dừng và báo; không hạ xuống test grep.

**Không đụng `live_score_screen.dart` ngoài khối đã xác định.** File có hunk chưa commit của phiên khác ở repo chính; change này chỉ làm việc trong worktree từ `origin/main`, nên không mang theo hunk nào.

## Risks / Trade-offs

- [Setup test nặng hoặc flaky] `LiveScoreScreen` đọc nhiều provider và socket. → Task 0.1 khảo sát trước; override tối thiểu; nếu không ổn định thì báo, không viết test grep.
- [Thiếu `.env` trong worktree] `.env` là file gitignored, `pubspec.yaml` khai báo làm asset; worktree mới không có file này, nên `flutter test` có thể không chạy. Ghi chú này được ghi trong change `agent-docs-map` (chưa đo lại ở đây). → Không copy `.env` từ repo chính (AGENTS.md cấm). Giai đoạn apply mới cần giải quyết; propose không yêu cầu.
- [Test chỉ bảo vệ icon play] Test không kiểm volume, fullscreen hay nội dung của trình phát thật. → Các control giả đã bị xoá; trình phát thật có test riêng nếu cần.
- [Lỗi YAML config có sẵn] Rule `specs` và guidance `archive` bị bỏ qua. → Ngoài phạm vi; cần change riêng.
- [Test đỏ có sẵn] `test/core/utils/elo_tier_test.dart` đỏ 9/9 trên `origin/main` theo change `agent-docs-map`; không liên quan và không sửa ở đây.
- [Lỗi layout bảng điểm có sẵn] `_liveScoreOverlay` đặt `Column` `stretch` trong `Positioned` không có width, và `Row` `stretch` trong `Column` không có height, làm test đỏ dù không đổi nút play. → Đã sửa trong change này theo lựa chọn người dùng: ô tên cố định `SizedBox(width: 132)` (đúng kích thước `Align` đang mở rộng tới 132 khi chạy thật), `Column` `crossAxisAlignment.start`, `IntrinsicHeight` quanh `Row` hàng điểm. Ô điểm giữ 36px. Chưa kiểm trên máy thật.

## Migration Plan

Không có migration dữ liệu. Rollback: revert một commit, bỏ khối `Center`, thanh dưới, sửa layout bảng điểm, key ARB `userProfileViewProfileOf` và file test mới.
