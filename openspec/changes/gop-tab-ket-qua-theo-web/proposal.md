## Why

Web (commit `05da19f2`, change `gop-tab-ket-qua-cong-khai`) gộp tab "Đang diễn ra" vào tab "Kết quả" và đặt tab đó ở cuối thanh tab. App vẫn có hai tab riêng, đặt ở đầu, nên hai nền tảng lệch nhau.

## What Changes

- Bỏ tab "Đang diễn ra". Tab "Kết quả" nằm cuối thanh tab (sau "Nhà tài trợ"), có chấm đỏ và số trận khi có trận đang đấu.
- Tab gộp, theo hạng mục đang chọn: bục vinh danh (chỉ khi hạng mục đã có kết quả chính thức) rồi bảng trận `ResultsMatchBoard`.
- Hạng mục đã xong (có bục): bảng chỉ liệt kê trận chung kết của sơ đồ loại trực tiếp; thể thức khác hoặc không tìm ra chung kết thì giữ nguyên bảng đầy đủ.
- Hạng mục chưa xong: không có bục, không có thẻ "chưa có kết quả"; bảng hiện mọi vòng.
- Bục: bỏ nút chia sẻ riêng, chạm vào bục thì mở chia sẻ.
- Nhiều hạng mục: chọn bằng dải hạng mục như tab Kết quả hiện tại, thay cho danh sách thu mở của tab Đang diễn ra.
- Thêm hàm thuần `pickFinalMatches` (port của Web `final-matches.ts`) có test.

## Out of scope

- Không đổi Backend, Web, `ResultsMatchBoard` ở khu quản lý giải, và điều kiện hiện tab của ban tổ chức (`canManage` vẫn luôn thấy).
- Không đổi tab mặc định khi mở giải (vẫn là Tổng quan).

## Impact

- Sửa: `tournament_intro_screen.dart`, `results_tab.dart`, `results_match_board.dart`.
- Tạo: `results_merged_tab.dart`, `final_matches.dart` và test.
- Xóa: `live_tab.dart` cùng `live_tab_test.dart` (không còn nơi dùng).
- Rủi ro: luật chọn trận chung kết phải khớp Web; có test đối chiếu.
