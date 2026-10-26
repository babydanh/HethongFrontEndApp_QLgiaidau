## Why
App chỉ hiện "Trận N" (`matchNumber` lấy từ `matchOrder`), lặp lại giữa các vòng/nội dung. Backend (change cùng tên) trả `matchCode` hoàn chỉnh (ví dụ `DNTB-K1-T3`, không có `#`); App thêm `#` ở đầu khi hiển thị (`#DNTB-K1-T3`), giống Web. Tên VĐV không nằm trong mã.

## What Changes
- Thêm `String? matchCode` vào entity `Match` và `TournamentWorkspaceMatch`, parse từ JSON (thiếu thì `null`).
- Helper `formatMatchCode(match, {l10n})` giữ chữ ký công khai: trả `#` + `matchCode`; thiếu `matchCode` thì giữ "Trận N" cũ. Bỏ phần ghép tên tắt VĐV (xoá `abbreviateNameForCode` nếu không còn nơi dùng) để các màn gọi `formatMatchCode`/`matchCodeOrNull` không phải sửa. Cùng quy tắc và cùng bộ test với Web.
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
