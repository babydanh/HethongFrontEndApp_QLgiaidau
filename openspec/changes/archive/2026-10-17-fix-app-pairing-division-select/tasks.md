## 1. Dùng chung

- [x] 1.1 Thêm `usableTournamentDivisions` vào `core/utils/tournament_division_id.dart`
- [x] 1.2 Thêm `LiteParticipant.tournamentDivisionId` và `activeDivisions` dùng `usableTournamentDivisions`
- [x] 1.3 Tách `showLiteDivisionPicker` thành `features/lite/widgets/lite_division_picker.dart`; màn quản lý gọi chung

## 2. Màn ghép cặp

- [x] 2.1 Bộ chọn nội dung, lọc danh sách chờ và danh sách đơn theo nội dung đang chọn
- [x] 2.2 `_ensureDivisionChosen` trước ghép ngẫu nhiên và tạo sơ đồ; gửi `divisionId` của nội dung đã chọn
- [x] 2.3 Ghép tay không gửi `divisionId`; xoá `liteSingleDivisionId` và `_canonicalMatchType`

## 3. Test

- [x] 3.1 Request: nhiều nội dung chưa chọn không hiện RANDOM; chọn d2 gửi `divisionId: d2`
- [x] 3.2 Request: tạo sơ đồ chưa chọn, huỷ hộp chọn thì không gửi POST nào
- [x] 3.3 Widget: picker khoá xác nhận khi chưa chọn; chọn rồi xác nhận trả id; huỷ trả null
- [x] 3.4 Unit: `LiteParticipant` đọc `tournamentDivisionId`

## 4. Kiểm tra

- [x] 4.1 `flutter analyze --no-pub` các thư mục đã sửa: 0 error
- [x] 4.2 `flutter test --no-pub` 4 file liên quan: All tests passed (+22)
- [x] 4.3 `openspec validate --all --strict`: 7 passed (trước khi gộp)
- [x] 4.4 Archive xong; gộp qua merge-lane ở bước cuối
