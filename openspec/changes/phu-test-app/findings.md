# Findings (nghi bug, KHÔNG sửa production; test tương ứng đã bỏ qua)

## F1. `getPendingPosts` / `getReports` bỏ rơi danh sách trần
- File: `lib/data/repositories/api/api_community_social_repository.dart:184-186` (`getPendingPosts`), `:203-205` (`getReports`).
- Quan sát: `payload = _asMap(response.data)` biến một `List` thành map rỗng; dòng sau `raw = payload['data'] ?? payload` khi đó là map rỗng, `raw is! List` → trả `[]`. Nhánh `?? payload` có vẻ để chấp nhận body không bọc, nhưng với list trần thì luôn trả rỗng (so với `_getReactionGroups` ở `:325-338` có xử lý `response.data is List`).
- Vì sao nghi sai: không đối xứng với `_getReactionGroups`; nếu backend/proxy trả list trần, hàng chờ duyệt/báo cáo sẽ im lặng rỗng. Hiện backend bọc `{data: [...]}` nên chưa lộ.
- Test: không khẳng định hành vi này; test chỉ phủ dạng `{data: [...]}`.
