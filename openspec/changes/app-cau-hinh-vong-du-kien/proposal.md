## Why
Web hiện "Luật theo vòng" ngay khi hạng mục chưa có sơ đồ (vòng tính từ số đội). App chỉ mở được khi đã có sơ đồ, nên người tổ chức App không đặt được luật vòng trước.

## What Changes
- Hàm thuần `computePlannedRounds` (`lib/features/tournament/utils/planned_rounds.dart`) tính vòng dự kiến giống công thức Web.
- Hạng mục đã lưu, chưa có sơ đồ, có vòng dự kiến: menu thẻ hạng mục hiện "Cấu hình từng vòng"; mở `StageRoundConfigSheet` ở chế độ `draft`, lưu bằng `updateDivisionConfig`.
- Đã có sơ đồ: giữ nguyên. Thụy Sĩ hoặc chưa đặt số đội (knockout): ẩn.
- Không đổi Backend, Web, contract, chuỗi i18n.
