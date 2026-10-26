## Why
App chỉ hiện "Trận N" (`matchNumber` lấy từ `matchOrder`), lặp lại giữa các vòng/nội dung. Backend (change cùng tên) sẽ trả `matchCode` (ví dụ `DN1K2T3`); App hiển thị mã đó kèm tên tắt hai bên, giống Web.

## What Changes
- Thêm `String? matchCode` vào entity `Match` và `TournamentWorkspaceMatch`, parse từ JSON (thiếu thì `null`).
- Helper `formatMatchCode` + tên tắt (cùng quy tắc và cùng bộ test với Web): `matchCode` + chữ cái đầu hai từ cuối của mỗi tên, bỏ dấu, `Đ`→`D`, chữ hoa; đôi lấy VĐV thứ nhất; thiếu `matchCode` thì giữ "Trận N" cũ.
- Hiện mã ở: dòng bảng trận bracket, nhãn trận của `match_round_label`, màn Vận hành của ban tổ chức, lưới lịch, nhãn trận của workspace, xuất Excel; thẻ vòng/ma trận vòng bảng nếu App có (kiểm khi làm).
- Không hiện: overlay livestream, trận câu lạc bộ.

## Out of scope
- Tính mã ở App; đổi trường cũ; in mã/QR.

## Capabilities
### New Capabilities
- `match-code-display`: hiển thị mã trận ở App.

### Modified Capabilities
- Không có.

## Impact
- Phụ thuộc Backend change `ma-tran-ma-so-tran`: Backend gộp trước. Thiếu trường vẫn chạy.
- Màn đang chạy trên máy thật dùng chung (`app-run.py`); không `flutter run` riêng trong worktree.
