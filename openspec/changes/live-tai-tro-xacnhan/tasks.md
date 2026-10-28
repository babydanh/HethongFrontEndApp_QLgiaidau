## 1. Màn 12 — Nhà tài trợ

- [x] 1.1 Hàm thuần tính thay đổi `displayOrder` sau khi kéo + getter hiển thị công khai/lưu trữ. Tiêu chí: `flutter test --no-pub test/domain/tournament_sponsor_order_test.dart` → exit 0
  - Files: sửa `lib/domain/entities/tournament_sponsor.dart`; test `test/domain/tournament_sponsor_order_test.dart`
- [x] 1.2 Màn Nhà tài trợ: tay kéo, avatar chữ cái, công tắc hiển thị, vuốt trái lưu trữ, nút Thêm trên thanh trên, xem trước, chú thích; bỏ ô số thứ tự trong hộp sửa. Tiêu chí: `flutter test --no-pub test/features/tournament_management_sponsors_section_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_sponsors_section.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/features/tournament_management_sponsors_section_test.dart`
  - Chủ file chung: ARB vi/en

## 2. Màn 11 — Livestream

- [x] 2.1 Nút QR của camera PUSH mở hộp xác nhận trước khi mở sheet khoá phát. Tiêu chí: `flutter test --no-pub test/features/tournament_camera_panel_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/tournament_camera_panel.dart`, ARB; test `test/features/tournament_camera_panel_test.dart`
- [x] 2.2 Khối "Camera · N" (thanh trên có nút Thêm camera, hàng camera có trạng thái Đang phát/Chờ) và khối "Sân" gán/đổi camera bằng chip chọn. Tiêu chí: `flutter test --no-pub test/features/tournament_camera_panel_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/tournament_camera_panel.dart`, ARB; test như 2.1
- [x] 2.3 Dừng phát luôn hỏi lại: `_stopSession` đã có hộp xác nhận và test đã khoá hành vi (không gọi `stopSession` trước khi xác nhận). Không code mới; chạy lại test. Tiêu chí: `flutter test --no-pub test/features/tournament_management_livestream_section_test.dart` → exit 0
  - Files: không sửa; test sẵn có `test/features/tournament_management_livestream_section_test.dart`

## 3. Màn 7 — Xác nhận kết quả giải

- [ ] 3.1 Repository: `confirmTournamentResults(id)` gọi `POST /tournaments/:id/results/confirm`. Tiêu chí: `flutter test --no-pub test/tournament_management_repository_api_test.dart` → exit 0
  - Files: sửa `lib/domain/repositories/tournament_management_repository.dart`, `lib/data/repositories/api/api_tournament_management_repository.dart`; test `test/tournament_management_repository_api_test.dart`
- [ ] 3.2 Sheet hoàn tất giải: podium hạng 1-3, khối giải thưởng, điều kiện, dòng đỏ khi bị chặn, hộp xác nhận nêu hậu quả. Tiêu chí: `flutter test --no-pub test/features/lifecycle_end_sheet_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/lifecycle_end_sheet.dart`, ARB; test `test/features/lifecycle_end_sheet_test.dart`
- [ ] 3.3 Thẻ chốt lại kết quả (khi COMPLETED và `needsReconfirm`) ở hub quản lý. Tiêu chí: `flutter test --no-pub test/features/tournament_management_hub_screen_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_hub_screen.dart`, ARB; test `test/features/tournament_management_hub_screen_test.dart`
