# Proposal

## Why

Màn Kết quả chiếm nhiều diện tích cho bục trao giải, đẩy danh sách hạng xuống thấp; thẻ hiện tên đội nhưng chưa cho biết rõ thành viên đơn hoặc cặp đôi. Bỏ bục và đưa tên đội, tên vận động viên cùng avatar vào danh sách giúp người xem nhận ra kết quả nhanh hơn trên màn hình điện thoại.

## What Changes

- Bỏ bục vinh danh khỏi màn Kết quả; giữ danh sách thứ hạng ngay dưới bộ chọn hạng mục hiện có.
- Dùng tên đội làm tên chính của thẻ; hiển thị tên thành viên lấy từ dữ liệu participant, ảnh đại diện và ảnh thay thế bằng chữ cái đầu khi thiếu ảnh.
- Giữ việc chọn hạng mục qua các hàng hiện có; dùng đúng `matchType` của hạng mục đang chọn để trình bày một thành viên cho nội dung đơn và hai thành viên cho nội dung đôi, không thêm bộ lọc song song.
- Giảm màu nhấn và trang trí của thẻ để ưu tiên tên, hạng và avatar.

## Capabilities

### New Capabilities
- `tournament-results`: Hiển thị kết quả, hạng thưởng, tên đội/thành viên và avatar theo hạng mục giải đấu được chọn.

### Modified Capabilities

- Không có; kho spec chưa có capability quy định hành vi màn Kết quả.

## Impact

- App: `lib/features/tournament/widgets/results_tab.dart` và kiểm thử widget liên quan; bộ chọn hạng mục hiện tại tiếp tục cấp ID/tên cho màn kết quả.
- API: không đổi endpoint hay field; tận dụng `participant.teamName`, `participant.members[].fullName` và `participant.members[].avatarUrl` đã được dùng trong luồng avatar hiện tại.
- Backend API và Web: không bị ảnh hưởng.
- Ngoài phạm vi: thay đổi API/dữ liệu, thay đổi bộ chọn hạng mục, sửa màn kết quả trên Web, thay đổi thứ hạng hoặc quy tắc trao giải.
