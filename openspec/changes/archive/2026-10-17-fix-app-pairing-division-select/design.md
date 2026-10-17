## Thiết kế

- **Nguồn nội dung**: `LitePairingScreen` tự gọi `GET /tournaments/:id` (không dùng notifier của màn quản lý). Màn giữ `_divisions` đã qua `usableTournamentDivisions`, `_tournamentMatchType`, và `_selectedDivisionId`.
- **Ghi có điều kiện**: `_writeDivisionId` lấy nội dung đang chọn, hoặc nội dung duy nhất. Không có nhánh nào lấy nội dung đầu tiên khi giải có nhiều nội dung.
- **Hỏi chọn trước khi ghi**: `_ensureDivisionChosen()` chạy đầu ghép ngẫu nhiên và tạo sơ đồ, trước dialog xác nhận. BTC huỷ thì trả false và không gọi API.
- **Loại thi đấu**: `_effectiveMatchType` theo nội dung đang chọn (hoặc nội dung duy nhất). Giải nhiều nội dung chưa chọn trả null, không suy đoán từ nội dung đầu như `_canonicalMatchType` cũ.
- **Lọc danh sách**: `_inSelectedDivision(p)` so `tournamentDivisionId` với nội dung đang chọn khi giải có từ hai nội dung. Danh sách chờ và danh sách đơn dùng hàm này.
- **Ghép tay**: body vẫn `{participant1Id, participant2Id, teamName}`; `PairLiteParticipantsDto` không có `divisionId`.
- **Dùng chung**: `usableTournamentDivisions` (`core/utils/tournament_division_id.dart`) và `showLiteDivisionPicker` (`features/lite/widgets/lite_division_picker.dart`) được cả màn quản lý và màn ghép cặp gọi.
- **Không đổi**: `updateMaxParticipants` vẫn PATCH nội dung đầu tiên và nuốt lỗi (ghi nhận ở rủi ro, cần quyết định riêng).
