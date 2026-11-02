## 1. Bảng điểm overlay
- [x] 1.1 Widget `LiveScoreboardOverlay` kiểu Web, đặt góc trên trái video cho người xem (tên viết tắt IN HOA, cùng hàng ngay sau nút Quay lại), ẩn khi Sơ đồ hiện. Tiêu chí: `flutter test --no-pub test/features/match/live_scoreboard_overlay_test.dart` → exit 0
  - Files: tạo `lib/features/match/widgets/viewer/live_scoreboard_overlay.dart`; sửa `lib/features/match/screens/live_score_screen.dart` (`_liveScoreOverlay`, khối Positioned bảng điểm); test `test/features/match/live_scoreboard_overlay_test.dart`
  - Giao: `LiveScoreboardOverlay({team1, team2: Widget, score1, score2: int, finished: bool})` · Nhận: (không)
  - Chủ file chung: 1.1 giữ `live_score_screen.dart` trước 2.1, 3.1
  - Phụ thuộc: không

## 2. Hàng nút và chat
- [ ] 2.1 Cổ vũ + Chia sẻ, tên giải thành link; chat rỗng có chữ gợi ý; ô nhập một khối. Tiêu chí: test widget mới → exit 0
  - Files: sửa `live_viewer_header.dart`, `live_score_screen.dart` (`_buildChatTab`, ô nhập), `lib/l10n/app_vi.arb`, `app_en.arb`
  - Chủ file chung: 2.1 giữ `app_vi.arb`, `app_en.arb`
  - Phụ thuộc: sau 1.1

## 3. Popup Chi tiết trận
- [ ] 3.1 Bảng điểm đầu popup, bỏ thẻ ELO "Chưa có", ẩn dòng rỗng, nút Báo cáo viền nhỏ. Tiêu chí: `flutter test --no-pub test/features/match/live_match_details_sheet_test.dart` → exit 0
  - Files: sửa `live_match_details_sheet.dart`, phần dựng dữ liệu `_showDetailsSheet` trong `live_score_screen.dart`; test `test/features/match/live_match_details_sheet_test.dart`
  - Phụ thuộc: sau 2.1

## 4. Kiểm tra
- [ ] 4.1 `flutter analyze --no-pub` file đã sửa; test hẹp; xem thật trên điện thoại. Tiêu chí: exit 0
  - Phụ thuộc: sau 3.1
