## Why

Ba màn quản lý giải của App còn lệch thiết kế đã duyệt (màn 8, 9, 10 trong `quan-ly-giai-ui-audit`): sheet nội dung thi đấu là một trang cuộn dài, không có form đăng ký tuỳ biến cho BTC, và vòng đời giải chỉ là một nút trơn không cho thấy giải đang ở bước nào.

## What Changes

- Màn 8: `DivisionEditorSheet` chuyển sang accordion (Cơ bản, Luật vòng, Ràng buộc ELO, Vòng bảng/thể thức), mỗi mục có tóm tắt một dòng, chỉ mở một mục; thêm "Xem minh hoạ thể thức" (nội dung tĩnh lấy từ Web `FormatIllustration`, chưa có hoạt hình); nói rõ vì sao bị khoá khi đã có sơ đồ.
- Màn 9: màn mới "Form đăng ký" trong mục Người tham gia: danh sách câu hỏi kéo đổi thứ tự, vuốt xoá có xác nhận, Họ tên và Số điện thoại hiện cố định, loại câu hỏi Văn bản/Số/Chọn một/Chọn nhiều, lưu vào `tournamentConfig.registrationForm` qua `updateTournament` đã có.
- Màn 10: thanh bước vòng đời (Nháp, Xuất bản, Mở ĐK, Đang đấu, Kết thúc) + một nút kế tiếp, cảnh báo đủ đội kèm nút Đóng đăng ký, khoá nút Xuất bản kèm lý do khi còn phí công bố, xoá giải phải gõ lại tên giải.
- Không đổi hợp đồng API/DTO; không thêm package.

## Capabilities

### New Capabilities
- `app-division-editor`: accordion cấu hình nội dung thi đấu và minh hoạ thể thức.
- `app-registration-form`: BTC chỉnh form đăng ký tuỳ biến trên App.
- `app-tournament-lifecycle`: thanh bước vòng đời giải và các cổng chặn.

### Modified Capabilities

## Impact

- `lib/features/tournament/widgets/division_editor_sheet.dart` và widget mới cạnh nó.
- File mới cho form đăng ký và thanh vòng đời; chỉnh nhỏ `tournament_management_section_screen.dart` (thẻ vòng đời) và `tournament_management_hub_screen.dart` (xoá giải) là hai file nhánh khác cũng sửa.
- `lib/l10n/app_vi.arb`, `app_en.arb`.
