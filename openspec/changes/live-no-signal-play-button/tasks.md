## 0. Khảo sát trước khi viết test

- [x] 0.1 Đọc `lib/features/match/screens/live_score_screen.dart` (`build` và `initState`) và liệt kê provider tối thiểu cần override để pump `LiveScoreScreen` mà không mở mạng hay socket thật: `singleMatchProvider`, `matchControllerProvider`, `authProvider`, `tournamentProvider`, `viewerCountProvider`, `scorePanelNotifierProvider`, `matchPlaybackProvider` (trả null ở case chưa có luồng; case lỗi đi qua provider thật với `dioClientProvider` từ chối request), `matchSocketServiceProvider`, `dioClientProvider`. Hoàn thành khi có danh sách override và đã xác nhận từng override có kiểu trả về đúng trong code. Điều kiện dừng: nếu setup cần mạng hoặc socket thật, dừng, báo người dùng, KHÔNG viết test grep source.

## 1. Test hành vi trước khi sửa

- [x] 1.1 Viết `test/match/live_score_video_panel_test.dart`: pump `LiveScoreScreen` với `matchPlaybackProvider` trả null. Assert (a) trong phạm vi `Stack` chứa `LiveVideoBox` có đúng 1 `Icons.play_arrow_rounded`; (b) widget đó là con của `Positioned` (thanh dưới); (c) nhãn "Chưa có tín hiệu phát trực tiếp" có. Đếm trong phạm vi `Stack` vì nút "Bắt đầu trận" (dòng 943, 1242) dùng cùng icon và không thuộc khung video. Hoàn thành khi test chạy và FAIL ở (a) vì tìm thấy 2 icon (chứng minh test bắt được nút giữa). Không dùng `findsNothing` cho icon play: thanh dưới vẫn có icon.
- [ ] 1.2 Thêm scenario backend lỗi khi tải playback vào cùng file, cùng các assertion (a)–(c). Trạng thái: chưa có RED cho case này; lần chạy hiện tại FAIL do lỗi layout bảng điểm (xem 2.2) trước khi tới assertion icon. Hoàn thành khi case này FAIL ở (a) trước khi sửa và PASS sau khi sửa.

## 2. Sửa code

- [x] 2.1 Xoá khối `Center` nút play trang trí (comment "Big central Play Button", dòng 1796–1815 của `origin/main`) khỏi `lib/features/match/screens/live_score_screen.dart`. Không đổi thanh dưới. Hoàn thành khi `git diff -- lib/features/match/screens/live_score_screen.dart` chỉ có đúng khối này bị xoá.
- [ ] 2.2 Chạy `flutter test --no-pub test/match/live_score_video_panel_test.dart`. Hoàn thành khi cả hai case PASS (còn đúng 1 icon, nằm trong `Positioned`).

## 3. Kiểm chứng cuối

- [x] 3.1 Chạy `flutter analyze --no-pub lib/features/match`. Hoàn thành khi không có lỗi mới so với `origin/main` (ghi lại số warning sẵn có để so sánh).
- [ ] 3.2 Chạy `flutter test --no-pub test/match/live_score_video_panel_test.dart test/match/live_score_no_fake_elo_test.dart test/match/live_score_member_profile_link_test.dart`. Hoàn thành khi tất cả PASS.
