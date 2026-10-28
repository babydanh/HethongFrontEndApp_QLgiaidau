# Design

## Context

Xem `proposal.md` (Why / What Changes). Hiện trạng cần biết để chọn cách làm:

- `ResultsTab` (`lib/features/tournament/widgets/results_tab.dart`) là `ConsumerWidget`, chỉ đọc `tournamentResultProvider` (poll `GET /tournaments/:id/results` mỗi 15 s, giữ snapshot cuối khi lỗi) và vẽ danh sách trao thưởng. Khi chưa có `awards` nó trả về trạng thái rỗng toàn màn hình.
- `tournament_intro_screen.dart` quyết định tab Kết quả có hiện hay không theo `hasResults`; biến `canManage` (chủ giải / đồng tổ chức) đã có sẵn ở màn này, tính qua `canManageTournament(...)` (`lib/domain/services/tournament_manage_access.dart`).
- Danh sách trận đã có provider: `matchesProvider(id)` và `liteBracketMatchesProvider(id)` (`lib/providers/query_providers.dart`, chọn theo `tournament.isLite`). `MatchModel` (`lib/domain/entities/match.dart`) có `round`, `matchNumber`, `team1Id/2Id`, `status`, `scheduledTime`, `completedAt`, `divisionId`, `isBye`.
- Nhãn vòng đã có `MatchRoundLabel.formatRound(match:, allMatches:, tournament:, l10n:)` (`lib/core/utils/match_round_label.dart`), cần truyền toàn bộ trận (kể cả BYE) để đếm vòng đúng.
- Nhập điểm đã có `MatchScoreEntryChooser.show(context, {match, tournamentId})` (hộp Huỷ / Xem live / Nhập điểm), dùng ở tab Bracket.
- Xếp lịch API đã có: `MatchRepository.updateSchedule(tournamentId, matchId, {courtName, courtAddress, courtId, scheduledAt, durationMinutes, clear})` → `PATCH /matches/:id/schedule`; khoá bằng `isScheduleLocked(match)` (`schedule_actions.dart`: LIVE hoặc đã xong).
- Luật đối chiếu ở Web: `src/features/organizer/operations/results.ts` (`canEnterScore`, `buildResultsRounds`, `splitResultsMatches`, `splitUpcomingByTime`, `defaultResultsRoundKey`).

## Goals / Non-Goals

**Goals:**
- Một nguồn luật thuần (không phụ thuộc Flutter/Riverpod) cho "trận chờ nhập điểm", gom vòng, tách Đã xong / Sắp tới, vòng mặc định; test được bằng `flutter test` nhẹ.
- Tab Kết quả, tab Lịch và tab Bracket dùng chung một điều kiện `canEnterScore` và một cách mở nhập điểm.
- Hộp xếp lịch một trận không phụ thuộc màn hình gọi nó (Bracket, bảng trận Kết quả đều mở được).

**Non-Goals:**
- Không tạo provider mới cho trận, không thêm tầng repository mới (dùng cái có sẵn).
- Không đụng lưới lịch kéo thả và khay Bracket (nhánh khác sở hữu).
- Không thêm package, không đổi hợp đồng API.

## Decisions

### D1. Hàm thuần port từ Web vào `lib/features/tournament/utils/results_rounds.dart`
Các hàm: `canEnterScore(MatchModel)`, `buildResultsRounds(...)`, `splitResultsMatches(...)`, `splitUpcomingByTime(...)`, `defaultResultsRoundKey(...)`. Nhận danh sách `MatchModel` và một hàm nhãn vòng (inject), trả về record/class bất biến. Lý do: cùng luật với Web, test không cần widget. Nhãn vòng được truyền vào dạng callback để file này không import l10n; widget gọi `MatchRoundLabel.formatRound` trên toàn bộ trận (kể cả BYE) rồi mới lọc BYE khỏi bảng.

Thay thế đã loại: tính thẳng trong `build()` của widget (khó test, dễ lệch Web).

### D2. Bảng trận là widget riêng `results_match_board.dart`, `ResultsTab` chỉ ghép
`ResultsTab` thêm tham số `canManage` và bọc nội dung trong một `SingleChildScrollView` duy nhất: bảng trận (nếu có trận hoặc là BTC) phía trên, danh sách trao thưởng phía dưới. Trạng thái "chưa có kết quả chính thức" chỉ thay phần trao thưởng, không che bảng trận. Lý do: spec yêu cầu hai phần độc lập. Giữ `_buildAwardCard` và các hàm avatar nguyên văn, không dọn.

Nguồn trận: `ref.watch` provider tuỳ `tournament.isLite`, lọc `divisionId` của hạng mục đang chọn (không có hạng mục thì lấy hết). Khi provider lỗi sau khi đã có dữ liệu thì dùng `valueOrNull` để giữ dữ liệu cũ, không hiện lỗi trống.

### D3. Vòng đang chọn lưu trong State cục bộ, không lưu provider
`ConsumerStatefulWidget` giữ `String? _roundKey`; mỗi lần build kiểm tra key còn tồn tại trong danh sách vòng, nếu không thì rơi về `defaultResultsRoundKey`. Lý do: trạng thái chọn chỉ có nghĩa trong tab này, và đổi hạng mục đã tạo `ResultsTab` mới (`ValueKey('results-$_selectedDivisionId')`).

