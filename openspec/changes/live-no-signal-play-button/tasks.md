## 0. Khảo sát trước khi viết test

- [x] 0.1 Đọc `lib/features/match/screens/live_score_screen.dart` (`build` và `initState`) và liệt kê provider tối thiểu cần override để pump `LiveScoreScreen` mà không mở mạng hay socket thật: `singleMatchProvider`, `matchControllerProvider`, `authProvider`, `tournamentProvider`, `viewerCountProvider`, `scorePanelNotifierProvider`, `matchPlaybackProvider` (trả null ở case chưa có luồng; case lỗi đi qua provider thật với `dioClientProvider` từ chối request), `matchSocketServiceProvider`, `dioClientProvider`. Hoàn thành khi có danh sách override và đã xác nhận từng override có kiểu trả về đúng trong code. Điều kiện dừng: nếu setup cần mạng hoặc socket thật, dừng, báo người dùng, KHÔNG viết test grep source.

## 1. Test hành vi trước khi sửa

- [x] 1.1 Viết `test/match/live_score_video_panel_test.dart`: pump `LiveScoreScreen` với `matchPlaybackProvider` trả null. Assert (a) trong phạm vi `Stack` chứa `LiveVideoBox` không có `Icons.play_arrow_rounded` nào; (c) nhãn "Chưa có tín hiệu phát trực tiếp" có. Đếm trong phạm vi `Stack` vì nút "Bắt đầu trận" (dòng 943, 1242) dùng cùng icon và không thuộc khung video. Trước khi sửa, số icon là hai (nút giữa và nút thanh dưới). RED đã chạy ở bước xoá nút giữa (2 icon); bước xoá thanh dưới chưa có RED riêng.
- [x] 1.2 Thêm scenario backend lỗi khi tải playback vào cùng file, cùng assert (a) và (c). Đã PASS ở lần chạy cuối. Chưa có RED riêng cho case này: lần chạy đầu bị lỗi layout bảng điểm chặn trước khi tới assert icon.

## 2. Sửa code

- [x] 2.1 Xoá khối `Center` nút play trang trí (dòng 1796–1815 của `origin/main`) và thanh điều khiển dưới giả (dòng 1721–1794) khỏi `lib/features/match/screens/live_score_screen.dart`. Hoàn thành khi `git diff -- lib/features/match/screens/live_score_screen.dart` chỉ có hai khối này bị xoá.
- [x] 2.2 Chạy `flutter test --no-pub test/match/live_score_video_panel_test.dart`. PASS 2/2. Lỗi layout bảng điểm có sẵn đã sửa trong cùng change: ô tên cố định 132px, `Column` bỏ `stretch` ngang, `IntrinsicHeight` quanh hàng điểm.

## 3. Kiểm chứng cuối

- [x] 3.1 Chạy `flutter analyze --no-pub lib/features/match`. Hoàn thành khi không có lỗi mới so với `origin/main` (ghi lại số warning sẵn có để so sánh).
- [x] 3.2 Chạy `flutter test --no-pub --concurrency=1 test/match/live_score_video_panel_test.dart test/match/live_score_no_fake_elo_test.dart test/match/live_score_member_profile_link_test.dart`. PASS 4/4, 0 exception.
