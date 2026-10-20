# Proposal

## Why

App chưa có cách chia đội vào bảng vòng bảng; BTC chỉ chỉnh được slot ở nhánh loại trực tiếp. Cấu hình vòng bảng đã thuộc nội dung giải trên Backend, nhưng App chưa đọc/lưu cấu hình đó nên chia bảng thủ công và sinh lại sơ đồ không đồng bộ.

## What Changes

- Thêm màn phân bảng dùng cấu hình của division, bảng “Chưa xếp”, số bảng khả dụng theo số đội hợp lệ, kéo-thả có vị trí chèn và menu chuyển bảng.
- Lưu `groupsConfig` cùng `roundConfig` hiện tại bằng PATCH cấu hình division; khóa thao tác khi vòng bảng đã bắt đầu/có kết quả; nếu sơ đồ đã sinh nhưng chưa đấu thì yêu cầu Backend sinh lại với `allowReset: true`.
- Cho phép bốc thăm chọn division tường minh khi giải có nhiều nội dung; không tự đoán nội dung khi chưa chọn.
- Bổ sung kiểm thử cấu hình, payload PATCH, thao tác giao diện, trạng thái khóa, rollback và localization tiếng Việt/Anh.

## Capabilities

### New Capabilities
- `group-stage-assignment`: Đọc, chỉnh sửa và lưu phân bảng vòng bảng từ màn BTC của một nội dung.

### Modified Capabilities
- `bracket-draw-publish`: Cho phép dùng division đang được chọn khi sinh sơ đồ ở giải nhiều nội dung; vẫn không tự chọn thay BTC.

## Impact

- App: `TournamentDivision`, cấu hình/resolver vòng bảng, repository và providers; màn `BracketViewScreen`, route quản trị, màn phân bảng mới, `AutoDrawScreen`, hai tệp ARB và test Flutter.
- API hiện có: `PATCH /api/v1/tournaments/:tournamentId/divisions/:divisionId/config` với `isConfigOverride: true` và `roundConfig.groupsConfig`; sinh lại bằng `POST /api/v1/tournaments/:id/generate-bracket` với đúng `divisionId`.
- Backend: không thêm endpoint hoặc đổi hợp đồng. Web song song dùng cùng cấu hình division; thay đổi App không yêu cầu sửa Web.
- Phạm vi loại trừ: không chuyển đội qua `PATCH /tournaments/groups/:id`, không sửa quy trình kéo-thả slot knockout, không thêm dependency hoặc API mới.
