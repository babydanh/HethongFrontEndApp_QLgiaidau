# Design

## Context

Xem `proposal.md` và hai delta spec. `TournamentDivision` hiện đọc `tournamentConfig` nhưng chưa giữ `roundConfig`; `Team` đã có `divisionId` và `isApproved`; `MatchModel` có trạng thái bắt đầu/kết quả và `isGroupStageMatch` nhận diện trận vòng bảng. Repository đã có `updateDivisionConfig` dùng đúng PATCH division config; repository giải đã có `generateBracket`. `BracketViewScreen` có division đang chọn và các tab vòng bảng; `AutoDrawScreen` hiện gửi `divisionId: null` với giải nhiều nội dung.

## Goals / Non-Goals

**Goals:**
- Một resolver thuần Dart, dùng chung khi dựng bảng và khi tạo payload; parse cấu hình null/sai dạng an toàn.
- Quản lý phân bảng trong route quản trị theo division, trước và sau khi sinh sơ đồ; thao tác được bằng kéo-thả hoặc menu.
- PATCH bảo toàn các khóa `roundConfig` hiện tại; chỉ reset sơ đồ khi có trận vòng bảng chưa đấu.
- Bốc thăm chỉ gửi division đơn hoặc division BTC đã chọn rõ.

**Non-Goals:**
- Không thay đổi Backend/Web, không thêm endpoint/dependency, không dùng endpoint đổi tên group để gán participant.
- Không sửa các thao tác kéo-thả slot knockout hoặc đổi thể thức giải.

## Decisions

1. **Giữ cấu hình thô và resolve tại domain.** Thêm `roundConfig` nullable vào `TournamentDivision`, đọc map từ JSON nhưng không đưa dữ liệu JSONB tùy ý vào `Tournament.toJson()` vốn có allow-list. Resolver đọc `groupsConfig` và `advancementConfig`, lọc participant hợp lệ theo division, dùng fallback `tournamentConfig` rồi mặc định `numGroups = 1`, `teamsAdvancing = 2`; `teamsPerGroup` thiếu thì là ceiling của số participant trên số nhóm. Cấu hình nhóm thiếu/sai dạng tạo nhóm rỗng, không làm mất participant khỏi “Chưa xếp”.

2. **Số nhóm và thay đổi phân công là phép biến đổi ổn định.** Lựa chọn hợp lệ là `1..floor(participantCount / 2)` cộng số đang cấu hình nếu ngoài khoảng. Khi tăng nhóm, thêm nhóm rỗng; khi giảm, giữ các nhóm đầu và chuyển participant từ nhóm bị bỏ vào “Chưa xếp”, không tự phân phối lại. Chèn vào target đặt participant trước target; menu đặt participant cuối nhóm đích.

3. **Màn mới nằm trong luồng quản trị bracket hiện có.** Route nhận `tournamentId` và `divisionId`; `BracketViewScreen` mở màn từ tab vòng bảng, kể cả state chưa có trận. Màn đọc tournament, roster và matches bằng provider hiện có. Bảng dùng cuộn ngang trên điện thoại 360px, nội dung cuộn dọc; drag gần mép gọi cuộn theo hướng tương ứng. `AnimatedContainer` chỉ chuyển màu target/feedback với `Curves.easeOutCubic`; khi khóa, drag targets và menu bị vô hiệu hóa. Lý do khóa luôn hiển thị.

4. **Lưu theo thứ tự PATCH rồi mới sinh lại.** Payload giữ nguyên `division.roundConfig`, merge `groupsConfig` với `numGroups`, `teamsPerGroup` và `groups[{name, participantIds}]`, kèm `isConfigOverride: true`. PATCH thất bại khôi phục bản nháp cũ; thành công thì invalidate tournament/division, bracket và match providers. Chỉ khi tồn tại trận vòng bảng và mọi trận còn chưa bắt đầu mới gọi `generateBracket` với division hiện tại và `allowReset: true`. Nếu bước sinh lại lỗi, cấu hình đã PATCH vẫn là sự thật phía server và không rollback bằng một PATCH thứ hai.

5. **Không đoán division trong AutoDraw.** Route truyền division hiện chọn nếu có. Khi giải có nhiều division mà route không có lựa chọn, màn bốc thăm yêu cầu BTC chọn; nút lưu không gọi API khi chưa chọn. Một division tiếp tục tự dùng ID đó.

6. **Giữ dữ liệu hiển thị và lỗi theo hợp đồng hiện tại.** Candidate là participant `COMPLETE` của đúng division. Lỗi Dio ưu tiên `response.data.message`, rồi `friendlyDioErrorMessage`. Đang lưu thì khóa nút và bỏ qua lần gọi lặp; lỗi PATCH đưa draft về cấu hình ban đầu.

## Risks / Trade-offs

- PATCH và sinh lại là hai yêu cầu riêng, không có transaction chung → nếu sinh lại lỗi, giữ cấu hình server đã lưu, hiện lỗi và invalidate lại dữ liệu để màn phản ánh trạng thái thật.
- Participant hoặc `roundConfig` từ API có thể thiếu/không đúng dạng → resolver lọc null, ID ngoài roster và ID trùng; các participant hợp lệ còn lại vẫn hiện ở “Chưa xếp”.
- Màn nhiều cột trên điện thoại nhỏ cần cuộn ngang → giữ mỗi bảng là một cột cuộn được và kiểm tra widget ở chiều rộng 360px, không ép co cột tới mức khó kéo.

## Migration Plan

Không có migration dữ liệu. Cấu hình division cũ vẫn đọc được; lần lưu đầu tiên ghi `groupsConfig` vào `roundConfig` hiện hữu. Rollback bằng cách khôi phục thay đổi App; dữ liệu đã lưu vẫn là định dạng Backend hiện dùng.
