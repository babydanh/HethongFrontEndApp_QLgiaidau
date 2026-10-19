# Design

## Context

`TournamentIntroScreen` đã hiển thị `DivisionAccordion` khi giải có nhiều hạng mục; thao tác chọn cập nhật ID và tên hạng mục, rồi `ResultsTab` tải kết quả theo ID qua `tournamentResultProvider`. `TournamentDivision` chứa `matchType`. `ResultsTab` hiện chia thứ hạng thành các nhóm huy chương để vẽ bục và danh sách; thẻ danh sách đã hiện `participant.teamName` và gọi `_buildPodiumAvatar`, hàm này đọc `participant.members`, `fullName` và `avatarUrl`.

## Goals / Non-Goals

**Goals:**
- Giữ nguyên bộ chọn hạng mục và nguồn dữ liệu; danh sách xếp hạng là nội dung kết quả chính, không có bục riêng.
- Hiển thị tên đội cùng tên thành viên và avatar phù hợp với `matchType` đang chọn.
- Giảm độ bão hòa, đổ bóng và viền màu nổi bật, vẫn giữ phân biệt thứ hạng bằng nhãn và số hạng.

**Non-Goals:**
- Không đổi API, provider polling, luật xếp hạng, cấu trúc navigation, màn Web hoặc bộ chọn hạng mục.
- Không thêm dependency hay chuỗi hiển thị mới nếu có thể dùng nhãn và dữ liệu hiện có.

## Decisions

- Dùng `DivisionAccordion` hiện có làm nguồn chọn duy nhất; ở `TournamentIntroScreen`, tìm `TournamentDivision` đang chọn theo ID và truyền `matchType` thực vào `ResultsTab`. Không diễn giải loại hạng mục từ `selectedDivision` (tên hiển thị).
- Trong `ResultsTab`, bỏ phần dựng bục và giữ luồng xếp thứ hạng/list hiện có. Thẻ giữ `teamName` làm tiêu đề; dòng thông tin thành viên trình bày `fullName` theo loại hơn mục. Tận dụng avatar thành viên hiện có, một avatar cho đơn và hai avatar cho đôi; avatar thiếu hoặc lỗi dùng chữ cái đầu tên.
- Dùng token màu của theme cho nền, chữ, đường viền và điểm nhấn thứ hạng; tránh gradient và màu huy chương bão hòa. Không đổi thứ tự giải thưởng hay trạng thái rỗng.
- Thêm kiểm thử widget cho chọn đúng hạng mục, trường hợp đơn/đôi, thẻ đội có avatar, thiếu ảnh và trạng thái không có giải thưởng; dữ liệu test dùng cùng dạng participant hiện đang đọc.

## Risks / Trade-offs

- Dữ liệu kết quả cũ có thể thiếu `members` hoặc tên thành viên. Khi đó giữ tên đội và chỉ hiện thành viên/avatar có dữ liệu; không suy đoán tên hoặc loại nội dung.
- Hiển thị tên thành viên có thể làm thẻ cao hơn trên màn hình nhỏ; giới hạn số dòng và cắt gọn tên dài, giữ toàn bộ thẻ nằm trong cuộn dọc.
