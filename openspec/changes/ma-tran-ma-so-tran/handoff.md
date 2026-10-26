# Handoff: mã trận (`ma-tran-ma-so-tran`)
Cập nhật: 2026-10-26 · bởi: omp · nhánh: `omp/issue-53` · OpenSpec: `ma-tran-ma-so-tran`

## Mục tiêu
Backend trả `matchCode` thô; App chỉ thêm `#` lúc hiển thị, giữ fallback cũ khi thiếu mã và không hiện mã trong overlay livestream. Không đổi DTO, schema hay API.

## Trạng thái
- Hoàn tất hiển thị mã ở bracket, nhãn vòng/trận, Vận hành, lưới lịch, workspace và Excel; dữ liệu/export vẫn giữ mã thô, overlay livestream không hiện mã.
- Mọi lời gọi `crossTableLegTitle` dùng thứ tự `(leg, title)`; nhãn group Ops được chuẩn hóa trước khi dịch.
- Tile trận workspace gọi `localizedMatchLabel(l10n)`, hiện `#DNTB-K1-T3` hoặc fallback `Trận N`; task 2.1 đã cập nhật.
- Review App trước đó tìm thấy P2 về mã lặp và tên group chưa dịch; cả hai đã sửa. Review độc lập mới không thấy finding P0–P3.
- OpenSpec strict validation hợp lệ. Task 3.1 và 4.2 còn mở vì thiếu `app-run.py status` và chưa hoàn tất toàn bộ cổng kiểm chứng.
- Ripwire trên toàn bộ diff chọn 65 test files; đã có kết quả bộ 18 file (152 pass) và các test trọng điểm, chưa chạy phần còn lại. Batch 62 unit/widget test bị dừng theo quy định không chạy test nặng local; 2 `integration_test` cần `app-e2e`.

## Đã thử
| Cách | Kết quả | Bằng chứng |
|---|---|---|
| `flutter test --no-pub test/features/public_bracket_view_test.dart --plain-name 'TC-FEAT-10'` | Đạt | 1 test pass sau khi fixture dùng null-aware entry |
| `flutter test --no-pub test/features/match_code_display_test.dart --plain-name 'TC-FEAT-11'` | Đạt | 1 test pass; nhãn nhánh thua không lặp mã |
| `flutter test --no-pub test/features/dashboard_screen_typed_football_summary_test.dart --plain-name 'TC-FEAT-12'` | Đạt | 1 test pass; test đỏ khi bỏ nhãn mã khỏi tile workspace |
| Bộ 18 test file Ripwire-selected trước khi thêm tile workspace | Đạt | 152 test pass |
| `flutter analyze --no-pub` trên 24 file Dart đã sửa | Chưa xanh | Exit 1 do hai diagnostic `use_null_aware_elements` có sẵn tại `test/features/public_bracket_view_test.dart:47-48`; entry `leg` mới đã dùng `'leg': ?leg` |
| `pnpm dlx @fission-ai/openspec@1.14.2 validate ma-tran-ma-so-tran --strict` | Đạt | `Change 'ma-tran-ma-so-tran' is valid` |
| `python ~/.omp/scripts/app-run.py status` | Không chạy được | File script không tồn tại trong môi trường Linux; chưa có trạng thái `errors` của app dùng chung |
| `ripwire quality_delta` | Có cảnh báo cấu trúc | 51 dòng regression, 51 `preexisting-worse`, 18 gating; không có mục `defect-shape` trong kết quả |

## Ràng buộc đang có
- Backend trả mã không có `#`; App chỉ thêm `#` khi hiển thị; trận CLB/lẻ vẫn không có mã.
- Không đổi shape DTO, schema DB hoặc API; overlay livestream không hiển thị mã.
- Không push Backend, `main` hoặc `staging`; không chạy `flutter run` hay cài App.

## Ràng buộc thay đổi lần này
- Không đổi hợp đồng dữ liệu hay API; thêm mã và fallback vào tile workspace theo proposal.
- Các task kiểm chứng chưa đạt đủ vẫn để `[ ]`, không đánh dấu hoàn tất giả.

## Câu hỏi còn mở
- Cần môi trường có `~/.omp/scripts/app-run.py` để chạy `status`; task 3.1 và 4.2 giữ mở cho tới khi xác nhận app dùng chung và hoàn tất test ảnh hưởng. Cloud `app` target đã biết không tương thích Dart `^3.10.3` (Flutter 3.29.x chỉ có Dart 3.7.2).
