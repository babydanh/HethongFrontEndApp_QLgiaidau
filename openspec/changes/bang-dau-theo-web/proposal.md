## Why
Tab "Bảng đấu" của App chỉ có bảng xếp hạng DataTable và bảng chéo ô cố định 92px, không bấm xem chi tiết trận. Web đã có bảng chéo, bảng xếp hạng, theo vòng và popup trận. App cần cùng trải nghiệm (đợt 1: vòng bảng).

## What Changes
- Trang công khai (`PublicBracketView`): vòng tròn và tab "Bảng" của vòng bảng + playoff dùng `GroupStageView` mới.
- Mỗi bảng là thẻ "Bảng A" + "N Đội", 3 chế độ: Bảng chéo (mặc định), Bảng xếp hạng, Theo vòng; chuyển lượt khi có nhiều lượt.
- Bảng chéo: cột STT + tên cố định, cột đối thủ cuộn ngang, không phân trang, không chữ gợi ý; đơn 1 dòng tên, đôi 2 dòng.
- Bấm ô/trận mở bottom sheet chi tiết trận (tên đầy đủ, điểm từng set, sân, giờ, nút Xem trận).
- Màn tổ chức (`bracket_view_screen`, `bracket_diagram_screen`) giữ nguyên `CrossTableView`/`StandingsView`.
- Ngoài phạm vi (đợt 2): playoff nhánh thắng/thua phân trang; không port H2H tiebreak của Web (giữ thứ tự xếp hạng từ API).

## Impact
`lib/features/bracket/widgets/*`, `lib/core/participants/participant_display.dart` (thêm cờ `abbreviate`), `lib/l10n/app_{vi,en}.arb`.
