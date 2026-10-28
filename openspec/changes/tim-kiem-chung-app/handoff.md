# Handoff: tim-kiem-chung-app

## Mục tiêu
Một icon tìm kiếm trong hàng công cụ của các tab danh sách BTC; bấm thì thả xuống ô tìm + bộ lọc; một component dùng chung (`SearchFilterToggle` + `SearchFilterBar`), mỗi tab chỉ truyền nhãn, bộ lọc, số kết quả. Bản vẽ: `~/.lavish/tim-kiem-chung.html`.

## Trạng thái
- Xong: component `lib/shared/widgets/search_filter_bar.dart` (state Riverpod theo khoá tab, debounce 200ms, khớp không dấu), nối vào tab Lịch (lưới sân) và tab VĐV của hub quản lý.
- Chưa nối (không có màn trong origin/main): tab Kết quả; Bảng đấu không có danh sách lọc được; chế độ danh sách trận trong `OrganizerOpsScreen` (nút grid/list) chưa nối.
- Chip bỏ vì không có field thật: "Có mặt" (VĐV) — `OrganizerOpsParticipant` không có cờ check-in.

## Đã thử
- Toolbar lưới Lịch cũ là `Row` cố định, tràn 343px ở 320dp (có từ trước). Đổi sang `Wrap` lồng nhau -> hết tràn, test 320dp xanh.
- Dùng `dart format` cả file lưới -> kéo theo 260 dòng đổi định dạng ngoài phạm vi; đã hoàn tác bằng cách áp lại sửa từ HEAD, không format.
- Lịch: 🖨 và Xuất Excel chuyển vào menu ⋯ (`schedule-more-button`); test cũ `schedule_print_test.dart` sửa theo (bấm ⋯ trước).
- VĐV: lọc ẩn các hàng nội dung không có VĐV khớp; hàng mở ra chỉ liệt kê VĐV khớp (bộ lọc chip trạng thái cũ vẫn chạy song song).

## Ràng buộc đang có
- ARB: thêm 13 key vào `app_vi.arb` / `app_en.arb` (chèn sau `schedulePrint`, không ở cuối file để tránh xung đột với nhánh khác), đã chạy `flutter gen-l10n`.
- `PopScope` của thanh tìm chặn Back khi thanh mở (đóng thanh trước). Tab khác trong `TabBarView` vẫn giữ PopScope của thanh đang mở [SUY LUẬN]: Back ở tab khác có thể đóng thanh ẩn trước.
- Khoá state: `'<tournamentId>:schedule'` và `'<tournamentId>:athletes'`.

## Ràng buộc thay đổi lần này
- Hàng công cụ lưới Lịch không còn nút in / xuất riêng, nằm trong ⋯.
- Nhánh khác `lich-logic-nhu-web`, `tab-ket-qua-nhap-diem-xep-lich`, `bang-dau-gon-search-so-do` có thể đụng cùng file lưới/ARB: gộp cần chú ý.

## Câu hỏi còn mở
- Khi có tab Kết quả thì nối bằng `SearchFilterToggle` + `SearchFilterBar` với khoá `'<id>:results'`.
- VĐV: có nên tự mở rộng hàng khi tìm không? Hiện không (mỗi hàng mở sẽ gọi API danh sách riêng).
- Chưa nhìn bằng mắt trên máy thật.
