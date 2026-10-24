# Design

## Context

Xem `proposal.md` và `specs/schedule-grid-match-cards/spec.md`. `TournamentDivision` đã có metadata loại trận/giới tính; màn giải có thể truyền các division này xuống lưới. Thẻ đang nhận tên hạng mục riêng và lưu trữ lịch sử điểm/trạng thái trận.

## Goals / Non-Goals

**Goals:** Phân màu từ metadata có cấu trúc, giữ tên và điểm tách bạch ở độ rộng điện thoại, không đổi ý nghĩa trạng thái.

**Non-Goals:** Không sửa API, mô hình dữ liệu, quy tắc ghi điểm, bố cục lưới hoặc màn kết quả.

## Decisions

- Ánh xạ `matchType` và `genderRestriction` của division theo ID; `DOUBLES` + `MALE` xanh theme `info`, `DOUBLES` + `FEMALE` hồng `#DB2777`. Tên hiển thị chỉ là nhãn, không phải nguồn phân loại; thiếu/không khớp metadata thì giữ bảng màu dự phòng. Cách này ổn định khi tên hoặc thứ tự đổi.
- Trong hàng đầy đủ, tên đội nhận phần chiều rộng còn lại, tối đa hai dòng và ellipsis; các ô điểm giữ độ rộng riêng, căn phải. Không dùng cuộn ngang trong thẻ vì sẽ che điểm hoặc làm thao tác đọc kém rõ.
- Không suy ra trận hoàn tất từ việc có điểm. Chỉ cờ hoàn tất hiện có được quyết định cách nhấn mạnh đội thắng; điểm trực tiếp có thể còn hiển thị trong lúc trận đang diễn ra.

## Risks / Trade-offs

- Tên dài hơn hai dòng vẫn bị rút gọn; giới hạn này giữ chiều cao thẻ và vị trí điểm ổn định.
- Màu hồng là token màu cố định để phân biệt giới tính, không phải màu trạng thái; chip vẫn dùng nền cùng màu với độ mờ thấp.
