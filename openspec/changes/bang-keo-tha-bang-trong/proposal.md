## Why

Sau khi màn quản lý dùng view vòng bảng chung (change `bang-quan-ly-keo-tha`), chủ giải chưa kéo được đội vào bảng đang trống, và đội chưa xếp bảng không hiện nên không kéo vào bảng được. Icon cài đặt ở thanh Tạo/Xoá bracket chỉ nhảy sang tab "Hạng mục" vốn đã có trên thanh tab, nên thừa.

## What Changes

- `GroupStageView` (chế độ chỉnh sửa) dựng thẻ bảng từ config: bảng chưa có đội vẫn hiện thẻ trống nhận thả.
- Thêm khu "Chưa xếp" liệt kê đội chưa thuộc bảng nào; kéo từ đó vào bảng.
- Bỏ icon cài đặt (`bracket-mgmt-manage`) và tham số `onManageDivisions` trên đường `BracketManagementBar` ← `BracketViewScreen` ← hub, cùng key l10n `bracketMgmt_manageTooltip`.

## Out of scope

- Không đổi Backend/Web/API. Không làm kéo ô trong Playoff, tự cuộn khi kéo, đổi thứ tự trong cùng bảng, thả đội về "Chưa xếp".

## Capabilities

### New Capabilities
- `bracket-group-stage-management`: bổ sung bảng trống nhận thả và khu "Chưa xếp".

### Modified Capabilities
(không)

## Impact

- App: `group_stage_view.dart`, `public_bracket_view.dart`, `bracket_view_screen.dart`, `bracket_management_bar.dart`, `tournament_management_hub_screen.dart`, `app_vi.arb`, `app_en.arb`, test liên quan.
