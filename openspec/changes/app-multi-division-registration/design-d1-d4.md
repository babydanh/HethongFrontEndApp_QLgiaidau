# D1 / D4 — trạng thái CHỜ RÀ SOÁT

Không triển khai D1/D4 trong nhánh App D2/D3.

- **D1, cần rà soát pháp lý:** `rankingConsentAt` là mốc ELO được tính; `accountLinkConfirmedAt` xác nhận roster thuộc tài khoản và hiện quyết định hiển thị banner. Route `POST /tournaments/:id/participants/me/ranking-consent` hiện xác nhận cả hai mốc. Đề xuất BTC duyệt thay xác nhận của VĐV có thể không phải consent hợp lệ; cần legal review. App không tự thay trạng thái consent/banner.
- **D4, cần rà soát bảo mật:** các route người chơi nhận lời mời/đăng ký và route roster xác nhận có thể bị ảnh hưởng khi thay `@Verified()`. Chưa có thay đổi App hoặc guard; email nhập/thêm vẫn phải yêu cầu xác minh tài khoản cho tới khi security review chấp thuận.
- **Quyết định:** `NEEDS_HUMAN_REVIEW`; App tiếp tục dùng dữ liệu và quyền do Backend cung cấp.
