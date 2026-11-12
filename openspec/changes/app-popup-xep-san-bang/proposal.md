## Why
Sau khi tạo bracket từ popup, màn bảng đấu hiện "Chưa xếp 8 đội": cấu hình chỉ có số bảng, không có đội nào trong bảng, và lựa chọn xếp theo ELO / ngẫu nhiên của popup không tác động tới bảng. BTC mong chọn xong là đội được xếp luôn.

## What Changes
- Khi xác nhận popup (Round Robin / Vòng bảng), App chia các đội đã duyệt của nội dung vào bảng theo lựa chọn: ELO (rắn, mạnh nhất trước) hoặc ngẫu nhiên, ghi vào `roundConfig.groupsConfig.groups[].participantIds` rồi tạo bracket.
- Round Robin: một bảng chứa mọi đội.
- Backend từ chối danh sách (400, ví dụ đội miễn phí/chưa đóng phí mà App không thấy): lưu lại cấu hình không có `groups` rồi tạo lại để Backend tự bốc.
- Không tải được danh sách đội: tạo như cũ (Backend tự bốc).

## Impact
- App: `bracket_management_bar.dart`, hàm thuần mới `bracket_group_draw.dart`, `group_stage_config.dart` (đổi tên `groupStageGroupName` thành public), test và E2E TC-53.
- Backend/Web: không đổi.
