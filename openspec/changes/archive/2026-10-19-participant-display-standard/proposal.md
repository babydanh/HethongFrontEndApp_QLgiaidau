## Why

Nhãn đội/VĐV trong App hiện không thống nhất và có nhiều chỗ tự bịa tên:

- Thẻ trận live (`live_match_card_v2.dart`) ghép họ/tên cuối của hai VĐV thành `A / B` và ghi đè cả tên đội thật.
- Thẻ đội giải (`tournament_team_card.dart`) tách `team.name` theo ` - `, ` / `, ` & ` để đoán VĐV.
- Parser đội (`api_team_repository.dart`) tự tạo nhãn "Đội {id}" và "VĐV" khi thiếu tên.
- Overlay và lịch dùng hai bộ rút gọn tên khác nhau (`shortTeamName`, `scheduleShortTeamName`).
- Bảng xếp hạng gom nhóm theo tên hiển thị thay vì ID.
- Excel, kết quả, roster, bracket mỗi nơi tự quyết định cách hiện.

Quy chuẩn chung được chốt với người dùng (`team-label-contract.md`, đồng bộ Web và Backend): hiện tên đội khi có tên thật, không trùng tên VĐV; ngược lại hiện từng VĐV kèm avatar; chỗ hẹp viết tắt tên người theo `N. T. M. Khai`; chỗ rộng hiện đầy đủ.

## What Changes

- Thêm `lib/core/participants/participant_display.dart` là nguồn duy nhất cho nhãn đội/VĐV: `ParticipantPlayer`, `toParticipantPlayers` (ưu tiên `players[]`, dự phòng `members`/`guestNames`), `resolveParticipantDisplay` (TEAM/PLAYERS), `abbreviateName`, `participantLabel` (chuỗi, chỉ để hiển thị) và widget `ParticipantLabel` (`compact` cho chỗ hẹp, Tooltip hiện tên đầy đủ).
- Thay mọi nhãn đội/VĐV trong App bằng helper trên: thẻ trận live, bracket, double-elim, bảng vòng tròn, lịch sân (công khai và BTC đều viết tắt theo contract §3), overlay, điều khiển tỉ số, bảng xếp hạng, kết quả, thẻ đội giải, roster, Excel.
- Xoá hai bộ rút gọn cũ (`overlay_team_name.dart`, `schedule_team_label.dart`) và logic tách tên theo ký tự phân cách.
- Bỏ nhãn fabricate: "Đội {id}", "VĐV", "Chưa đặt tên", và nhãn ghép `A / B` khi import roster. Đội không tên giữ `null`/rỗng và hiện VĐV.
- Nhóm bảng xếp hạng, nhận diện cặp, gán sự kiện theo ID, không theo chuỗi hiển thị.
- Đăng ký và thêm VĐV: không gửi tên người vào `teamName`; để trống thì bỏ field.
- Model `Team`, `Standing`, `OrganizerOpsParticipant` (`lib/domain/entities/organizer_ops.dart`), `PaymentModel` đọc `teamName` nullable và đọc `players`.

## Out of scope

- Không migrate hay sửa dữ liệu cũ; giá trị `teamName` đang có giữ nguyên.
- Không đổi Backend (endpoint, DB). Backend là bên thêm `players[]` và cho phép `team_name = NULL`; App chỉ tiêu thụ.
- Không đổi luồng bóng đá (tên đội bóng luôn là TEAM).
- Không thêm package (chuẩn hoá NFC chưa có thư viện trong `pubspec.yaml`; so khớp dùng trim, gộp khoảng trắng, không phân biệt hoa thường).
- Không chạy integration test, `flutter analyze` toàn repo, hoặc build release.
- Không đổi animation, theme, hay token màu.
- PDF: không có exporter trong `lib/` đã xác nhận, không thay đổi.

## Repo khác bị ảnh hưởng

- Backend (`HethongBackendApi_QuanlyGiaiDau`): thêm field `players: ParticipantPlayer[]` cho các endpoint participant, và `team_name` nullable. Danh sách endpoint do Backend ghi vào mục 6 của `team-label-contract.md`. App đọc `players` nếu có, không có thì dựng từ `members`/`guestNames`.
- Web (`HethongFrontEndWeb_QLgiaidau`): cùng quy tắc hiển thị qua change `participant-display-standard` riêng.
