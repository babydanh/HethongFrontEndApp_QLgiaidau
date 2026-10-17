## 1. Spec và audit

- [x] 1.1 Rà toàn `lib`: mọi đường GHI cấu hình theo nội dung (notifier, màn quản lý, repository config)
- [x] 1.2 Phân loại `divisions.first` còn lại: chỉ đọc hoặc chọn hiển thị nhìn thấy; không đổi ngoài Lite
- [x] 1.3 OpenSpec: MODIFIED requirement "Màn quản lý ghi sơ đồ và VĐV ảo theo nội dung đang chọn"

## 2. Test đỏ

- [x] 2.1 Notifier `updateMatchType`: nhiều nội dung chưa chọn ném lỗi, không PATCH; đã chọn d2 PATCH đúng d2; một nội dung PATCH d1
- [x] 2.2 Notifier `updateMaxParticipants`: nhiều nội dung chưa chọn ném lỗi, không PATCH; đã chọn d2 PATCH config d2
- [x] 2.3 Notifier `generatePairs`: nhiều nội dung chưa chọn ném lỗi trước request; đã chọn d2 gửi d2
- [x] 2.4 Widget màn quản lý: nhập sức chứa khi chưa chọn → hộp chọn hiện; huỷ → không PATCH

## 3. Sửa

- [x] 3.1 Notifier: `_writeDivision()`; `updateMatchType`, `updateMaxParticipants`, `generatePairs` dùng nó
- [x] 3.2 Màn quản lý: `_buildFormatSettingCard` đọc `displayDivision`; nút lưu thể thức và debounce sức chứa gọi `_ensureDivisionChosen`

## 4. Kiểm tra

- [x] 4.1 `flutter analyze --no-pub` các thư mục đã sửa: ghi exit code, 0 error
- [x] 4.2 `flutter test --no-pub` các file liên quan: đỏ trước sửa, xanh sau sửa
- [x] 4.3 `openspec validate fix-app-lite-write-division --strict` và `openspec validate --all --strict`
- [ ] 4.4 Archive, commit, merge-lane, dọn worktree
