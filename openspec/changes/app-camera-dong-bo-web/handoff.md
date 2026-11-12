# Handoff: app-camera-dong-bo-web

Nhánh: `cloud/danh4-app-camera-dong-bo-web` (máy danh4). Chưa gộp `main`, chưa deploy. Backend/Web chỉ đọc, không sửa.

## Bảng Web ↔ App
| # | Web | App | Trạng thái |
|---|-----|-----|-----------|
| 1 | `OfficialScoreModal` `StreamToggleButton` + `useMatchStreamControl` | `lib/features/match/widgets/match_stream_toggle_row.dart` (nhúng trong `official_score_modal.dart`), `lib/providers/match_stream_control_provider.dart` | Xong. Chỉ hiện khi `hasCamera` và trạng thái nhận ra; ENDED→IDLE; khoá khi đang gửi; 403 ẩn nút + `permissionDenied`; 5xx im lặng; PENDING cảnh báo; sau start/stop làm mới `matchPlaybackProvider` |
| 2 | Badge `statusLabelKey` (LivestreamTab) | `lib/features/tournament/widgets/camera_status_badge.dart`, dùng ở `tournament_camera_panel.dart` và `court_camera_row.dart` | Xong. 6 trạng thái + "Không rõ", chấm + chữ + Semantics |
| 3 | `CourtCameraBoard` `MatchCard` + handler `handleStart/handleStop` | `lib/features/tournament/widgets/match_stream_actions.dart` (dùng ở hàng trận trong `tournament_management_camera_section.dart`: danh sách trận và thẻ sân), `lib/providers/tournament_match_livestreams_provider.dart` | Xong: Xem live / Bắt đầu / Dừng / MP4. Start có `publish` thì sao chép liên kết; PULL báo URL của sân; PENDING cảnh báo |
| 3 | `canShowRecordingButton` | `lib/features/tournament/utils/recording_access.dart` | Xong; nút MP4 ẩn khi LIVE |
| 3 | `RecordingSequentialPlayer` "Tải video đầy đủ" | `match_recording_player_sheet.dart` + `utils/full_recording_download.dart` | Xong: playlist (kiểm quyền) → Dio tải kèm token → file tạm → `share_plus` → xoá file |

Endpoint đã dùng (đều có ở Web `api.ts`, không bịa): `GET /livestream/matches/{id}/control-state`, `POST .../start`, `POST .../stop`, `GET /livestream/tournaments/{tid}/matches`, `GET .../recording-days`, `GET .../recordings/playlist?period=`, `GET .../recordings/download?period=`.

## Ngã rẽ đã chọn (giống Web nhất)
- Không có endpoint "bắt đầu ghi": ghi MP4 đi theo start/stop phát.
- `hasCamera` của trận = trận có `cameraId` (từ `/livestream/tournaments/{tid}/matches`) hoặc sân có camera có `playbackUrl` (như `renderCard` Web).
- Tải file: App đã có `share_plus` + `path_provider` (xuất Excel) nên tải về file tạm rồi mở chia sẻ; không thêm package, không mở trình duyệt.
- Nhãn hàng trên trang chấm điểm lấy theo Web: vi "Trực tiếp", en "Livestream".
- Giải chỉ-đọc: ẩn Bắt đầu/Dừng, vẫn có Xem live và MP4.

## Test đã chạy (mã thoát thật, máy danh4, Flutter 3.47.9)
- TC-CAM-SYNC-01..32 ở `test/features/camera_sync_{repository,stream_control,status_badge,match_actions,board,download}_test.dart`.
- Chạy chung 16 file liên quan (6 file mới + `test/match_recording_catalog_model_test.dart`, `test/features/tournament_management_camera_catalog_test.dart`, panel/sheet camera, player sheet, repo recording, 2 file `official_score_modal`): `flutter test --no-pub ...` → **exit 0, 114 test pass**.
- `flutter analyze --no-pub lib/features/tournament lib/features/match lib/providers lib/data lib/domain` → **0 lỗi** (30 info/warning có sẵn ở file không đụng tới, không có dòng nào ở file của change này).
- `openspec validate app-camera-dong-bo-web --strict` → **exit 0**.
- Không chạy cả bộ test, không E2E.
- Lưu ý quy trình (TDD): lượt đỏ thật (lỗi biên dịch vì thiếu API) chỉ chạy cho TC-01..06 và TC-29..32. Các test còn lại (07..28) viết trước code nhưng mình không chạy lượt đỏ riêng, chạy lần đầu sau khi code đã có.

## CI
- `CI` của repo (workflow push) trên nhánh này: run 43073247319 **FAIL sau 2 giây, 0 step, không có runner**. Mọi run gần đây của repo (cả nhánh danh3 và `ci/merge-lane/*`, từ 2026-11-11 08:48 trở đi) đều fail đúng kiểu này → lỗi hạ tầng GitHub Actions của repo (nghi hết hạn mức/billing hoặc runner), không phải do code. Cần chủ repo kiểm tra tab Actions/Billing.
- Đã chạy thêm qua `cloud-test` (agent-orchestrator), target `app`, nhánh này, `--specs test/features/camera_sync_repository_test.dart`: run https://github.com/babydanh/agent-orchestrator/actions/runs/43073311622 → **success** (job "Test Flutter App (Dart Analyze & Widget)" success). Lưu ý run này chỉ chỉ định 1 file spec; 5 file test mới còn lại + analyze chạy xanh ở máy danh4 như trên.

## Còn thiếu / lưu ý
- Chưa chạy trên máy thật/ảnh chụp màn hình (không có thiết bị); đã kiểm không tràn ở 360px và 900px bằng widget test, vùng bấm ≥ 44 (trừ nút tròn "compact" ở màn ngang thấp của trang chấm điểm: cao 30–38 vì hàng tiêu đề chật; rộng 44).
- Trận đã hoàn thành không nằm trong danh sách "trận có thể gán sân" của bảng camera (hành vi App có sẵn), nên chưa có MP4 cho các trận đó ở bảng này.
- Đọc control-state lỗi không phải 403 ở trang chấm điểm: im lặng (Web có toast lỗi chung cho lỗi đọc không phải 5xx).
- Trang admin cameras: ngoài phạm vi, không làm.
- `tournament_management_livestream_section.dart:27` còn dòng chú thích "Still absent: starting a match stream": chưa sửa (đó là phần khác, nhắc để dọn sau).
