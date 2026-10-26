## Why

Kiểm kê ngày 2026-10-25 giữa Web (`src/app/organizer/**`, ~50 popup/luồng quản lý) và App (hub quản lý + Organizer Ops, ~61 popup/sheet) cho thấy App còn hụt nhiều chức năng thật của BTC: dialog hạng mục chỉ 4 trường trong khi Web có ~20 (ELO min/max, phí riêng, luật set/điểm/deuce/tiebreak, vòng bảng, preset theo môn); không có ghép cặp thủ công/tự động, wildcard, VĐV ảo, tách cặp; khai mạc/kết thúc không có checklist chi tiết như Web; lịch thiếu xếp nối tiếp nhiều trận, editor khung giờ sân, phát hiện VĐV trùng giờ, AI xếp lịch; khu camera/stream key bị chặn cố ý. Người dùng chốt 2026-10-25: đồng bộ MỌI nhóm chức năng quản lý giải cho khớp Web, popup làm lại theo chuẩn bottom sheet của App (chức năng 1-1, không copy bố cục desktop); Series (chuỗi giải) và tạo giải bằng AI để đợt sau.

## What Changes

- **Vòng đời & đăng ký**: prompt tự đề nghị đóng đăng ký khi hạng mục đủ chỗ; sheet khai mạc liệt kê từng hạng mục đang mở kèm tick đóng từng hạng mục (như `openingWarnings` của Web); sheet kết thúc có checklist (trận đã xong/tổng, cảnh báo trận LIVE, hạng mục chặn) và cho cả organizer (bỏ giới hạn chỉ admin); sheet đóng/mở đăng ký hàng loạt theo hạng mục (select-all, hạn mới khi mở lại quá hạn); sửa lệ phí nhanh có nút mức phí + bảng phân tích phí sàn.
- **Hạng mục & vòng đấu**: làm lại sheet hạng mục đầy đủ như `CreateDivisionModal` (nhận dạng, match type, bracket type, chuẩn/Lite, giới hạn sức chứa + ELO min/max + lệ phí riêng, luật chi tiết theo môn gồm sets/points/win-by-2/max deuce/super tiebreak, số lượt vòng tròn, cấu hình vòng bảng + playoff, giữ `SwissConfigEditor`, preset nhanh theo môn); thêm sheet cấu hình từng vòng đấu (sân, giờ mặc định, luật) gọi `PATCH /tournaments/stages/:stageId`.
- **VĐV & ghép cặp**: lọc danh sách theo trạng thái; sheet hồ sơ VĐV chi tiết (sửa liên hệ, ghi chú nội bộ BTC, câu trả lời form tùy chỉnh, gán seed, khoá/mở roster bóng đá, xoá VĐV ảo); tách cặp; sheet sinh VĐV ảo + xoá sạch; sheet wildcard giữ chỗ; sheet ghép cặp thủ công (chọn/kéo ghép, xáo trộn, đặt tên cặp) và ghép cặp tự động 3 chiến lược; import Excel tự tạo hạng mục mới theo tên trong file; xuất Excel danh sách VĐV.
- **Lịch sân**: sheet xếp nhiều trận nối tiếp (cascade) từ một ô với thời lượng từng trận; nâng cấp khay chưa xếp thành xếp hàng loạt (chọn sân đích + khung giờ); editor cài đặt khung giờ sân (giờ mở/đóng, bước ô 5–60 phút); phát hiện và cảnh báo VĐV bị xếp trùng giờ; AI xếp lịch bằng lệnh chữ (preview rồi áp dụng như bản nháp hiện có).
- **Livestream camera** (gỡ chặn có kiểm soát theo Web): CRUD camera PUSH/PULL + gắn camera vào sân (kéo-thả), QR stream key kèm issue/rotate/rename (không ghi log key), giữ nguyên pairing QR/stop session/Facebook hiện có; camera override từng trận đã có chỉ soát lại.
- Mọi popup mới dùng một khung sheet chung (tiêu đề, thân cuộn, thanh thao tác sticky, chống đóng khi đang gửi) đúng quy ước App hiện có.

## Capabilities

### New Capabilities
- `app-division-config`: Sheet cấu hình hạng mục đầy đủ và cấu hình từng vòng đấu cho BTC.
- `app-participant-tools`: Bộ công cụ BTC quản lý VĐV — lọc trạng thái, hồ sơ chi tiết, VĐV ảo, wildcard, tách cặp, xuất Excel.
- `app-pairing-tools`: Ghép cặp đôi thủ công (kéo/chọn, xáo trộn, đặt tên) và tự động 3 chiến lược.
- `app-livestream-cameras`: Quản lý camera PUSH/PULL và stream key của giải trên App.

### Modified Capabilities
- `app-tournament-lifecycle`: checklist khai mạc/kết thúc chi tiết, prompt hạng mục đủ chỗ, đóng/mở đăng ký hàng loạt theo hạng mục, organizer được kết thúc giải.
- `organizer-schedule-workspace`: xếp nhiều trận nối tiếp, xếp hàng loạt từ khay chờ, editor khung giờ sân, cảnh báo VĐV trùng giờ, AI xếp lịch bằng lệnh chữ.

## Impact

- App Flutter: `lib/features/tournament/screens/tournament_management_*`, `lib/features/organizer_ops/**`, `lib/features/tournament/widgets/**` (sheet mới), repository quản lý giải thêm các route pairing/mock/wildcard/note/stages/cameras/stream-key/AI-schedule mà Web đang dùng; `lib/l10n/app_vi.arb` + `app_en.arb` (key mới hai ngôn ngữ, chạy `flutter gen-l10n`); test widget/test API theo từng task.
- Backend API: không đổi route — App chỉ bắt đầu gọi các route đã có mà Web đang gọi (`/tournaments/:id/pairing/*`, `/mock-participants`, `/reserve-slots`, `/participants/:id/note`, `/tournaments/stages/:stageId`, `/tournaments/:id/cameras`, stream key, `/ai/tournaments/:id/schedule-preview`); đối chiếu controller Backend khi làm từng task.
- Web: không đổi.

## Out of Scope

- Series (chuỗi giải, legs, điểm PSR) và tạo giải bằng AI — đợt sau theo chốt người dùng.
- AI xếp lịch bằng GIỌNG NÓI (chỉ làm lệnh chữ; giọng nói cần thêm package speech-to-text chưa được yêu cầu).
- `FormatIllustrationDialog` (animation minh hoạ thể thức) — trang trí, để sau.
- Kéo-thả đổi thứ tự sponsor/hạng mục (giữ nhập số `displayOrder` và thứ tự hiện có); seed giữ dạng nhập số + tự động như hiện có (đủ chức năng so với Web).
- Đổi môn/thể thức tổng của giải sau khi tạo (Web cũng không cho).
- Popup thông tin đội bóng/logo đội cho bóng đá (out-of-scope kế thừa từ `participant-label-web-parity`).
