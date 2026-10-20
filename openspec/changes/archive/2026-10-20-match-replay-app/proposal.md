# Phát lại trận đã kết thúc trong App

## Why
Người xem hiện chỉ thấy trình phát live hoặc trạng thái không có tín hiệu sau khi trận kết thúc, dù Backend cung cấp danh sách các đoạn MP4 đã ghi. Người xem cần xem toàn bộ bản ghi như một video liên tục, không phải tự mở từng đoạn.

## What Changes
App đọc `GET /api/v1/livestream/matches/:matchId/replay` khi trận không có nguồn live. Nếu payload `available` có đoạn phát hợp lệ, App phát các đoạn theo timeline chung, hỗ trợ tua toàn cục và chuyển tiếp tự động. Mỗi đoạn chỉ phát `[clipStartSec, clipStartSec + durationSec)`, không phát nội dung dư ở đầu/cuối file. Model bỏ qua segment thiếu URL/không an toàn. Controller kế tiếp được chuẩn bị trước, lỗi tải một segment thì bỏ qua segment đó. Trận chưa kết thúc (`NOT_FINISHED`) hoặc không có bản ghi giữ nguyên giao diện hiện tại.

## Source of truth
Hợp đồng đã duyệt tại `local://match-replay-contract.md` (chốt 2026-10-20), cùng endpoint đã triển khai song song ở Backend. App là client của endpoint, không sửa Backend.

## Out of scope
- Không thay đổi điều kiện quyền xem, API/Backend hoặc Web.
- Không thay đổi màn hình danh mục bản ghi theo ngày.
- Không upload, cắt, hợp nhất tệp hay phát URL nội bộ.
- Không thay đổi player live khi còn phát trực tiếp.

## Acceptance
- Parse model an toàn và loại segment URL thiếu/không phải HTTPS.
- Repository gọi replay endpoint theo envelope chuẩn.
Player có timeline chung, tua toàn cục, dùng `clipStartSec` để bỏ phần đầu thừa và dừng ở cuối ước tính, prebuffer khoảng 10 giây, tự chuyển và dispose controller cũ.
- LiveVideoBox chỉ chọn replay khi không live và available; trường hợp còn lại giữ no-signal hiện tại.
- Unit/widget tests và analyze file liên quan pass; OpenSpec strict validate + archive pass.