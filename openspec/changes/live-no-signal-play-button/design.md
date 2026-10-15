# Design

## Context

Khung video của `live_score_screen.dart` là một `Stack` (dòng ~1671). Con đầu là `LiveVideoBox` (dòng 1675), trả về `_NoSignalBox` khi `playbackUrl` rỗng và `LiveVideoPlayer` khi có URL (`lib/features/match/widgets/live_video_box.dart:62-65`). Sau đó là các `Positioned` overlay:

- Thanh điều khiển dưới (`Positioned`, dòng ~1722): icon play không có callback (dòng 1743–1747), thời gian hard-code `'02:40'`/`'--:--'`, icon volume và fullscreen. Không có điều kiện bọc; luôn hiển thị.
- Khối `Center` nút play trang trí (dòng 1796–1815): không có callback, không nằm trong `Positioned`, chồng lên cả hai trạng thái.

Trình phát thật đã có nút Phát/Tạm dừng riêng (`live_video_player.dart:254-255`). Xem proposal.md - Why.

Ràng buộc: `openspec/config.yaml` có lỗi YAML sẵn ở `origin/main` làm bỏ qua `rules.specs[1]` và `operations.archive.guidance`. Change này không sửa config.

## Goals / Non-Goals

**Goals:**
- Bỏ nút play trang trí ở giữa khung video khi chưa có luồng; trạng thái no-signal không còn bị chồng icon play.
- Có widget test hành vi (pump widget thật) kiểm đúng điều đó, và kiểm thanh dưới vẫn còn.

**Non-Goals:**
- Không xoá hay sửa thanh điều khiển dưới (icon play, thời gian hard-code, volume, fullscreen). Đây là control giả thứ hai, phạm vi chưa được người dùng chốt; change này không tự mở rộng.
- Không đổi `LiveVideoBox`, `_NoSignalBox`, `LiveVideoPlayer`, icon camera hay asset.
- Không đổi nhãn no-signal sang l10n: chuỗi `'Chưa có tín hiệu phát trực tiếp'` đang hard-code trong `_NoSignalBox`; đưa vào `.arb` là thay đổi khác phạm vi.

## Decisions

**Xoá hẳn khối `Center`, không thêm điều kiện hiển thị.** Phương án khác: chỉ hiện nút khi có stream. Bị loại vì khi có stream, `LiveVideoPlayer` đã có nút Phát/Tạm dừng, nên điều kiện đó chỉ tạo lại nút trùng.

**Assert theo số lượng và vị trí, không assert `findsNothing`.** Thanh dưới vẫn có `Icons.play_arrow_rounded`, nên `find.byIcon(...)` `findsNothing` sẽ luôn fail sau khi xoá khối giữa. Assert đúng: tổng số `Icons.play_arrow_rounded` trong khung video là 1 (trước khi sửa là 2 → test đỏ đúng lý do), và widget còn lại là con của `Positioned` (thanh dưới). Phương án "xoá luôn thanh dưới" bị loại vì vượt phạm vi đã chọn.

**Test pump `LiveScoreScreen` thật, không test source-text.** Hai file `test/match/live_score_no_fake_elo_test.dart` và `live_score_member_profile_link_test.dart` đều đọc source rồi grep chuỗi, nên không phải tiền lệ để copy. Không có test nào hiện tại pump `LiveScoreScreen`. Vì vậy setup provider là bước khảo sát (task 0.1), không được giả định. Provider màn hình đọc: `singleMatchProvider`, `matchControllerProvider`, `authProvider`, `tournamentProvider`, `viewerCountProvider` (trong `Consumer` khi trận live), `scorePanelNotifierProvider`, `matchPlaybackProvider` (qua `LiveVideoBox`); và `matchSocketServiceProvider` được đọc trong `initState` (dòng 245) nên phải override để không mở socket thật. Nếu setup cần mạng hoặc socket thật, dừng và báo; không hạ xuống test grep.

**Không đụng `live_score_screen.dart` ngoài khối đã xác định.** File có hunk chưa commit của phiên khác ở repo chính; change này chỉ làm việc trong worktree từ `origin/main`, nên không mang theo hunk nào.

## Risks / Trade-offs

- [Setup test nặng hoặc flaky] `LiveScoreScreen` đọc nhiều provider và socket. → Task 0.1 khảo sát trước; override tối thiểu; nếu không ổn định thì báo, không viết test grep.
- [Thiếu `.env` trong worktree] `.env` là file gitignored, `pubspec.yaml` khai báo làm asset; worktree mới không có file này, nên `flutter test` có thể không chạy. Ghi chú này được ghi trong change `agent-docs-map` (chưa đo lại ở đây). → Không copy `.env` từ repo chính (AGENTS.md cấm). Giai đoạn apply mới cần giải quyết; propose không yêu cầu.
- [Test chỉ bảo vệ phần giữa] Test không kiểm thanh dưới đúng hay sai, chỉ kiểm nó còn nguyên. → Đúng với phạm vi đã chọn; control giả ở thanh dưới là câu hỏi cho người dùng.
- [Lỗi YAML config có sẵn] Rule `specs` và guidance `archive` bị bỏ qua. → Ngoài phạm vi; cần change riêng.
- [Test đỏ có sẵn] `test/core/utils/elo_tier_test.dart` đỏ 9/9 trên `origin/main` theo change `agent-docs-map`; không liên quan và không sửa ở đây.

## Migration Plan

Không có migration dữ liệu. Rollback: revert một commit, chỉ xoá khối `Center` và file test mới.
