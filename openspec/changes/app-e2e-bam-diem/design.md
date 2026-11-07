## Cách làm
Theo mẫu `integration_test/xem_*_test.dart`: `IntegrationTestWidgetsFlutterBinding`, `xemApp(...)` bọc theme và l10n thật, `XemShooter.snap` chụp. Mỗi test bơm panel thật (`PickleballCourtPanel`, `RallyScorePanel`, `TennisScorePanel`, `FootballScorePanel`) với `ScorePanelNotifier` thật khởi tạo từ state do test chọn (cách `test/match/*_score_panel_*_test.dart` đang dùng), `IMatchRepository` giả chỉ nuốt lệnh ghi. Bấm bằng `tester.tap(find.text(...))` như người dùng.

## Phương án đã loại
- Chạy với Backend thật (app-e2e có sẵn): chậm, cần tạo trận từng môn qua API, hợp đồng bóng đá và tennis chưa chốt ở Backend.
- Dựng lại luật trong test: loại, test phải đi qua notifier thật để bắt bug sản phẩm.
