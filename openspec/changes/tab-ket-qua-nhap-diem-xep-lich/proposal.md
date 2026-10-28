# Proposal

## Why

Web đã có tab **Kết quả** cho Ban tổ chức (chọn vòng, danh sách trận Đã xong / Sắp tới, bấm hàng để nhập điểm) và nút **Xếp lịch** trên thẻ Bracket. App chỉ có tab Kết quả hiển thị danh sách trao thưởng (chỉ hiện khi đã có trận hoàn tất) và thẻ Bracket chỉ có thể nhập điểm, không đặt được sân/giờ cho một trận. Ban tổ chức dùng App ngoài sân phải quay lại Web để nhập điểm và xếp lịch.

## What Changes

- Tab **Kết quả** của App có thêm bảng trận theo vòng giống Web: bộ chọn vòng (nhãn kèm số trận chờ nhập), hai nhóm **Đã xong** và **Sắp tới**; Ban tổ chức bấm một hàng chờ nhập điểm để mở màn nhập điểm; người khác chỉ xem. Danh sách trao thưởng hiện có được giữ nguyên.
- Ban tổ chức luôn thấy tab Kết quả (Web luôn có tab); người xem thường vẫn chỉ thấy khi giải đã có kết quả.
- Hàm thuần port từ `results.ts` của Web (`canEnterScore`, gom vòng, tách Đã xong / Sắp tới, vòng mặc định) kèm test, để App và Web cùng một luật.
- Thẻ Bracket (và hàng bảng trận) có nút **Xếp lịch** cho Ban tổ chức, mở hộp chọn sân + giờ cho MỘT trận, gọi `PATCH /matches/:id/schedule` (đã có `MatchRepository.updateSchedule`); chặn bấm đúp, báo lỗi mạng, làm mới dữ liệu sau khi lưu.
- Tab Lịch thi đấu và Bracket nhập điểm qua cùng `MatchScoreEntryChooser` với cùng điều kiện `canEnterScore`.
- Khối **Đang diễn ra** ở đầu tab Kết quả và tab Đang diễn ra dùng card gọn mới: chấm đỏ, nhãn lượt, mã trận, hai đội, tỉ số ván + điểm từng ván, giờ · sân; không còn chữ "TRỰC TIẾP", "Vào phòng Live", nhãn nhánh. Ban tổ chức có thêm đúng một nút bút nhập điểm. Mỗi trận live chỉ hiện một chỗ, số đếm lấy từ cùng danh sách.
- Chuỗi mới ở `app_vi.arb` + `app_en.arb`.

## Out of scope

- Không đổi Backend, không đổi API, không thêm endpoint (dùng `GET /tournaments/:id/results`, `GET` danh sách trận hiện có, `PATCH /matches/:id/schedule`).
- Không làm lưới lịch kéo thả (thuộc `lich-logic-nhu-web`), không đổi bố cục khay giữ chỗ / thanh tìm kiếm Bracket (thuộc nhánh `bang-dau-gon-search-so-do`).
- Không đổi luật tính điểm, không xử lý tranh chấp (DISPUTED) hay huỷ trận ở App.
- Không thêm package.

## Capabilities

### New Capabilities
- `live-match-summary-card`: card trận đang diễn ra gọn, nút nhập điểm cho Ban tổ chức, quy tắc một trận một chỗ.
- `results-match-board`: bảng trận theo vòng trong tab Kết quả (Đã xong / Sắp tới, vòng mặc định, quyền nhập điểm theo Ban tổ chức).
- `bracket-match-actions`: nhập điểm và xếp lịch (sân + giờ) một trận từ thẻ Bracket, tab Lịch thi đấu và tab Kết quả.

### Modified Capabilities
(không có; `tournament-results` giữ nguyên, danh sách trao thưởng vẫn nằm ngay dưới bộ chọn hạng mục)

## Impact

- Code App: `lib/features/tournament/widgets/results_tab.dart`, `lib/features/tournament/screens/tournament_intro_screen.dart` (điều kiện hiện tab, truyền quyền), `lib/features/tournament/widgets/live_tab.dart`, file mới `lib/features/tournament/utils/results_rounds.dart`, `lib/features/tournament/widgets/live_match_summary_card.dart`, `lib/features/tournament/widgets/results_match_board.dart`, `lib/features/bracket/widgets/match_schedule_dialog.dart`, `bracket_match_card.dart`, `match_table_row.dart`, `lib/l10n/app_vi.arb`, `app_en.arb`.
- Repo khác: Web chỉ để đối chiếu (`src/features/organizer/operations/results.ts`, `ResultsBoard.tsx`, `useManageState.ts`); Backend không đổi (`PATCH /matches/:id/schedule` đã có).
- Xung đột tiềm tàng với `bang-dau-gon-search-so-do` và `ma-tran` ở `bracket_view_screen.dart`, `match_table_row.dart`, 2 file ARB: nhánh này rebase sau khi hai nhánh kia lên `main`.
