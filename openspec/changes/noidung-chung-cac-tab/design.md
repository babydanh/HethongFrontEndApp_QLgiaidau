## Chọn nơi giữ lựa chọn

| Cách | Ưu | Nhược |
|---|---|---|
| **Hub giữ state, truyền xuống (chọn)** | Không thêm state toàn cục; hai màn đã có sẵn tham số `divisionId` / `onDivisionChanged` | Mỗi tab con thêm một tham số |
| Riverpod provider theo `tournamentId` | Tab nào cũng đọc được | Thêm state toàn cục; `BracketViewScreen` còn dùng ngoài hub nên phải rẽ nhánh |

## Quy tắc

- `null` = chưa chọn; mỗi tab tự lùi về nội dung đầu tiên của giải. Nếu nội dung đang chọn không còn trong danh sách (bị xoá) cũng lùi về nội dung đầu.
- Tab con vẫn chạy được khi không nhận tham số (màn công khai, màn vận hành riêng): tham số điều khiển là tuỳ chọn.
- Tab VĐV bỏ accordion; nút thao tác theo nội dung (thêm, nhập Excel, VĐV ảo, wildcard, ghép đôi) giữ nguyên, chỉ không còn bấm để mở rộng dòng.
- Lưới sân dùng `DivisionStrip` với `keyPrefix: 'schedule-division'`; không còn `schedule-division-dropdown`.

## Hành vi đổi có chủ đích

Test cũ kiểm accordion của tab VĐV ("expandable division rows") và dropdown của lưới sân sẽ được sửa theo hành vi mới, nêu rõ trong commit.
