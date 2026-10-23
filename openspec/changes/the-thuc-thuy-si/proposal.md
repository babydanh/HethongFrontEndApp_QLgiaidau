## Why

Backend sắp có thể thức Thụy Sĩ (`SWISS`). App chưa biết thể thức này: thể thức là chuỗi rải ở ~20 file, nhánh `else` mặc định gần như ở đâu cũng là loại trực tiếp nên stage `SWISS` sẽ bị vẽ như sơ đồ nhánh, và BTC dùng App chưa có chỗ chỉnh ghép cặp vòng kế. App đọc bảng xếp hạng từ endpoint rồi mới tự tính, nhưng bản tự tính không có Buchholz nên với Swiss phải tin dữ liệu Backend.

## What Changes

- Nhận diện `SWISS` ở hằng số, nhãn, icon, suy nhãn vòng (`Vòng N`), chọn thể thức cho nội dung, màn đăng ký và thẻ giải.
- Xem Swiss (công khai và BTC): bảng xếp hạng phẳng có Buchholz theo `rank` Backend, lịch trận theo vòng, nhãn `BYE`.
- Cấu hình Swiss cho nội dung: số vòng, thứ tự tiebreak (kéo sắp xếp), cách ghép vòng 1.
- Màn **Ghép cặp vòng N** cho BTC: máy đề xuất, BTC kéo thả (nhấn giữ) hoặc chọn từ bảng chọn "Đổi với...", thấy cảnh báo, xác nhận để tạo vòng; nút hoàn tác vòng mới nhất.
- Giao diện phẳng (không khung lồng khung, tối đa một loại icon).

## Out of scope

- Tạo giải Swiss từ các màn tạo giải nhanh/CLB/Lite (`create_public_quick_tournament_screen.dart`, `create_club_tournament_screen.dart`, `tournament_settings_form.dart`, `lite_management_*`), sinh sơ đồ phía client (`bracket_generator.dart`).
- Sửa `lib/data/api_service.dart` (file sinh bởi `scripts/sync-api-clients.js`, không được app dùng) và Backend.
- Ghép tăng tốc, cắt top-N vào knockout, ép cặp trước khi ghép (bản sau).
- Tự tính Buchholz ở client.

## Capabilities

### New Capabilities
- `swiss-format-display`: nhãn thể thức, bảng xếp hạng, trận theo vòng, BYE.
- `organizer-swiss-config`: cấu hình số vòng, tiebreak, ghép vòng 1.
- `organizer-swiss-pairing`: màn ghép cặp vòng kế, kéo thả/chọn, cảnh báo, xác nhận, hoàn tác.

### Modified Capabilities
- (không)

## Impact

- **Backend** (`HethongBackendApi_QuanlyGiaiDau`) cung cấp: `POST /api/v1/tournaments/:id/swiss/preview`, `.../swiss/validate`, `.../swiss/next-round`, `.../swiss/rounds/:round/undo`; `GET /api/v1/tournaments/:id/standings` thêm `rank, buchholz, buchholzCut1, sonnebornBerger`; `GET .../bracket` stage `type:'SWISS'` kèm `roundConfig.swiss`; `PATCH .../stages/:stageId`. Hợp đồng nguyên văn ở `design.md`.
- **Web**: change song song cùng hợp đồng; không đụng nhau về file.
- App: `lib/domain/entities`, `lib/domain/repositories/tournament_repository.dart`, `lib/data/repositories/api/api_tournament_repository.dart`, `lib/providers`, `lib/features/bracket`, `lib/features/tournament`, `lib/core`, `lib/l10n/*.arb` (+ file sinh), `test/`.
