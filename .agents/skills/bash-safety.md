---
name: bash-safety
description: Quy chuẩn phòng thủ shell, bảo vệ an toàn tệp và dữ liệu trên Windows/PowerShell
---

# Bash & Shell Safety Guidelines

1. **Destructive Commands:**
   - Tuyệt đối không tự ý chạy `rmdir /s /q` hoặc `Remove-Item -Recurse -Force` mà không có đường dẫn rõ ràng và xác thực trước.
   - Luôn sử dụng đường dẫn cụ thể, tránh dùng wildcards (`*`) bừa bãi ở các thư mục root/hệ thống.

2. **Process Control:**
   - Khi terminate process (`taskkill` hoặc `Stop-Process`), luôn kiểm tra PID hoặc lọc chính xác tên process để tránh làm crash các dịch vụ hệ thống khác.

3. **State Preservation:**
   - Tránh ghi đè file cấu hình toàn cục mà không sao lưu hoặc kiểm tra nội dung hiện có.
   - Ưu tiên kiểm tra cú pháp và dry-run trước khi áp dụng thay đổi hàng loạt.
