## Why

Tab "Bảng đấu" ở màn quản lý (hub) vẫn dùng giao diện vòng bảng cũ (thanh tab bảng riêng, nút "Quản lý bảng" mở màn xếp bảng riêng), khác hẳn trang chi tiết giải. Người dùng muốn màn quản lý giống trang chi tiết (accordion theo hạng mục, Bảng | Playoff, thẻ "Bảng A" với Bảng chéo / Xếp hạng / Theo lượt) và kéo thả đội giữa các bảng ngay tại đó.

Giả định (chưa xác nhận bằng lời, suy ra từ ảnh chụp): "bag3 cũ" = "bảng cũ" = giao diện vòng bảng cũ ở màn quản lý.

## What Changes

- `GroupStageView` nhận thêm tham số tuỳ chọn để bật chế độ chỉnh sửa: giữ lâu một đội rồi thả sang thẻ bảng khác để chuyển bảng.
- `PublicBracketView` / `PublicBracketLoader` truyền các tham số đó xuống (thêm tham số, không đổi hành vi mặc định).
- `BracketViewScreen`: nhánh `hasGroupStage` dùng view chung ở chế độ chỉnh sửa khi `canEditBracket`; bỏ thanh tab bảng cũ và nút "Quản lý bảng".
- Lưu thay đổi dùng chung logic của `GroupStageAssignmentScreen._save` (PATCH config + sinh lại bracket nếu chưa có trận bắt đầu).

## Out of scope

- Không đổi Backend / Web / API (dùng lại `PATCH /tournaments/{id}/divisions/{divisionId}/config` và `POST /tournaments/{id}/generate-bracket`).
- Không đổi `CrossTableView` / `StandingsView` (còn dùng ở `bracket_diagram_screen.dart`).
- Không đổi nhánh knockout / Swiss; không gỡ `GroupStageAssignmentScreen` (route cũ vẫn chạy).
- Không thêm package.

## Capabilities

### New Capabilities
- `bracket-group-stage-management`: quản lý vòng bảng bằng giao diện chung với trang chi tiết, có kéo thả chuyển đội giữa các bảng.

### Modified Capabilities
(không)

## Impact

- App: `lib/features/bracket/widgets/group_stage_view.dart`, `public_bracket_view.dart`, `screens/bracket_view_screen.dart`, `screens/group_stage_assignment_screen.dart` (tách hàm lưu), test liên quan.
- Lane khác đụng `public_bracket_view.dart`: `bracket-quan-ly-moi` (chỉ thêm tham số, tránh xung đột).
