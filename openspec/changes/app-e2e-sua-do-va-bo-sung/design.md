## Cách làm

Mỗi file đỏ được phân loại bằng log và ảnh của lượt cloud:
- **Lỗi thời:** màn đã đổi có chủ ý (đối chiếu `lib/` và commit gần đây) thì sửa test, giữ ý kiểm tra gốc.
- **Lỗi app thật:** giữ `expect`, `skip: true` (vì `testWidgets(skip:)` chỉ nhận `bool`), mã `BUG-...` trong tên ca và chú thích cạnh `skip`, ghi vào bảng dưới.

## Phát hiện

(Điền theo kết quả chạy thật.)
