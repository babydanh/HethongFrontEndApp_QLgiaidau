## Why

Tab "Kết quả" (bảng trận trong màn quản lý, cũng là bảng của tab "Đang diễn ra") của App xếp mọi vòng thành một dãy hộp cùng màu xanh, không phân biệt nhánh thắng, nhánh thua, chung kết tổng. Hộp không gập được nên giải 64 VĐV phải cuộn rất dài. Menu "Tới vòng" chỉ cuộn tới chỗ, không mở/gập. Bấm vào trận chỉ hiện hộp chọn "Vào trang Live / Tính điểm ngay", không có chỗ nhập điểm ngay tại bảng. Web (`ResultsBoard.tsx`) đã làm đủ những việc này.

## What Changes

- Mỗi vòng thuộc một nhánh (`main`, `winners`, `losers`, `grandFinal`); hộp có màu và biểu tượng riêng theo nhánh (xanh lá thắng, hổ phách thua, tím chung kết tổng, xám chính), giống `BOX_TONE` của Web.
- Vòng xếp theo nhánh rồi tới số vòng; mỗi vòng nhánh thua là một hộp riêng (khoá `losers|<số vòng>`).
- Bấm đầu hộp để gập/mở (mũi tên xoay); mặc định chỉ mở vòng còn trận chờ điểm (không có thì vòng cuối); khi đang tìm kiếm mở mọi hộp còn trận khớp; người dùng bấm tay thì luôn thắng.
- "Tới vòng": chọn một vòng thì mở đúng vòng đó, gập các vòng khác, rồi cuộn tới; mục menu có chấm màu nhánh và số trận chờ.
- Hàng trận: viền trái theo trạng thái (sẵn sàng xanh dương, chờ xám, đang đấu hồng, xong xanh lá, huỷ xám nhạt); hàng cột `# · Cặp đấu · Kết quả`; dòng meta có giờ, sân, trọng tài.
- Bỏ hai chip "Trễ giờ" và "Tranh chấp" khỏi thanh lọc của bảng (màn tiến trình vẫn mở bảng với hai bộ lọc đó khi cần, lúc ấy chip hiện ra đang chọn).
- Dấu "+" nhập điểm thành nút tròn lớn, rõ, nằm giữa hai bên đấu ở cột Kết quả (trước đây là dấu mờ nhỏ cạnh chữ "vs").
- Bấm trận (BTC/trọng tài) mở popup nhập điểm ngay tại bảng: hai bên (đơn một tên, đôi "A / B" kèm ảnh, đội có logo), giờ + sân, ô điểm từng set, nút Lưu và nút "Vào trang Live".

## Out of scope

- Không đổi Backend, không đổi Web.
- Không đổi luật tính điểm của Backend; popup chỉ gửi qua `updateScoreDetails` có sẵn.
- Không đổi sơ đồ nhánh ở tab "Sơ đồ"; tab "Đang diễn ra" của người xem vẫn chỉ đọc, chỉ dùng chung màu và gập.
- Hộp "Đang đấu" (đỏ) giữ nguyên chức năng, chỉ thêm khả năng gập.

## Capabilities

### New Capabilities
- `results-board-branches`: bảng trận phân nhánh, gập mở, tới vòng, hàng trận đủ cột, popup nhập điểm.

### Modified Capabilities
(không có)

## Impact

- `lib/features/tournament/utils/results_rounds.dart`, `lib/features/tournament/widgets/results_board_palette.dart`, `results_match_board.dart`, `results_match_row.dart`, file mới `results_score_dialog.dart`.
- `lib/l10n/app_vi.arb`, `app_en.arb` và file sinh `app_localizations*.dart`.
- Test: `results_rounds_test.dart`, `results_match_board_test.dart`, `results_match_board_open_speed_test.dart`, thêm test hàng và popup.
- Callers của `ResultsMatchBoard`: `live_tab.dart`, `tournament_management_hub_screen.dart` (không đổi chữ ký).
