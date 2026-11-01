## Why
Mở một giải rồi chuyển sang giải khác trong App bị lag: các request nối đuôi nhau, hai vòng xoay toàn màn hình thay cho skeleton, tab Đang diễn ra/Kết quả hiện muộn làm thanh tab nhảy, một lỗi tải đội làm mất cả nội dung các tab, và bảng trận dựng lại toàn bộ mỗi lần build. Căn cứ: audit 2026-11-01 (3 subagent đọc code App, Web, tầng dữ liệu).

## What Changes
- Tải song song `/divisions` và `/sponsors` trong `getById`; song song `/participants` và `/divisions` khi tải đội.
- Màn chi tiết giải: skeleton thay vòng xoay; không chặn `TabBarView` bằng `introTeamsProvider`; tab Đang diễn ra/Kết quả quyết định theo trạng thái giải, chỉ chấm đỏ/số trận chờ dữ liệu trận; dựng lại màn khi số trận live/kết quả đổi chứ không mỗi lần luồng trận phát.
- Luồng trận: phát ngay dữ liệu đã lưu khi mở lại giải; bỏ qua sự kiện socket của giải khác.
- Provider Lite giữ danh sách trận cuối khi một lần poll lỗi (không ghi đè bằng danh sách rỗng).
- Bảng trận (`ResultsMatchBoard`): không tính lại vòng/nhãn mỗi lần build, danh sách trận dựng lazy, ô tìm có debounce.

## Out of scope
`autoDispose` cho provider bảng đấu (Riverpod 3 đã tự tạm dừng provider không có người nghe), parse JSON bằng isolate, cache ảnh đĩa, `CancelToken` cho phân trang trận, endpoint tóm tắt mới ở Backend, gộp `/divisions` trùng giữa các repo, tối ưu các tab Bảng đấu/Lịch/Đội.

## Capabilities
### New Capabilities
- `tournament-open-speed`: tốc độ và độ ổn định khi mở màn chi tiết giải.
### Modified Capabilities
(không)

## Impact
`api_tournament_repository.dart`, `api_team_repository.dart`, `api_match_repository.dart`, `query_providers.dart`, `tournament_intro_screen.dart`, `results_match_board.dart`, `results_rounds.dart`, `live_tab.dart`.
