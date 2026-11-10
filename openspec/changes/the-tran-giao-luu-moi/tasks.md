## 1. Thẻ trận

- [x] 1.1 Vẽ lại `_buildMatchCard`: `ParticipantSideLines` hai bên, tỉ số to, chip trạng thái, hàng nút "Nhập nhanh" / "Bấm điểm" cho trận chưa xong; thêm `_openScoreboard`. Tiêu chí: `flutter test --no-pub test/features/social/social_match_tab_test.dart` → exit 0 (TC-SOC-CARD-01 avatar chữ viết tắt; 02 chưa xong có hai nút; 03 đã xong không có nút; 04 "Nhập nhanh" mở hộp kết quả)
  - Files: sửa `lib/features/social/widgets/match_tab/social_match_tab.dart`; test `test/features/social/social_match_tab_test.dart`
  - Giao: (không) · Nhận: `ParticipantSideLines`, `OfficialScorePage`
  - Phụ thuộc: (không)

## 2. Kiểm

- [x] 2.1 `flutter analyze --no-pub lib/features/social` → exit 0
  - Phụ thuộc: sau 1.1
