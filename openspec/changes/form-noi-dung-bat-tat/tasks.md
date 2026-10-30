## 1. Form gọn

- [x] 1.1 Bỏ khung chữ khoá, Luật vòng thành công tắc, ELO hiện sẵn, bấm mục đang mở thì đóng. Tiêu chí: `flutter test --no-pub test/features/division_editor_sheet_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/division_editor_sheet.dart`, `lib/features/tournament/widgets/division_editor_accordion.dart`; test `test/features/division_editor_sheet_test.dart`; `integration_test/xem_noidung_form_vongdoi_test.dart` (đổi khoá bấm, chạy ở cloud)
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 1.1 giữ các file này
  - Phụ thuộc: (không)

## 2. Minh hoạ có animation

- [x] 2.1 Hộp thoại minh hoạ phát animation lặp cho 5 thể thức, có chạy lại và tạm dừng. Tiêu chí: `flutter test --no-pub test/features/format_illustration_stage_test.dart` → exit 0
  - Files: tạo `lib/features/tournament/widgets/format_illustration_scenes.dart`, `format_illustration_stage.dart`; sửa `format_illustration_dialog.dart`, `lib/l10n/app_vi.arb`, `app_en.arb` (+ code sinh); test `test/features/format_illustration_stage_test.dart`
  - Giao: `sceneFor(String bracketType): FormatScene`, `FormatIllustrationStage({required String bracketType})` · Nhận: (không)
  - Chủ file chung: 2.1 giữ các file này
  - Phụ thuộc: (không)
