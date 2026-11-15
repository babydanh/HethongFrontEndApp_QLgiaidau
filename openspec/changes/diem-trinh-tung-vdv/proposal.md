## Why

BTC cần điểm trình từng VĐV để xếp cặp theo tổng đôi (điều lệ Dragons lần IV: tổng đôi 1.225–1.240). Màn nhập Excel của App đọc số đầu tiên của ô điểm (`Top 8 CCTV 610` thành DUPR 8, `605-610` lặng lẽ lấy 605, `6.2` trong cột ba chữ số thành DUPR 6.2), đôi gộp từ hai dòng chỉ gửi trung bình, và thẻ xem trước không hiện điểm.

## What Changes

- `parseRosterScore` bỏ số dính chữ (`4P`, `6xx`), bỏ số sau `Top/Giải/Hạng/Vòng/Lần/Bảng/Năm`, ưu tiên điểm ELO 100–999; trả thêm cờ `RANGE`/`MULTIPLE`. Ô có chữ số mà không đọc ra điểm mang cờ `UNREADABLE`. Cột phần lớn ba chữ số thì ô `6.2` đọc 620, cờ `CONVERTED`.
- Đôi gộp từ hai dòng giữ `player1Elo`/`player2Elo`; item gửi `POST /api/v1/tournaments/:id/roster-import` mang hai trường này thay cho `elo`. Dòng không có điểm từng VĐV vẫn gửi `elo`. Bỏ VĐV 2 ở chi tiết dòng thì bỏ điểm của VĐV đó.
- Thẻ đôi ở xem trước hiện `Điểm trình: 620 + 605 · tổng 1225`; điểm có cờ tô vàng kèm lý do.
- Chi tiết participant không liệt kê `memberElos` thành câu trả lời riêng.

## Không làm (out of scope)

- Hiện điểm nhập (`importedElo`, tổng đôi) trong chi tiết participant: App hiện chưa hiện điểm nhập ở đó.
- Sửa tay điểm ở xem trước, luật tổng trình của hạng mục, tự ghép theo tổng trình.

## Repo bị ảnh hưởng

- **Backend API**: `RosterImportItemDto` thêm `player1Elo`, `player2Elo`; lưu `customResponses.memberElos` (change Backend `diem-trinh-tung-vdv`). Backend bật `forbidNonWhitelisted` nên App bản mới chỉ phát hành sau khi Backend lên production.
- **Web**: change `diem-trinh-tung-vdv` bên Web làm phần tương tự.

## Impact

- Code: `lib/features/organizer_ops/utils/roster_excel_parser.dart`, `lib/features/organizer_ops/utils/roster_pairing.dart`, `lib/features/organizer_ops/screens/roster_pair_card.dart`, `lib/features/organizer_ops/screens/roster_import_sheet.dart`, `lib/domain/entities/roster_import.dart`, `lib/features/tournament/widgets/participant_detail_sheet.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (+ file sinh `app_localizations*.dart`).
- Test: `test/features/organizer_ops/roster_score_flags_test.dart` (mới).
