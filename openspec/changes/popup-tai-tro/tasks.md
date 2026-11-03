## 1. Tab Tài trợ

- [x] 1.1 Giữ nhà tài trợ không logo. Tiêu chí: `flutter test --no-pub test/data/tournament_public_sponsors_test.dart test/data/tournament_open_speed_repository_test.dart test/domain` → exit 0 (TC-SPON-01..03, đỏ trước xanh sau)
  - Files: sửa `lib/data/repositories/api/api_tournament_repository.dart:160`, `lib/domain/entities/tournament.dart:364`; tạo `test/data/tournament_public_sponsors_test.dart`
  - Giao: (không đổi chữ ký) · Nhận: `TournamentSponsor` có `logoUrl` rỗng hợp lệ
  - Chủ file chung: 1.1 giữ hai file trên
  - Phụ thuộc: không

## 2. Popup dùng chung một theme

- [x] 2.1 Thêm `showDragHandle: true` và gỡ `shape`/`backgroundColor` nhái ở 26 bottom sheet nền thường. Tiêu chí: `flutter test --no-pub test/features/social/social_sheets_theme_test.dart` → exit 0 (TC-POP-01, đỏ khi bỏ tay kéo)
  - Files: sửa 24 file có `showModalBottomSheet` (danh sách trong `git diff --name-only`); tạo `test/features/social/social_sheets_theme_test.dart`
  - Giao: (không) · Nhận: `AppTheme.bottomSheetTheme` (bo 24)
  - Chủ file chung: không (mỗi file một chỗ gọi)
  - Phụ thuộc: không
- [x] 2.2 Gỡ `shape`/`backgroundColor: bgCard` riêng ở 12 hộp thoại. Tiêu chí: `flutter test --no-pub test/match test/features/social test/features/community test/features/tournament test/features/bracket test/features/match test/data test/domain test/features/profile` → exit 0
  - Files: sửa `lib/core/widgets/app_share_modal.dart:251`, `lib/features/community/social/club_chat_screen.dart:299`, `lib/features/community/widgets/club_detail_gallery_preview.dart:37`, `lib/features/community/social/widgets/community_club_match_session_roster_widget.dart:112`, `lib/features/community/social/widgets/community_tournament_roster_widget.dart:232`, `lib/features/match/screens/matches_list_screen.dart:596`, `lib/features/match/widgets/injury_input_dialog.dart:37`, `lib/features/match/widgets/official_score_modal.dart:1277`, `lib/features/match/widgets/penalty_input_dialog.dart:67`, `lib/features/social/widgets/social_cancel_session_dialog.dart:15`, `lib/features/social/widgets/create_edit_screen/social_price_dialog.dart:41`, `lib/features/tournament/widgets/public_tournament_create_entry.dart:28`
  - Giao: (không) · Nhận: `AppTheme.dialogTheme` (bo 20, viền mảnh)
  - Chủ file chung: không
  - Phụ thuộc: sau 2.1

- [x] 2.3 Màu chữ bục podium theo huy chương (vàng ấm, bạc xám trung tính, đồng ấm), mỗi thẻ vẫn ≥ 4.5:1 trên nền. Tiêu chí: `flutter test --no-pub test/features/lifecycle_end_sheet_test.dart` → exit 0 (TC-POP-02, đỏ trước xanh sau)
  - Files: sửa `lib/features/tournament/widgets/lifecycle_end_sheet.dart:455-466` (`_PodiumSlot._ink`); test `test/features/lifecycle_end_sheet_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: không
  - Phụ thuộc: không
- [x] 2.4 Sửa E2E `xem_ketqua_btc_test.dart` theo bảng Kết quả mới (đọc `managedMatchesWithDivisionProvider`, bấm dòng giờ/sân `results-schedule-<id>`) và thêm bước chụp popup nhập điểm. Tiêu chí: `flutter analyze --no-pub integration_test/xem_ketqua_btc_test.dart` → exit 0; chạy trên cloud (`cloud-test-runner.py run --target app-e2e`)
  - Files: sửa `integration_test/xem_ketqua_btc_test.dart`
  - Giao: (không) · Nhận: key `results-schedule-<id>`, `results-add-score-<id>`, `results-score-sheet`, `results-score-played-at`
  - Chủ file chung: không
  - Phụ thuộc: sau 2.3

## 3. Kiểm tra cuối

- [x] 3.1 Phân tích tĩnh và validate. Tiêu chí: `flutter analyze --no-pub` đúng các file đã sửa không có lỗi mới (chỉ info/warning cũ ở dòng không đụng); `openspec validate popup-tai-tro --strict` → exit 0
  - Kết quả: analyze 0 lỗi; 13 mục cũ (info `curly_braces_in_flow_control_structures`, `prefer_if_null_operators`, warning `unnecessary_non_null_assertion` ở `app_share_modal.dart:170..293`) ở dòng không thuộc change này. Ảnh E2E cloud và chụp điện thoại: xem ghi chú bàn giao.
  - Files: không sửa code
  - Giao: (không) · Nhận: toàn bộ task 1..2
  - Chủ file chung: không
  - Phụ thuộc: sau 2.2
