# Bằng chứng phát hành

Trạng thái: CHƯA ĐỦ để phát hành. Build APK debug đã thành công và đã cài lên `aa785b1a`; app đang chạy (PID 9761 ở lần `flutter run` gần nhất). Chưa kiểm giao diện trên máy. Mọi kết quả dưới đây là kết quả thật đã quan sát.

| Hạng mục | Trạng thái | Bằng chứng |
|---|---|---|
| `dart analyze` các file đã sửa (14 file) | Không có lỗi | Còn 1 warning và 2 info, xem mục "Lint còn lại" |
| Test parser (`roster_excel_parser_test.dart`) | Pass 20/20 | `flutter test --no-pub --concurrency=1`. Chưa có pha RED (test viết cùng code, không có log đỏ trước khi code) |
| Test repository (`tournament_management_repository_api_test.dart`) | Pass 45/45 | Gồm 5 test mới: 4 batch, 1 email. Implementation có trước test nên không có pha RED |
| Test thêm VĐV, hub, live overlay, live score source-text (6 file). Run lịch sử, trước khi thêm 2 test hub | Pass 81/81 | `add_athlete_entry_test`, `tournament_management_hub_screen_test`, `features/match/live_overlay_controls_test` (11/11), `match/live_score_no_fake_elo_test`, `match/live_score_member_profile_link_test`, `features/live_overlay_short_name_test` |
| Ba file test (parser, repository, hub) sau khi thêm 4 test mới (parser 1, repository 1, hub 2) | Pass 111/111 (tổng ba file, không tách theo test mới) | `flutter test --no-pub --concurrency=1` gồm 3 file. Gồm test `Notes` tiếng Anh, `customResponses.notes`, nút Excel trong hàng VĐV và mở sheet nhập |
| Probe pan `InteractiveViewer` (bản sao cấu hình) | Pass 2/2, đã xoá | Cấu hình mới pan được (translation < -50). Cấu hình có scroll lồng không pan (≈ 0) |
| Build APK debug | Thành công | `flutter build apk --debug --no-pub` → `build/app/outputs/flutter-apk/app-debug.apk`. Đầu log bị cắt bởi `tail`, chưa đọc khối cảnh báo KGP/Kotlin ở đầu |
| Cài máy `aa785b1a` và mở app | Thành công | `adb install -r` → `Success`; `flutter run` lần 2 cài và chạy. Tiến trình `flutter run` thoát mã 0 sau khi sẵn sàng; app vẫn chạy (PID 9761) |
| Pan và zoom sơ đồ trên máy (P4) | Chưa chứng minh | `INJECT_EVENTS` bị từ chối, không tap được tự động |
| Luồng nhập Excel và thêm VĐV trên máy | Chưa kiểm tra | Cần user |
| Backend cho app trên máy thật | Không kết nối | Docker Desktop tắt (`docker info` exit 1). Không có listener ở 3000, 5432, 6379. App đổi `localhost` thành `10.0.2.2` (chỉ đúng với emulator). Log: `DioClient ... connectionError` lặp lại |
| Validate workflow | Không chạy được trong App | Harness chỉ có ở thư mục cha |

## Lint còn lại (không do phiên này thêm, hoặc chưa xác minh)
- `test/features/tournament_management_hub_screen_test.dart:1221` warning `unused_local_variable` (`iconRect`). Có sẵn ở HEAD. Không sửa, ngoài phạm vi.
- `test/organizer_ops/add_athlete_entry_test.dart:200-201` info `use_null_aware_elements`. Nằm trong logic phí giải, không thuộc phần email. File này chưa được commit nên chưa đối chiếu được với HEAD.

## Lệch so với web (có chủ đích)
- `entryType` (Loại nhập) không đưa vào app: backend bỏ qua trường này (`roster-import.dto.ts`).
- Elo: "1.250" và "1,250" đều thành 1250. Web dùng `parseFloat` nên cho 1. "6,5" thành 6.5. "12 điểm" thành null. Web cho 12.
- Token paid tiếng Nga của web không đưa vào app. App chỉ giữ token VI và EN.
- Khách: tab "Nhập tên" là tab riêng, không gate theo kết quả tìm kiếm như `guestSearchMatches` của web (web chưa triển khai phần này).
- Sau lỗi không xác định, app vẫn refresh roster kể cả khi `addedCount = 0`. Web chỉ refresh khi `addedCount > 0`. Giữ để không mất banner `opsAddAthleteOutcomeUnknown`.
- Chuyển tab xoá danh sách đang chọn (hành vi cũ của app, giữ nguyên).
- Thêm nhiều VĐV: tuần tự, dừng ở lỗi đầu tiên (theo cây web được phép). Không dùng `allSettled` (chỉ có ở cây `-main`).
- Nút "Thêm VĐV" trên tab VĐV không còn full width (đặt cạnh "Nhập Excel" và "Tải mẫu" trong `Wrap`).
- `shareRosterTemplate` trên Windows chỉ ghi file vào thư mục tài liệu, không mở share sheet (giống `excel_export_service.dart`).
- Mẫu Excel: lấy từ web. vi dùng `Mau_Danh_Sach_VDV_Dang_Ky.xlsx` (sheet `Mau_Dang_Ky`). en dùng `Registration_List_Template.xlsx` (sheet `Registration template`). Locale khác en thì dùng vi.

## Chưa làm / ngoài phạm vi
- Chưa commit, chưa push.
- Hub Bracket redesign: chờ user duyệt frame. `changes/hub-bracket-division-rows/` chỉ là scaffold.
- Khoá nút xếp lô chống bấm đúp (`organizer_ops_screen.dart` `_bulkSchedule`): file có hunk của session khác.
- Seed chip, `categoryName`, `h2hStat`: không có nguồn trong `MatchModel`.
