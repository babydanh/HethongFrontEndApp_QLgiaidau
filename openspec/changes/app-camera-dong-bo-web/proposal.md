## Why
Web đã có đủ chức năng camera/livestream theo trận (bật/tắt phát, trạng thái camera, nút bản ghi, tải video đầy đủ) nhưng App thì thiếu: App chỉ xem được bản ghi và không bật/tắt được phát, badge camera chỉ phân biệt LIVE, nút bản ghi luôn hiện, không tải được video. Mục tiêu: App có các tính năng camera/livestream của trận giống hệt Web. Chủ repo đã giao làm liền, không dừng hỏi; ngã rẽ chọn phương án giống Web nhất (ghi ở `handoff.md`).

## What Changes
1. **Trang chấm điểm trận (OfficialScorePage)**: nút "Livestream" Bắt đầu/Dừng theo `GET control-state` (`hasCamera`), gọi `POST start|stop`, khoá khi đang gửi, toast `recordingPending` khi `recordingStatus=PENDING`, 403 thì ẩn nút + toast `permissionDenied`, 5xx im lặng; xong thì làm mới `matchPlaybackProvider`.
2. **Badge trạng thái camera** đủ 6 trạng thái (IDLE/ASSIGNED/WAITING/LIVE/OFFLINE/ERROR) có chấm + chữ + màu, dùng ở panel camera và hàng camera theo sân.
3. **Thẻ trận ở bảng camera**: Bắt đầu / Dừng / Xem bản ghi (ẩn khi đang LIVE, hiện theo `canShowRecordingButton`); trạng thái phát theo trận lấy từ `GET /livestream/tournaments/{tid}/matches`; "Tải video đầy đủ" trong sheet phát (Dio kèm token → file tạm → chia sẻ bằng `share_plus` đã có).

## Out of scope
- Trang admin cameras (`/admin/livestream/cameras`).
- Backend và Web: chỉ đọc, không sửa. Không thêm package, không thêm endpoint mới.

## Capabilities
### New Capabilities
- `match-stream-control`: nút bật/tắt phát của trận ở trang chấm điểm.
- `camera-status-badge`: badge 6 trạng thái camera.
- `match-board-stream-actions`: Bắt đầu/Dừng/Bản ghi/Tải trên thẻ trận.

### Modified Capabilities
- `match-recording-playback`: thêm "Tải video đầy đủ".

## Impact
- Sửa `lib/data/models/match_recording_catalog_model.dart`, `lib/domain/repositories/match_recording_catalog_repository.dart`, `lib/data/repositories/api/api_match_recording_catalog_repository.dart`, `lib/providers/`, `lib/features/match/widgets/official_score_modal.dart`, `lib/features/tournament/**` (panel, section, sheet), `lib/l10n/app_vi.arb`, `app_en.arb`.
- Test mới `TC-CAM-SYNC-01..`; giữ xanh `test/match_recording_catalog_model_test.dart`, `test/features/tournament_management_camera_catalog_test.dart`.
