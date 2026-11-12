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

## F4. `validateToken` gán vai trò admin/referee chỉ từ tiền tố của mã nhập
- File: `lib/data/repositories/api/api_token_repository.dart:52-60`.
- Quan sát: với mã không có `ADM-`/`REF-`, nhánh `role == 'viewer'` vẫn đặt `admin` nếu `code.toUpperCase().startsWith('ADM')` (không cần dấu gạch) hoặc `referee` nếu bắt đầu bằng `REF`, hoặc khi `code == data['adminToken']`. Một mã mời hợp lệ ngẫu nhiên bắt đầu bằng "ADM"/"REF" (vd `ADMX42`) cho vai trò quản trị/trọng tài phía client.
- Vì sao nghi sai: vai trò suy từ chuỗi người dùng gõ, không từ phản hồi server; phần gán quyền trong UI có thể bật sai. Backend vẫn là chốt chặn ghi nên mức độ phụ thuộc vào việc UI dựa vào `role` này đến đâu (cần người xác nhận; không phải kết luận đã khai thác được).
- Test: chỉ khẳng định tiền tố có dấu gạch (`ADM-`, `REF-`) và mã thường → viewer; không khẳng định nhánh tiền tố không gạch.

## F5. `loginWithEmailPassword` & họ hàng nuốt thông báo lỗi riêng của mình
- File: `lib/data/repositories/api/api_auth_repository.dart:41-52` (và các hàm cùng khuôn: register, google, apple, facebook).
- Quan sát: khối `try` ném `Exception(authCredentialsMissingResponse)` khi thiếu token / status lạ, nhưng `catch (e)` ngay bên dưới bắt luôn chính nó và ném lại `Exception(ErrorParser.parse(e, networkConnectionFailed))`. `ErrorParser.parse` với `Exception` không phải Dio trả về `fallback` → người dùng thấy "lỗi kết nối mạng" thay vì "thiếu thông tin đăng nhập".
- Vì sao nghi sai: thông báo cụ thể được viết ra nhưng không bao giờ tới UI; chẩn đoán sai (mạng) khi thực tế server trả 200 thiếu token.
- Test: khẳng định chỉ rằng không có phiên nào được trả và có `Exception`; không khẳng định nội dung thông báo cho nhánh này.