### D4. Quyền BTC = tham số `canManage` truyền từ `tournament_intro_screen.dart`
Không tự suy ra `role == admin`. Điều kiện hiện tab: `hasResults || canManage`. Lý do: spec `live-score-access` loại ADMIN không phải BTC; `bracket_view_screen.dart` (`canScoreMatch = admin || canEditBracket || isReferee`) giữ nguyên, chỉ thêm dùng chung `canEnterScore` cho điều kiện trận.

### D5. Hộp xếp lịch một trận mới: `match_schedule_dialog.dart`
Hộp riêng, nhận `{tournamentId, match}`, chọn sân (danh sách sân hiện có nếu repo cung cấp; nhập tên tay nếu không), ngày giờ, thời lượng từ `scheduleDurationOptions`, nút Lưu và "Bỏ lịch". Gọi `matchRepository.updateSchedule`. Trạng thái `_saving` chặn bấm đúp; lỗi bắt bằng `on DioException` cụ thể và hiện thông báo qua l10n (không đưa `e.toString()` ra UI); sau `await` kiểm `mounted`. Thành công thì `Navigator.pop(true)`, bên gọi invalidate provider trận.

Thay thế đã loại: tái dùng `MultiMatchScheduleSheet` (xếp nhiều trận nối tiếp, UX và payload khác, kéo theo phụ thuộc nhánh `lich-logic-nhu-web`).

### D6. Nút Xếp lịch và nhập điểm gắn vào thẻ có sẵn qua callback
`bracket_match_card.dart` và `match_table_row.dart` nhận thêm `onSchedule` (null khi không phải BTC hoặc trận khoá). Không để thẻ tự đọc provider/quyền. Lý do: thẻ đang là widget thuần hiển thị, giữ nguyên để nhánh `bang-dau-gon-search-so-do` rebase dễ.

### D7. Làm mới dữ liệu
Sau lưu lịch hoặc quay lại từ nhập điểm: `ref.invalidate` các provider trận của giải (cả `matchesProvider` và `liteBracketMatchesProvider`) và `tournamentResultProvider`. Dùng đúng tập provider mà `_refreshBracketAfterEdit` đang invalidate, không thêm tập mới.

### D8. Chuỗi hiển thị
Mọi chuỗi mới (tiêu đề bảng, "Đã xong", "Sắp tới", nhãn "chờ nhập", "Xếp lịch", lỗi lưu lịch…) vào `app_vi.arb` + `app_en.arb`, rồi `flutter gen-l10n`. Hai file ARB và `tournament_intro_screen.dart` chỉ một task sở hữu (xem `tasks.md`).

## Risks / Trade-offs

- [Xung đột rebase với `bang-dau-gon-search-so-do` và `ma-tran` ở `bracket_view_screen.dart`, `match_table_row.dart`, 2 ARB] → sửa tối thiểu các file đó (chỉ thêm tham số/callback), rebase sau khi hai nhánh kia lên `main`.
- [Nhãn vòng sai vì thiếu trận BYE trong danh sách] → luôn tính nhãn trên toàn bộ trận rồi mới lọc BYE khỏi bảng; có test.
- [Hai luồng nhập điểm lệch điều kiện] → `canEnterScore` là nguồn duy nhất, test bảng trạng thái.
- [Poll 15 s của kết quả và provider trận không đồng bộ] → bảng trận không phụ thuộc poll; chấp nhận độ trễ ngắn, invalidate thủ công sau thao tác.
- [Đồng tổ chức ngoài trang đầu workspace có thể chưa có `canManage`] → rủi ro đã biết của `nut-quan-ly-theo-giai`, không xử lý ở change này.
- [Backend từ chối đổi lịch (409/422)] → hộp giữ nguyên dữ liệu nhập, báo lỗi dễ hiểu; không retry tự động.

### D9. Card trận đang diễn ra mới, không sửa `LiveMatchCardV2`
`LiveMatchCardV2` (912 dòng) còn dùng ở màn live, danh sách phiên CLB; sửa nó đổi giao diện 4 nơi ngoài phạm vi. Tạo `LiveMatchSummaryCard` riêng, tái dùng `ParticipantLabel(compact: true)` cho avatar + tên rút gọn, `MatchModel.currentLiveScore`/`scoreHistory` cho tỉ số, `TournamentLocationFormatter.matchShortCourt` cho sân. Mã trận là tham số tuỳ chọn `matchCode`: trường `MatchModel.matchCode` chỉ có ở nhánh `ma-tran` (chưa lên `main`), nên change này không phụ thuộc nó; sau khi `ma-tran` lên `main` thì nơi gọi truyền `matchCodeOrNull(match)`.

### D10. Một nguồn cho danh sách và số đếm trận live
`isLiveMatch` (trong `results_rounds.dart`) là điều kiện duy nhất; `LiveTab` và khối "Đang diễn ra" của bảng trận đều lọc bằng nó rồi đếm `length` của chính danh sách đó. Trận live bị loại khỏi nhóm "Sắp tới".
