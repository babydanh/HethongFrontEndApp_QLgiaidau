## Why

Màn chi tiết buổi Social trên App chỉ hiện tab "Trận đấu" khi buổi gắn CLB (`social_detail_screen.dart:234`). Buổi cá nhân (không có `communityId`) không có tab, trong khi Backend change `tran-dau-buoi-ca-nhan` đã cho host buổi cá nhân tạo và nhập kết quả trận qua `socialSessionId`. Web đã bỏ gate tương tự; App cần ngang bằng.

## What Changes

- Tab "Trận đấu" hiện cho cả buổi cá nhân và buổi gắn CLB.
- Buổi cá nhân: danh sách trận lấy theo `socialSessionId`; nút "Tạo trận" chỉ cho host; người chơi chọn từ người tham gia đã duyệt (không lọc theo thành viên CLB, không tải thành viên CLB).
- Buổi gắn CLB: giữ nguyên hành vi hiện tại.
- Không đổi Backend, không đổi bố cục tab.

## Capabilities

### New Capabilities
- `social-personal-match-tab`: tab Trận đấu của buổi Social không gắn CLB trên App.

### Modified Capabilities
(không có)

## Impact

- App: `social_detail_screen.dart`, `social_match_tab.dart`, `club_standalone_match_dialog.dart`, `api_club_match_session_repository.dart`, test `social_match_tab_test.dart`.
- Phụ thuộc Backend `tran-dau-buoi-ca-nhan` đã deploy (staging đã có).
