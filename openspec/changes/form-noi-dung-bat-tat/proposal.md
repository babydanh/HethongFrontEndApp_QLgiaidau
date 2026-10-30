## Why

Form "Thêm nội dung" còn nhiều thao tác thừa so với Web: mục Luật vòng phải bấm mở rồi mới bật/tắt được, mục Ràng buộc ELO phải bấm mở mới thấy ô nhập, khung chữ giải thích khoá chiếm chỗ đầu form, và minh hoạ thể thức chỉ là một icon tĩnh trong khi Web có animation.

## What Changes

- Bỏ khung chữ "Nội dung này đã có sơ đồ…" ở đầu form (biểu tượng khoá và ô bị vô hiệu đã đủ báo).
- "Luật vòng" thành hàng có công tắc ngay trên hàng: bật hiện ô luật theo môn, tắt ẩn đi; không còn bấm để mở sang mục.
- "Ràng buộc ELO" luôn hiện sẵn (giới hạn số đội, ELO, phí), không cần bấm mở.
- Bấm lại mục đang mở (Cơ bản, Vòng bảng/Thuỵ Sĩ) thì đóng mục đó.
- Hộp thoại minh hoạ thể thức có animation lặp cho cả 5 thể thức, kèm nút chạy lại và tạm dừng; giảm chuyển động thì chỉ hiện khung cuối.

## Out of scope

Lưới chọn thể thức, nút ▶ trên từng ô, luồng lưu, phần bước/chú thích từng bước của animation Web (App giữ đoạn mô tả hiện có).

## Capabilities

### New Capabilities
- `division-editor-inline`: Luật vòng bật/tắt tại chỗ, ELO hiện sẵn, minh hoạ có animation.

### Modified Capabilities

## Impact

`lib/features/tournament/widgets/division_editor_sheet.dart`, `division_editor_accordion.dart`, `format_illustration_dialog.dart`; mới `format_illustration_scenes.dart`, `format_illustration_stage.dart`; `lib/l10n/app_vi.arb`, `app_en.arb` (3 khoá mới) và code sinh; test `division_editor_sheet_test.dart`, `format_illustration_stage_test.dart`; `integration_test/xem_noidung_form_vongdoi_test.dart` (đổi khoá bấm).
