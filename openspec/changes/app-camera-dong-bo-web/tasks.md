## 1. Model + repository (nền cho 3 mục)
- [x] 1.1 Model: `streamStatus` (ENDED→IDLE, lạ→null) trong control-state, `RecordingStatus`, kết quả start/stop (`recordingStatus`, `publishUrl`), tóm tắt livestream theo trận (`cameraId`, `streamStatus`, `hasRecording`); repo thêm `startMatchStream`, `stopMatchStream`, `listTournamentMatchLivestreams`, `downloadFullRecording`. Tiêu chí: `flutter test --no-pub test/features/camera_sync_repository_test.dart` → exit 0 (TC-CAM-SYNC-01..06)
  - Files: sửa `lib/data/models/match_recording_catalog_model.dart`, `lib/domain/repositories/match_recording_catalog_repository.dart`, `lib/data/repositories/api/api_match_recording_catalog_repository.dart`; test `test/features/camera_sync_repository_test.dart`
  - Giao: các hàm repo trên · Nhận: các route ở design.md
  - Phụ thuộc: không

## 2. Mục 1: nút phát ở trang chấm điểm
- [x] 2.1 Notifier `matchStreamControlProvider` + hàng Livestream. Tiêu chí: `flutter test --no-pub test/features/camera_sync_stream_control_test.dart` → exit 0 (TC-CAM-SYNC-07..13)
  - Files: tạo `lib/providers/match_stream_control_provider.dart`; sửa `lib/features/match/widgets/official_score_modal.dart`, arb vi/en
  - Giao: `MatchStreamControlNotifier` · Nhận: repo 1.1
  - Phụ thuộc: 1.1

## 3. Mục 2: badge camera
- [ ] 3.1 `CameraStatusBadge` + dùng ở panel và hàng theo sân. Tiêu chí: `flutter test --no-pub test/features/camera_sync_status_badge_test.dart test/features/tournament_camera_panel_test.dart` → exit 0 (TC-CAM-SYNC-14..17)
  - Files: tạo `lib/features/tournament/widgets/camera_status_badge.dart`; sửa `tournament_camera_panel.dart`, `tournament_management_camera_section.dart`, arb
  - Phụ thuộc: không

## 4. Mục 3: thẻ trận + bản ghi + tải
- [ ] 4.1 `recording_access.dart` + provider trận-livestream + `MatchStreamActions` trên thẻ trận. Tiêu chí: `flutter test --no-pub test/features/camera_sync_match_actions_test.dart test/features/tournament_management_camera_catalog_test.dart` → exit 0 (TC-CAM-SYNC-18..26)
  - Files: tạo `lib/features/tournament/utils/recording_access.dart`, `lib/features/tournament/widgets/match_stream_actions.dart`, `lib/providers/tournament_match_livestreams_provider.dart`; sửa `tournament_management_camera_section.dart`, arb
  - Phụ thuộc: 1.1, 3.1 (chung file section)
- [ ] 4.2 "Tải video đầy đủ" trong sheet phát. Tiêu chí: `flutter test --no-pub test/features/camera_sync_download_test.dart` → exit 0 (TC-CAM-SYNC-27..30)
  - Files: sửa `lib/features/tournament/widgets/match_recording_player_sheet.dart`, arb
  - Phụ thuộc: 1.1

## 5. Kiểm và bàn giao
- [ ] 5.1 `flutter gen-l10n`; `flutter analyze --no-pub` trên `lib/features/tournament lib/features/match lib/providers lib/data lib/domain` 0 lỗi; `test/match_recording_catalog_model_test.dart` xanh; cập nhật `handoff.md`; push; CI xanh.
