## 1. Bảng điểm overlay
- [x] 1.1 Widget `LiveScoreboardOverlay` kiểu Web, đặt đáy video, góc dưới trái cho người xem (tên viết tắt IN HOA), ẩn khi H2H/Sơ đồ hiện. Tiêu chí: `flutter test --no-pub test/features/match/live_scoreboard_overlay_test.dart` → exit 0
  - Files: tạo `lib/features/match/widgets/viewer/live_scoreboard_overlay.dart`; sửa `lib/features/match/screens/live_score_screen.dart` (`_liveScoreOverlay`, khối Positioned bảng điểm); test `test/features/match/live_scoreboard_overlay_test.dart`
  - Giao: `LiveScoreboardOverlay({team1, team2: Widget, score1, score2: int, finished: bool})` · Nhận: (không)
  - Chủ file chung: 1.1 giữ `live_score_screen.dart` trước 2.1, 3.1
  - Phụ thuộc: không

## 2. Hàng nút và chat
- [x] 2.1 Cổ vũ + Chia sẻ, tên giải thành link, "Chi tiết"; ô nhập một khối (widget `LiveCommentInput`). Chat rỗng đã có chữ gợi ý sẵn (`liveEmptyDiscussion`), giữ nguyên. Tiêu chí: `flutter test --no-pub test/features/match/live_viewer_header_test.dart test/features/match/live_comment_input_test.dart` → exit 0
  - Files: sửa `live_viewer_header.dart`, `live_score_screen.dart` (`_buildChatTab`, ô nhập), `lib/l10n/app_vi.arb`, `app_en.arb`
  - Chủ file chung: 2.1 giữ `app_vi.arb`, `app_en.arb`
  - Phụ thuộc: sau 1.1

## 3. Popup Chi tiết trận
- [x] 3.1 Bảng điểm đầu popup, bỏ thẻ ELO "Chưa có", ẩn dòng rỗng, nút Báo cáo viền nhỏ. Tiêu chí: `flutter test --no-pub test/features/match/live_match_details_sheet_test.dart` → exit 0
  - Files: sửa `live_match_details_sheet.dart`, phần dựng dữ liệu `_showDetailsSheet` trong `live_score_screen.dart`; test `test/features/match/live_match_details_sheet_test.dart`
  - Phụ thuộc: sau 2.1

## 3b. Overlay H2H và Sơ đồ
- [x] 3.2 Overlay H2H (widget `LiveH2hOverlay`) và Sơ đồ cùng tông navy + #1E90FF như Web/bản vẽ Lavish; H2H bỏ chip ELO "Chưa có". Tiêu chí: `flutter test --no-pub test/features/match/live_h2h_overlay_test.dart` → exit 0
  - Files: tạo `lib/features/match/widgets/viewer/live_h2h_overlay.dart`; sửa `live_score_screen.dart` (`_buildH2hOverlay`, `_buildBracketOverlay`), `lib/l10n/app_vi.arb`; test `test/features/match/live_h2h_overlay_test.dart`
  - Phụ thuộc: sau 3.1

## 3c. Avatar đơn/đôi và chuyển động overlay
- [x] 3.3 Avatar mỗi bên: VĐV đơn/đội/bên chưa xác định = 1 avatar, cặp đôi = 2 avatar chồng nhau (tối đa 2); không có ảnh thì chữ cái đầu (tên một chữ như `odi695` → `O`). Dùng chung ở popup (đường kính 34) và H2H (28, viền màu bên). Tiêu chí: `flutter test --no-pub test/features/match/live_side_avatars_test.dart test/features/match/live_match_sides_test.dart test/features/match/live_h2h_overlay_test.dart` → exit 0
  - Files: tạo `lib/features/match/widgets/viewer/live_side_avatars.dart`; sửa `live_match_sides.dart` (`matchSideAvatars`), `live_match_details_sheet.dart`, `live_h2h_overlay.dart`, `live_score_screen.dart`
  - Phụ thuộc: sau 3.2
- [x] 3.4 Chuyển động overlay: H2H trượt lên + mờ dần, Sơ đồ phóng nhẹ 0.96 + mờ dần, bảng điểm trượt từ trái; ẩn nhanh hơn hiện (160 ms so với 240 ms); đổi điểm có hiệu ứng nảy 180 ms; tắt hết khi người dùng bật giảm chuyển động. H2H và bảng điểm có nhãn đọc cho trình đọc màn hình. Tiêu chí: `flutter test --no-pub test/features/match/live_overlay_controls_test.dart test/features/match/live_scoreboard_overlay_test.dart test/features/match/live_h2h_overlay_test.dart` → exit 0
  - Files: sửa `lib/features/match/widgets/live_overlay_controls.dart` (`liveOverlayReverseDuration`, `liveOverlayTransition`), `live_scoreboard_overlay.dart`, `live_score_screen.dart`
  - Phụ thuộc: sau 3.3

## 4. Kiểm tra
- [x] 4.1 `flutter analyze --no-pub` file đã sửa; test hẹp (106 test trong `test/features/match`, các `test/match/live_score_*` và 2 test overlay-visibility đều xanh). Tiêu chí: exit 0. Ghi chú: CHƯA xem trên điện thoại thật; người dùng xem trên máy Redmi qua app chung.
  - Phụ thuộc: sau 3.1
