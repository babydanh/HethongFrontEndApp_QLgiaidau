# Proposal

## Why

Người dùng (18/10) muốn: chủ giải thấy số ms của video live, FPS theo luồng thật, và phát lại bản ghi. Web đã có huy hiệu `Ping … ms · Trễ …` cho chủ giải/admin và trình phát bản ghi nối tiếp; App chưa có cả hai.

Đã xác minh trong code (lane `live-stats-recording-playback-20261018` từ `origin/main`):
- `lib/features/match/widgets/live_video_player.dart:58-107`: phát bằng `video_player` 2.11.1 (`VideoPlayerController.networkUrl`); chỉ đọc `value.size` để lấy tỉ lệ khung. Không hiện thông số luồng nào.
- `video_player` không cho biết FPS, không có callback từng khung. App không tự đo được FPS hiển thị; FPS nguồn chỉ lấy được từ máy media qua Backend (xem "What Changes").
- `lib/features/match/screens/live_score_screen.dart:639-642`: quyền điều khiển dựa vào `auth.canScore` (gồm trọng tài), không phải "chủ giải/admin". Chủ giải xác định được bằng `Tournament.creatorId == userProfile.id` (cách đã dùng ở `tournament_intro_screen.dart:156`), admin bằng `userProfile.hasRole('ADMIN')` (`tournament_management_hub_screen.dart:132`).
- `lib/features/tournament/widgets/match_recording_catalog_sheet.dart`: chỉ liệt kê ngày và tên tệp ghi; không phát được. Repository gọi `control-state`, `recording-days`, `recordings?period=`; chưa gọi `GET /livestream/matches/:matchId/recordings/playlist?period=YYYY-MM-DD`, endpoint trả `{ period, segments: [{ name, startAt: string|null, url }] }` (Backend `livestream.service.ts:75-85`, quyền `assertCanControlMatchStream`: admin, chủ giải, staff giải, trọng tài được phân công).

## What Changes

**Huy hiệu cho chủ giải/admin trên video live** (`LiveVideoPlayer`, góc trên trái, chữ trắng nền đen mờ như Web):
- `Ping … ms`: thời gian nhận xong manifest HLS (GET `playbackUrl`, không cache), đo mỗi 5 giây bằng `Dio` riêng không gắn token. CHỈ đo khi đường dẫn URL kết thúc bằng `.m3u8` (bỏ query khi so); URL khác (ví dụ HTTP-FLV tải mãi không dừng) KHÔNG gọi mạng và hiện `—`. Manifest quá 64 KB hoặc quá 4 giây thì huỷ bằng `CancelToken` và hiện `—`.
- `Trễ … ms`: phần video đã tải trước điểm đang phát (mép cuối `value.buffered` trừ `value.position`), cập nhật mỗi giây. Đây là đệm trên App, KHÔNG phải độ trễ từ camera tới người xem. Chưa có dữ liệu thì `—`.
- `FPS …`: lấy từ `video.fps` của `GET /livestream/matches/{matchId}/stream-info` (contract của change Backend `live-stream-media-info`, Bearer, cùng quyền `assertCanControlMatchStream`), hỏi mỗi 10 giây khi huy hiệu đang hiện. `available:false`, `video:null` hoặc lỗi thì `—`. Đây là FPS nguồn do máy media báo, không phải FPS App đo được trên khung hình hiển thị, vì `video_player` không có callback từng khung.
- Huy hiệu đọc `Ping <n> ms · Trễ <n> ms · FPS <n>`.
- Chỉ hiện khi người xem là admin hoặc người tạo giải. Trọng tài, người xem thường không thấy.
- Phụ thuộc: change Backend `live-stream-media-info` phải có trước để `FPS` hiện số thật. Nếu endpoint chưa có, `FPS` hiện `—` và Ping/Trễ vẫn chạy bình thường.

**Phát lại bản ghi** trong sheet "Bản ghi" của từng trận (màn quản lý camera):
- Nút "Phát lại ngày này" mở trình phát; gọi `recordings/playlist?period=` của ngày đang chọn.
- Phát nối tiếp các đoạn MP4 theo thứ tự: hai `VideoPlayerController` luân phiên, đoạn kế được khởi tạo trước khi đoạn đang phát kết thúc.
- Danh sách đoạn với giờ bắt đầu (`startAt`, giờ VN; thiếu thì hiện tên tệp); chạm để chuyển đoạn. Đoạn lỗi thì đánh dấu và tự bỏ qua; tất cả lỗi thì báo "Không phát được bản ghi nào".

## Không làm trong change này

- Không đổi quyền endpoint, không đổi player live cho người xem thường.
- Không tự kết nối lại luồng live khi rớt (hành vi hiện tại giữ nguyên).
- Không đo FPS hiển thị trên App (không có nguồn từ `video_player`); không thêm package.

## Capabilities

### New Capabilities

- `live-owner-stream-stats`: huy hiệu thông số luồng (Ping, Trễ, FPS) cho chủ giải/admin trên App.
- `match-recording-playback`: phát lại bản ghi nối tiếp trên App.

### Modified Capabilities

- Không có.

## Impact

- Code: `live_video_player.dart`, `live_video_box.dart`, `live_score_screen.dart` (truyền cờ chủ giải/admin), repository + model stream-info (`match_playback_repository.dart`, `api_match_playback_repository.dart`, model mới), `match_recording_catalog_sheet.dart`, model + repository bản ghi, widget mới phát bản ghi, `app_vi.arb`, `app_en.arb`.
- Test: widget test huy hiệu (hiện cho chủ giải, ẩn cho người xem), test formatter huy hiệu, test repository stream-info, test repository playlist (path, parse, bỏ đoạn URL không an toàn), test thứ tự/bỏ qua đoạn lỗi của bộ điều phối phát.
- Phụ thuộc: change Backend `live-stream-media-info` (endpoint `stream-info`).
- Rủi ro: hai controller MP4 cùng lúc tốn bộ nhớ; chỉ giữ tối đa 2, giải phóng đoạn đã xong.
