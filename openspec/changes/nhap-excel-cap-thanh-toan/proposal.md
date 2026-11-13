# Proposal

## Why

App Flutter có parser Excel riêng (`lib/features/organizer_ops/utils/roster_excel_parser.dart`, `lib/core/services/roster_excel_reader.dart`, `lib/features/organizer_ops/screens/roster_import_sheet.dart`) sao chép alias của Web nên mắc cùng lỗi: không nhận cặp từ STT gộp/trùng, không tách phần "chưa có cặp", không map `Số điện thoại liên hệ` và `Trình điểm`, mặc định đã thanh toán, không đọc ô gộp và không gọi AI layout. Nguyên nhân và quyết định nghiệp vụ: `web/openspec/changes/nhap-excel-cap-thanh-toan/proposal.md`.

## What Changes

App có ĐẦY ĐỦ logic như Web (chủ dự án yêu cầu không làm bản rút gọn), tám mục:

1. Đọc ô gộp từ gói `excel` (`Sheet.spannedItems`); STT gộp dọc hoặc hai dòng liền cùng STT là một cặp; mã cặp phạm vi trong khối.
2. Slot `pairCode` và ghép theo mã như Web, kể cả ô mã trống kế thừa mã dòng trên và dòng tiêu đề `Cặp n`.
3. Dòng tiêu đề phần (`DANH SÁCH VĐV CHƯA CÓ CẶP`, `chưa có cặp`, `chờ ghép`...) tách phần VĐV lẻ chờ ghép; bỏ dòng chỉ có STT.
4. Cột đồng đội (`VĐV đăng ký đứng chung`, `đứng chung`, `đồng đội`, `partner`) là gợi ý, khớp mờ như Web, không tạo VĐV từ biệt danh.
5. Thanh toán: cùng bảng alias và giá trị như Web; không có thông tin thì CHƯA thanh toán; gửi `isPaid` thật lên Backend.
6. Alias SĐT `số điện thoại liên hệ`, trình điểm lấy số đầu (kèm `eloSource` để Backend kiểm đúng thang).
7. Gọi `POST /ai/tournaments/:id/roster-layout` khi luật không đủ tin (cùng guard `rulesLayoutIsConfident` và dấu hiệu cặp không ghép được như Web); `aiAvailable:false`/429/503 thì giữ kết quả luật và báo trạng thái trên UI. Hàm gọi API ở `lib/data/repositories/api/api_roster_layout_repository.dart` qua interface riêng `RosterLayoutRepository` (không đụng `TournamentManagementRepository` nên không vỡ các fake test hiện có); digest che dữ liệu cá nhân như Web.
8. Test dùng cùng bố cục fixture giả như Web (`.xlsx` dựng trong test): 11 cặp + 7 VĐV lẻ, 0 đã thanh toán. Test ID `TC-APP-ROSTER-*`.

Repo khác: Backend nhận `isPaid` và `mergedRegions`/`singlesFromRow` (change cùng tên ở Backend).

## Out of scope

- Tách khối theo luật nhiều header/tiêu đề nội dung trong một sheet (`detectRosterLayout` của Web): App chỉ đọc mỗi sheet một bảng bằng luật; sheet nhiều khối bị guard coi là không đủ tin để hỏi AI.
- Thêm tay VĐV, tên cột tùy chỉnh (`customMapping`), package mới.
