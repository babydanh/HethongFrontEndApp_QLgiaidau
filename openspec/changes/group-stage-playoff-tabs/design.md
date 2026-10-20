# Design

## Context

Xem động lực trong `proposal.md` và hợp đồng trong `specs/tournament-group-playoff-view/spec.md`. Màn chi tiết đã truyền `divisionId` và `bracketType` tới bộ tải sơ đồ. Widget sơ đồ nhận toàn bộ trận, nhận diện thể thức vòng bảng + loại trực tiếp, rồi hiện riêng sơ đồ knockout. Widget `StandingsView` và provider bảng xếp hạng theo giải/nội dung đã tồn tại; hiện chưa được gắn vào nội dung Bảng đấu.

## Goals / Non-Goals

**Goals:**
- Kết hợp bảng xếp hạng và sơ đồ playoff trong cùng nội dung của hạng mục.
- Tái sử dụng nguồn dữ liệu, trạng thái rỗng/lỗi và giao diện hiện có.
- Giữ cách phân loại thể thức nhất quán với sơ đồ công khai.

**Non-Goals:**
- Thay đổi API, cách tạo trận, quy tắc tính điểm hoặc cách xác định đội đi tiếp.
- Thay đổi tab Bảng đấu cấp giải hay giao diện Web.

## Decisions

- Thêm hai tab bên trong widget sơ đồ công khai, không thay đổi cấu trúc tab cấp giải hoặc danh sách hạng mục. Chỉ thể thức vòng bảng + knockout dùng hai tab; loại khác tiếp tục dùng cách hiển thị hiện tại.
- Tab Bảng dùng `StandingsView` với `tournamentId`, `divisionId` và danh sách trận của nội dung hiện tại. Tab Playoff dùng nhánh knockout đã lọc bởi logic sơ đồ hiện có. Cách này tránh thêm API hoặc tải lại danh sách trận riêng cho từng tab.
- Ưu tiên thể thức cụ thể của hạng mục hơn thể thức chung của giải khi xác định hai tab và tính đội đi tiếp. Nếu thể thức hạng mục không có, nhận diện kết hợp từ dữ liệu có đủ trận vòng bảng và knockout. Khi metadata đã xác nhận vòng bảng + playoff, vẫn dựng hai tab trước khi có trận; khi thiếu cả metadata lẫn dữ liệu trận, giữ trạng thái rỗng hiện có.
- Trạng thái chọn tab là cục bộ trong nội dung hạng mục, khởi tạo ở Bảng; đổi hạng mục tạo nội dung mới và trở về Bảng.
- Dùng khóa dịch hiện có cho nhãn nếu đúng nghĩa; nếu chưa có, thêm cặp khóa cùng tên vào `app_vi.arb` và `app_en.arb` rồi chạy `flutter gen-l10n`.
- Kiểm thử chuyển tab, mặc định Bảng, chỉ hiện trận knockout ở Playoff, dữ liệu rỗng và giữ nguyên hành vi thể thức đơn.

## Risks / Trade-offs

- Bảng xếp hạng có thể chưa có dữ liệu trong khi playoff đã có trận → giữ trạng thái rỗng/lỗi sẵn có của từng tab; không khóa tab còn lại.
- Bảng xếp hạng có nội dung cuộn trong màn chi tiết → giữ cách cuộn hiện tại của trang cha và cấu hình danh sách bảng xếp hạng không cuộn độc lập.
- Thể thức hạng mục có thể khác thể thức cấp giải → dùng `bracketType` của hạng mục khi có, tránh hiện sai số đội đi tiếp.

## Migration Plan

Không cần migration dữ liệu hoặc thay đổi Backend. Có thể hoàn tác bằng cách bỏ hai tab con và trả widget sơ đồ công khai về cách dựng nội dung hiện tại.
