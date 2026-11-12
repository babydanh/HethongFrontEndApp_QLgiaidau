# Findings (nghi bug, KHÔNG sửa production; test tương ứng đã bỏ qua)

## F1. `getPendingPosts` / `getReports` bỏ rơi danh sách trần
- File: `lib/data/repositories/api/api_community_social_repository.dart:184-186` (`getPendingPosts`), `:203-205` (`getReports`).
- Quan sát: `payload = _asMap(response.data)` biến một `List` thành map rỗng; dòng sau `raw = payload['data'] ?? payload` khi đó là map rỗng, `raw is! List` → trả `[]`. Nhánh `?? payload` có vẻ để chấp nhận body không bọc, nhưng với list trần thì luôn trả rỗng (so với `_getReactionGroups` ở `:325-338` có xử lý `response.data is List`).
- Vì sao nghi sai: không đối xứng với `_getReactionGroups`; nếu backend/proxy trả list trần, hàng chờ duyệt/báo cáo sẽ im lặng rỗng. Hiện backend bọc `{data: [...]}` nên chưa lộ.
- Test: không khẳng định hành vi này; test chỉ phủ dạng `{data: [...]}`.

## F2. `generatingStrategy: null` trong `copyWith` không xoá được giá trị cũ
- File: `lib/providers/lite_management_notifier.dart:1071` (`state.copyWith(generating: false, generatingStrategy: null)`), `copyWith` ở `:243` và `:211`.
- Quan sát: `copyWith` dùng `generatingStrategy ?? this.generatingStrategy`, nên truyền `null` giữ nguyên chiến lược cũ ('SKILL'/'RANDOM'...) sau khi sinh cặp xong.
- Vì sao nghi sai: dòng gọi rõ ràng muốn xoá. Hiện vô hại vì UI (`lite_management_screen.dart:2929,2964`) luôn kiểm `state.generating &&` trước, nhưng một chỗ dùng mới chỉ đọc `generatingStrategy` sẽ thấy giá trị cũ.
- Test: không khẳng định `generatingStrategy` sau khi xong.

## F3. Bộ kiểm tra set từ chối tỉ số chạm trần hợp lệ (30-29 cầu lông)
- File: `lib/domain/services/score_validator.dart:73-87` (`validateRallyPointSet`, nhánh `config.mustWinByTwo`), dùng ở `lib/features/match/notifiers/score_panel_notifier.dart:1538` (`_validateSetBeforeFinish`).
- Quan sát: với cấu hình cầu lông mặc định (đến 21, thắng cách 2, `maxPoints` 30, `tiebreakAt` 20), set kết thúc 30-29 bị `deuceMargin` vì `minScore >= tiebreakAt` đòi `diff == 2`. Trong khi `isSetComplete` (cùng file) coi `maxScore >= maxPoints` là set đã xong (true cho 30-29). Tương tự cấu hình pickleball rally mặc định (`maxPoints` 15): 15-14.
- Vì sao nghi sai: luật cầu lông cho phép 30-29 (điểm vàng ở cap). Hai hàm trong cùng file mâu thuẫn nhau; BTC/trọng tài chỉ kết thúc được set này bằng chế độ ghi đè.
- Test: `test/domain/score_validator_validation_test.dart` không khẳng định 30-29/15-14 bị từ chối; chỉ khẳng định `isSetComplete(30,29)` là true (hành vi riêng của hàm đó) và các nhánh còn lại.
