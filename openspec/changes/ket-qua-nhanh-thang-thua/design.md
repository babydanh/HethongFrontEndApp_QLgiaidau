## Quyết định

1. **Nhánh suy ra ở App, không đổi model.** `BracketPosition.bracket` đã gộp `MAIN` và `WINNERS` thành `'winners'`. Nên `branchOfMatch` dùng: `losers` → thua; `grand_final*` → chung kết tổng; `winners` mà `stageType` là `DOUBLE_ELIMINATION` → thắng; còn lại → chính (loại trực tiếp). Giống `branchOf` của Web.
2. **Khoá vòng.** Nhánh thua dùng `losers|<roundNumber>` vì hai vòng thua có thể trùng nhãn và số trận. Các nhánh khác giữ khoá là nhãn như hiện nay (test cũ vẫn đúng).
3. **Mặc định mở vòng còn chờ điểm** (`defaultResultsRoundKey`), khác Web (Web mở hộp đầu). Lý do: BTC cần chỗ nhập điểm, hộp đầu thường đã xong hết. Muốn giống Web tuyệt đối thì đổi một dòng.
4. **Gập là trạng thái cục bộ của bảng** (`Map<String,bool> choice`), không lưu bền. `isRoundBoxOpen(choice:, isDefault:, searching:)` và `openOnlyRound(keys, picked)` là hàm thuần để test.
5. **Cuộn sau khi gập.** Gập đổi chiều cao các hộp phía trên, nên chờ hết hoạt ảnh (~220 ms) rồi mới `Scrollable.ensureVisible`; phần đầu hộp luôn được dựng nên `GlobalKey` còn hợp lệ.
6. **Popup nhập điểm dùng API có sẵn** `MatchRepository.updateScoreDetails(tournamentId, matchId, p1SetsWon, p2SetsWon, scoreDetails, winnerId)`. Không dùng `AdminEditScoreDialog` (cũ, không nơi nào gọi, chỉ một cặp số). Bên thắng tính từ số set thắng; hoà set thì khoá nút Lưu. Backend vẫn là nơi kiểm luật điểm; lỗi trả về hiện trong popup.
7. **Đơn/đôi/đội đã có sẵn** ở `ParticipantSideLines` (đôi hiện hai VĐV có ảnh, đội có logo). Không viết lại, chỉ thêm test khoá hành vi và dùng lại trong popup.
8. **Nhãn nhánh.** Nhãn vòng thắng/thua đã có tiền tố ("CK nhánh thắng", "Nhánh thua - Vòng n") từ `MatchRoundLabel`, nên không thêm key tiền tố mới; chỉ thêm biểu tượng và màu theo nhánh.

9. **Bỏ chip "Trễ giờ" / "Tranh chấp" nhưng giữ enum.** `ResultsBoardFilter.late/disputed` còn được `tournament_step_summary.dart` (popup tiến trình) dùng để mở bảng. Xoá enum sẽ hỏng popup đó, nên chỉ bỏ chip khỏi thanh lọc; nếu bộ lọc đó đang được đặt sẵn thì chip hiện ra ở trạng thái đã chọn để anh còn đổi được.
10. **Tranh chấp không còn màu riêng.** Trận tranh chấp là trận đã đóng nên dùng viền "xong"; `MatchTone` chỉ còn live, done, cancel, ready, wait.
11. **Nút "+" to.** Vòng tròn 32 dp, vùng bấm 44 dp, nằm giữa hai bên (căn giữa theo chiều dọc cột Kết quả), màu xanh dương của chip đang chọn; khi đã có điểm thì cột hiện điểm như cũ.

## Phương án đã loại

- Sửa `BracketPosition` để giữ `MAIN` riêng: chạm model dùng khắp nơi, rủi ro lớn hơn nhu cầu.
- Mở popup nhập điểm bằng chuyển trang: chậm, mất vị trí cuộn của bảng.
- Lưu trạng thái gập vào bộ nhớ máy: Web cũng không lưu, không cần thêm trạng thái bền.

## Rủi ro

- Popup nhập điểm là phần lớn nhất; nếu luật điểm theo thể thức phức tạp hơn "số set", chỉ giữ nút "Vào trang Live" và để popup cho change sau.
- Hộp "Đang đấu" dồn mọi vòng nên giữ màu đỏ riêng, không thuộc nhánh nào.
