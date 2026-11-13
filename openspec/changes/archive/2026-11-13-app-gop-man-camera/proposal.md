## Why

Màn "Phát trực tiếp" ở menu quản lý và tab Camera làm trùng nhau: cả hai liệt kê camera, thêm camera và gán camera cho sân. Tab Camera còn hiện khối "Trận đấu" gồm mọi trận chưa xong, kể cả trận đã có sân (lặp với popup sân), và popup sân lặp chữ ("Camera: san1", "Camera đã sẵn sàng · san1", "Đang chiếu…"). Người dùng duyệt bản Lavish `app-camera-gop-hai-man.html`, chọn A/A.

## What Changes

- Mục "Phát trực tiếp" ở menu quản lý mở thẳng tab Camera; màn riêng không còn khối camera.
- Menu ⋮ của tab Camera thêm "Điện thoại & phiên phát": mở sheet phiên phát trực tiếp và điện thoại phát (điện thoại phát chỉ hiện khi giải thuộc cộng đồng, không còn câu báo lỗi).
- Khối trận ở tab Camera chỉ còn "Trận chưa có sân"; không có trận nào và không lọc thì ẩn.
- Popup sân: một dòng camera (trạng thái, tên, nút Đổi/Gán, nút QR stream key cho camera PUSH), nút ⏻ ở dòng tiêu đề, ô URL thu gọn trong "Sửa URL phát"; bỏ dòng "Đang chiếu" và dòng "Camera đã sẵn sàng" trùng.
- Bộ chọn camera trong popup cho xoá camera (chip có nút ✕, có hỏi lại).
- Gỡ `TournamentCameraPanel` (không còn nơi dùng).

## Out of scope

- Không đổi API Backend, không đổi Web.
- Không đổi tường camera, bộ lọc tìm kiếm, luồng tạo camera.

## Capabilities

### New Capabilities

- `camera-tab-merge`: tab Camera là nơi duy nhất quản lý camera của giải.

### Modified Capabilities

(không)

## Impact

- `lib/features/tournament/screens/tournament_management_hub_screen.dart`, `tournament_management_camera_section.dart`, `tournament_management_livestream_section.dart`
- `lib/features/tournament/widgets/camera_tab_header.dart`, `camera_court_card.dart`, `camera_court_info.dart`, `court_camera_row.dart`; xoá `tournament_camera_panel.dart`
- `lib/l10n/app_vi.arb`, `app_en.arb`
- Test: `test/features/tournament/camera_court_sheet_test.dart`, `camera_tab_redesign_test.dart`, `test/features/tournament_management_livestream_section_test.dart`, xoá `test/features/tournament_camera_panel_test.dart`, `integration_test/xem_tai_tro_livestream_ketqua_test.dart`
