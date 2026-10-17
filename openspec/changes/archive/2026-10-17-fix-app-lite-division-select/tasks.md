## 1. Notifier

- [x] 1.1 Thêm `selectedDivisionId`, `activeDivisions`, `selectedDivision`, `displayDivision` vào `LiteManagementState`
- [x] 1.2 Thêm `_readDivisionId` (đọc) và `_writeDivisionId` (ghi); `createBracket`, `resetBracket`, `seedMock`, `clearMock` dùng `_writeDivisionId`
- [x] 1.3 Thêm `selectDivision` và để `generatePairs` ưu tiên nội dung đang chọn trước nội dung duy nhất

## 2. Màn quản lý

- [x] 2.1 Hiển thị sơ đồ dùng `displayDivision`
- [x] 2.2 Thêm `_ensureDivisionChosen` và `_showDivisionPicker`; gọi ở tạo sơ đồ, ghép ngẫu nhiên, reset, thêm và xoá VĐV ảo

## 3. Test

- [x] 3.1 Test notifier: nhiều nội dung chưa chọn ném lỗi và không gửi request; chọn rồi gửi đúng id; một nội dung gửi id duy nhất

## 4. Kiểm tra

- [x] 4.1 `flutter analyze --no-pub` các file đã sửa: 0 error
- [x] 4.2 `flutter test --no-pub test/providers/lite_management_pairing_request_test.dart`: 8/8 PASS
- [x] 4.3 `openspec validate --all --strict`: 7 passed (trước khi gộp)
