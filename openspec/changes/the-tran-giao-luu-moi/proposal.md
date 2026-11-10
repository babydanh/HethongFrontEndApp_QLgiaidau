## Why

Thẻ trận ở tab "Trận đấu" của buổi giao lưu chỉ có chữ (tên + trạng thái + tỉ số), không có avatar, và đường vào "bấm điểm trực tiếp" đang bị tắt (`showScoreboardAction: false`). Người dùng muốn thẻ gọn, có avatar chữ viết tắt chuẩn chung, chạm vào để nhập kết quả, và có nút chọn giữa bấm điểm trực tiếp hoặc nhập nhanh (lite).

## What Changes

- Thẻ trận dùng `ParticipantSideLines` (avatar tròn, chữ viết tắt và màu theo tên, giống Web) cho từng bên; tỉ số to ở bên phải, bên thắng in đậm.
- Trận chưa xong có hàng hai nút gọn: "Nhập nhanh" (mở hộp nhập kết quả, form lite) và "Bấm điểm" (mở bảng điểm trực tiếp `OfficialScorePage`). Chạm cả thẻ vẫn mở hộp nhập kết quả.
- Nút hiện cho mọi người đã đăng nhập; Backend vẫn là chốt quyền (`MATCH_SCORE_PERMISSION_REQUIRED` hiện lỗi trong hộp).

## Out of scope

- Sửa kết quả trận ĐÃ HOÀN THÀNH: Backend khoá (`MATCH_SCORE_LOCKED`, `completeStandaloneMatch` trả nguyên trạng) và có tính ELO; cần đổi Backend riêng, không làm ở đây.
- Không đổi API, không đổi `ClubStandaloneMatchResultDialog`.

## Capabilities

### New Capabilities
- `the-tran-giao-luu`: thẻ trận trong tab Trận đấu của buổi giao lưu.

### Modified Capabilities

## Impact

- `lib/features/social/widgets/match_tab/social_match_tab.dart`; test `test/features/social/social_match_tab_test.dart`.
