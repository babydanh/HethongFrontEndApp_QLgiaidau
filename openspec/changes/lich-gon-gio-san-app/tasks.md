## 1. Helper tên sân và màu chip

- [ ] 1.1 Helper `formatCourtShortName` và `courtChipColors` (test đỏ trước). Tiêu chí: `flutter test --no-pub test/features/schedule_court_label_test.dart` exit 0.
  - Files: tạo `lib/features/tournament/utils/schedule_court_label.dart`, `test/features/schedule_court_label_test.dart`
  - Giao: `String formatCourtShortName(String? name)`, `CourtChipColors courtChipColors(int index)`
  - Chủ file chung: không
  - Phụ thuộc: không

## 2. Lưới lịch gọn

- [x] 2.1 `_fullHeader`: giờ + chip sân một dòng; `_courtHeader`: chip + tooltip; thang giờ 112 (mặc định, công khai, host BTC), giới hạn 80..224. Tiêu chí: `dart analyze` các file sửa exit 0; test lịch cập nhật đúng số mới.
  - Files: sửa `lib/features/tournament/widgets/schedule_grid.dart` (`_fullHeader`, `_courtHeader`, `slotHeight`, `minSlotHeight`, `maxSlotHeight`), `matches_tab.dart` (slotHeight), `tournament_schedule_court_grid.dart` (`_slotHeight`)
  - Nhận: helper từ 1.1
  - Chủ file chung: không (ba file lịch đã được phiên `app-khai-mac-ket-thuc` trả về HEAD sạch)
  - Phụ thuộc: 1.1
- [ ] 2.2 Cập nhật test cũ theo số mới và chữ tiêu đề cột. Tiêu chí: các test lịch liên quan xanh (cần asset `.env` để chạy, xem handoff).
  - Files: sửa `test/features/schedule_grid_zoom_test.dart`, `tournament_schedule_tab_test.dart`, `hub_schedule_court_grid_test.dart`, `ops_matches_view_toggle_test.dart`
  - Phụ thuộc: 2.1

## 3. Kiểm và gộp

- [ ] 3.1 `dart analyze` + `dart format` đúng các file sửa; review `flutter-reviewer`, sửa P0/P1.
- [ ] 3.2 Kiểm hình ảnh trên thiết bị (chưa làm, cấm `flutter run` ở phiên này).
