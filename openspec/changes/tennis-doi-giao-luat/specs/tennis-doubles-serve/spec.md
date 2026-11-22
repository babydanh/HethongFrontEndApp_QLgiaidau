## ADDED Requirements

### Requirement: Giao/nhận tennis đôi theo set
Sân vợt tennis đôi trong App SHALL tính đội giao luân phiên mỗi game, người giao theo lựa chọn của từng đội trong set hiện tại, và người đỡ ô phải mặc định là người đứng ô phải; mỗi đội đổi được lựa chọn tới trước lượt giao/nhận đầu tiên của đội trong set, sau đó chỉ sửa sai (Luật 27c cho người giao tới hết set, 27e cho người nhận chỉ trong game).

#### Scenario: Chọn người giao xong người nhận tự hiện
- **WHEN** trọng tài chạm VĐV đội A ở đầu trận để chọn người giao
- **THEN** ô người đó hiện thẻ GIAO, người đứng ô phải đội B hiện NHẬN, nút + dùng được ngay

#### Scenario: Set mới chọn lại người giao
- **WHEN** set 1 kết thúc
- **THEN** dòng nhắc chọn người giao hiện lại và lựa chọn của set 1 không áp cho set 2

#### Scenario: Đội đã khoá chỉ còn sửa sai
- **WHEN** đội nhận đã nhận điểm đầu tiên của set và trọng tài chạm ô đội đó
- **THEN** menu có "Sửa sai: đổi người nhận trong game này" thay cho "Đổi chỗ phải/trái"; game nhận sau vị trí trở về như cũ

### Requirement: No-Ad chọn người đỡ điểm quyết định
Khi luật No-Ad và điểm 40-40, App SHALL cho đôi nhận chọn người đỡ điểm quyết định và người giao giao sang ô của người đó.

#### Scenario: Chọn người đỡ điểm quyết định
- **WHEN** 40-40 có No-Ad và trọng tài chọn "Người này đỡ điểm quyết định" ở một VĐV đội nhận
- **THEN** người đó hiện NHẬN và thẻ GIAO chuyển sang ô chéo với người đó

#### Scenario: Luật Advantage
- **WHEN** 40-40 khi luật có Advantage
- **THEN** menu không có mục chọn người đỡ điểm quyết định

### Requirement: Lưu trạng thái giao/nhận lên server
App SHALL lưu `TennisCourtState` qua `PATCH /api/v1/matches/:id/court-state` sau mỗi thao tác đổi lựa chọn và khôi phục từ `scoreDetails['courtState']` khi mở lại bảng chấm.

#### Scenario: Mở lại giữ người giao
- **WHEN** trọng tài chọn người giao, đóng rồi mở lại bảng chấm
- **THEN** sân hiện đúng người giao và người nhận đã chọn

#### Scenario: Lưu thất bại
- **WHEN** API court-state lỗi (mạng rớt hoặc 400)
- **THEN** sân giữ lựa chọn trên máy, báo lỗi một lần, thử lưu lại ở thao tác sau, không chặn ghi điểm

### Requirement: Chuỗi hiển thị hai ngôn ngữ
Mọi chuỗi mới MUST có key cùng tên ở `lib/l10n/app_vi.arb` và `lib/l10n/app_en.arb`.

#### Scenario: Máy để tiếng Anh
- **WHEN** App chạy locale `en`
- **THEN** menu và dòng nhắc hiện tiếng Anh

#### Scenario: Thiếu key
- **WHEN** chạy `flutter gen-l10n` khi một key chỉ có ở một file
- **THEN** gen-l10n báo key thiếu (untranslated) và task chưa được đánh dấu xong
