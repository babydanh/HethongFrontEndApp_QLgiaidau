# Tasks

## 1. Ảnh VĐV trên thẻ trận

- [x] 1.1 Helper lọc trùng thành viên (theo `userId`, rỗng thì theo tên), tối đa 2. Xong khi: test widget thẻ trận với 5 bản ghi trùng → đúng 1 `Image` trong dòng đội.
- [x] 1.2 `_DoubleAvatarWidget` và `_buildLargeAvatar` nhận danh sách thành viên: có `avatarUrl` thì `Image.network` bo tròn, lỗi/không có thì chữ viết tắt. Xong khi: test widget PASS ca có ảnh (có `Image`, không có text viết tắt) và ca không ảnh (text viết tắt như cũ).

## 2. Kiểm chứng

- [x] 2.1 `flutter analyze --no-pub` file sửa không lỗi; `flutter test --no-pub` test mới và test Trang chủ liên quan PASS.
- [x] 2.2 Smoke trên máy: Trang chủ tab "Sắp diễn ra", thẻ "Giải Thứ 4 giao lưu VNDC" hiện ảnh Nguyễn Minh Danh, Hoang Linh (ảnh chụp).
