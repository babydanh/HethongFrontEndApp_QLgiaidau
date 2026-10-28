## Why

Màn "Thông tin giải" là 3 thẻ dài (chỉ một thẻ có nút Lưu, ảnh thì tải lên là lưu ngay) và màn "Địa điểm & sân" mỗi sân là một khối cao có ô URL camera hiện sẵn kèm chip xoá sát nhãn. Người dùng đã duyệt thiết kế gọn hơn (mục 16 và 17 trong `quan-ly-giai-ui-audit.html`).

## What Changes

- Thông tin giải: 4 nhóm thu gọn/mở được (Chung, Nhận diện, Giải thưởng, Liên hệ), MỘT nút "Lưu thay đổi" dính đáy (xám khi chưa sửa, spinner khi đang lưu, chặn bấm đúp), hỏi lại khi thoát lúc chưa lưu.
- Địa điểm & sân: mỗi sân một dòng (tên, "Đã gắn camera"/"Chưa gắn camera", nút sửa camera, menu ⋮ chứa Xoá sân kèm hộp xác nhận); URL camera không hiện ngoài danh sách, chỉ hiện trong sheet với giá trị che dấu, nút Hiện, Lưu, Gỡ camera.
- Không đổi API/DTO. Tải logo/ảnh bìa/thư viện ảnh vẫn gửi ngay khi chọn ảnh (hành vi hiện tại, không đợi nút Lưu).
- Không đụng tab Tổng quan.

## Impact

`tournament_management_section_screen.dart`, `tournament_management_brands_section.dart`, `tournament_management_venues_section.dart`, `tournament_management_hub_screen.dart` (hỏi khi thoát), widget mới `court_camera_sheet.dart`, ARB vi/en.
