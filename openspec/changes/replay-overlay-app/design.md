## Hợp đồng đọc từ Backend

`overlayEvents: [{ kind: "H2H" | "BRACKET", visible: boolean, offsetSec: number }]`, đã sắp theo thời gian.
- `offsetSec` là **số thực** (làm tròn 3 chữ số thập phân), khác `offsetSec` của segment vốn là số nguyên. Dùng `double`, không dùng `_nonNegativeInt`.
- Sự kiện trong khoảng trống giữa hai đoạn được Backend dồn về đầu đoạn kế; sau đoạn cuối thì dồn về cuối. App không phải tự xử lý.

## Quyết định

1. **Trạng thái suy ra thuần từ vị trí**, không giữ cờ riêng: tua tới/lui luôn ra đúng overlay. `matchReplayOverlayAt` là hàm thuần trong `match_replay_timeline.dart`, cùng quy tắc với Web (`overlayStateAt`): sắp theo `offsetSec`, lấy sự kiện cuối `<= seconds` cho mỗi loại, mặc định tắt.
2. **Tái dùng quy tắc live**: kết quả `{h2h, bracket}` đi qua `liveOverlayToShow(..., matchEnded: false)` để ưu tiên Sơ đồ khi cả hai bật, y như live. Không viết lại thứ tự ưu tiên.
3. **Không `setState` cả màn mỗi giây**: `build` của `live_score_screen.dart` rất lớn. Vị trí phát lại đi qua `ValueNotifier<int?>`; chỉ khối overlay bọc `ValueListenableBuilder`. `null` nghĩa là đang không phát lại (live hoặc chưa có video).
4. **Chế độ phát lại** = `LiveVideoBox` đang dựng `MatchReplayPlayer`. Chỉ khi đó overlay lấy từ mốc; còn lại giữ nguyên đường live (`liveOverlayToShow` theo cờ server).
5. **Nút đóng overlay**: ẩn cục bộ đến khi loại overlay đang hiện thay đổi (hết mốc hoặc chuyển sang overlay khác) hoặc người xem tua; không lưu lâu hơn.
6. **Độ mịn**: vị trí phát lại của App tính theo giây nguyên (`_displayedSeconds`), nên overlay bật/tắt trễ tối đa < 1 giây so với mốc thực. Chấp nhận được.

## Rủi ro

- `live_score_screen.dart` và `match_replay_player.dart` còn có lane khác sửa; chỉ đụng khối overlay và một callback mới, kiểm `lane overlap` trước khi sửa.
- Trận quay trước `d0445b04` không có mốc: không có overlay, đây là giới hạn của dữ liệu, không phải lỗi.
- Người chấm điểm vẫn thấy nút H2H/Sơ đồ khi xem lại: bật/tắt lúc đó không ghi vào bản ghi cũ. Giữ nguyên hành vi hiện tại, ghi vào câu hỏi mở.
