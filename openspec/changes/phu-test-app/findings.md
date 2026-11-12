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
