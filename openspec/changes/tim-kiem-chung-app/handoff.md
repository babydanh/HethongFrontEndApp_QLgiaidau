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
- Review độc lập đòi sửa: thanh tìm VĐV ra ngoài `FutureBuilder` (reload không tháo thanh); `AnimatedOpacity` luôn có mặt thay `Opacity` bọc từng thẻ; số kết quả Lịch đếm theo phần đang hiển thị kèm dòng "ở ngày hoặc sân đang ẩn"; memo kết quả tìm và danh sách trùng lịch; fold từ khoá một lần; a11y (tooltip kèm số điều kiện, chip cao tối thiểu 40dp).
- Cách test reload VĐV: tab không có hook để gọi `_reload` từ ngoài, nên test giữ future ở trạng thái chờ (cùng trạng thái `waiting` của reload) và kiểm toolbar/thanh/chữ/focus còn nguyên sau khi future xong.
- VĐV: lọc ẩn các hàng nội dung không có VĐV khớp; hàng mở ra chỉ liệt kê VĐV khớp (bộ lọc chip trạng thái cũ vẫn chạy song song).

## Ràng buộc đang có
- ARB: thêm 17 key vào `app_vi.arb` / `app_en.arb` (chèn sau `schedulePrint`, không ở cuối file để tránh xung đột với nhánh khác), đã chạy `flutter gen-l10n`.
- `PopScope` của thanh tìm chỉ chặn Back khi thanh đang hiển thị (`TickerMode` bật và route là route hiện tại); thanh bị che (hub dùng `IndexedStack`) không nuốt Back. Có test.
- State tìm kiếm là `autoDispose` + `ref.keepAlive()` với 10 phút ân hạn (`_keepAliveGrace`): sống qua đổi tab và reload danh sách, rồi tự giải phóng khi rời màn. Vẫn còn `open` được nhớ trong 10 phút đó (không tự lấy focus khi quay lại).
- Bộ lọc có giá trị không còn được cung cấp (đổi sân/nội dung, hoặc danh sách đang nạp lại) bị bỏ qua khi hiển thị và khi lọc (`SearchFilterState.pruned`) nhưng KHÔNG xoá khỏi state, nên quay lại khi tuỳ chọn xuất hiện lại. `SearchFilterToggle` nhận `groups` để badge không đếm giá trị đó.
- Khoá state: `'<tournamentId>:schedule'` và `'<tournamentId>:athletes'`.

## Ràng buộc thay đổi lần này
- Hàng công cụ lưới Lịch không còn nút in / xuất riêng, nằm trong ⋯.
- Nhánh khác `lich-logic-nhu-web`, `tab-ket-qua-nhap-diem-xep-lich`, `bang-dau-gon-search-so-do` có thể đụng cùng file lưới/ARB: gộp cần chú ý.

## Câu hỏi còn mở
- Khi có tab Kết quả thì nối bằng `SearchFilterToggle` + `SearchFilterBar` với khoá `'<id>:results'`.
- VĐV: có nên tự mở rộng hàng khi tìm không? Hiện không (mỗi hàng mở sẽ gọi API danh sách riêng).
- Chưa nhìn bằng mắt trên máy thật.
