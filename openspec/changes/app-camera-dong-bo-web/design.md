## Bảng Web → App
| # | Web | App |
|---|-----|-----|
| 1 | `useMatchStreamControl` + `StreamToggleButton` (OfficialScoreModal) | `matchStreamControlProvider(matchId)` (`lib/providers/match_stream_control_provider.dart`) + hàng Livestream trong `official_score_modal.dart` |
| 2 | `statusLabelKey` badge ở LivestreamTab / CourtCameraBoard | `CameraStatusBadge` (`lib/features/tournament/widgets/camera_status_badge.dart`) dùng ở `tournament_camera_panel.dart`, `tournament_management_camera_section.dart` |
| 3 | `MatchCard` của CourtCameraBoard + handler start/stop LivestreamTab | `MatchStreamActions` widget + `tournamentMatchLivestreamsProvider(tid)` ở `lib/providers/` |
| 3 | `canShowRecordingButton`, `readHasRecording` | hàm thuần trong `lib/features/tournament/utils/recording_access.dart` |
| 3 | `RecordingSequentialPlayer` nút "Tải video đầy đủ" | nút trong `match_recording_player_sheet.dart`; `downloadFullRecording` ở repository (Dio kèm token → `getTemporaryDirectory` → `Share.shareXFiles`) |

## Quyết định (ngã rẽ → chọn giống Web)
- Không endpoint "bắt đầu ghi": ghi MP4 theo start/stop phát.
- `hasCamera` của trận = trận có `cameraId` (từ `/livestream/tournaments/{tid}/matches`) hoặc sân của trận có camera (như `renderCard` Web).
- Tải file: App đã có `share_plus` + `path_provider` → tải về file tạm rồi chia sẻ; không mở trình duyệt, không thêm package.
- Lỗi 5xx khi điều khiển không toast (giống Web).
- Badge: Web chỉ chữ; App thêm chấm + Semantics theo yêu cầu truy cập.
- Trang admin cameras không làm.
