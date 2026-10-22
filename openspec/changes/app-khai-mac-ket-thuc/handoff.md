# Handoff: thanh-tien-trinh-gon (App)
<!-- Đọc file này TRƯỚC khi làm tiếp nhánh. Cập nhật TRƯỚC khi báo xong, fast-handoff, hoặc hết phiên. -->
Cập nhật: 2026-10-22 18:39 · bởi: omp · nhánh: thanh-tien-trinh-gon · OpenSpec: app-khai-mac-ket-thuc

## Mục tiêu
Đưa App theo cùng hợp đồng khai mạc: `REGISTRATION_OPEN` luôn chốt đăng ký trước; `REGISTRATION_CLOSED` mới có nút khai mạc và cảnh báo khóa mọi division; App chỉ gọi `startTournament`. Chi tiết tại OpenSpec và task 3.5 của Web.

## Trạng thái
- Xong phần code: lifecycle card và xác nhận đã bỏ ô tick/luồng đóng trước `start`; helper `_start` chỉ chuyển tiếp đã được inlining; ARB vi/en và mã sinh đã cập nhật; `REGISTRATION_OPEN` luôn hiện “Chốt đăng ký”; test `TC-APP-LIFECYCLE-07` đã sửa theo luật mới.
- Xong phần OpenSpec: requirement App ghi cảnh báo khóa mọi division, chỉ gọi `/start`, và không cho khai mạc khi còn đăng ký mở; task 2.4 ghi nhận hợp đồng mới nhưng chưa tick vì cloud test chưa chạy.
- `flutter gen-l10n` đã chạy theo cấu hình `l10n.yaml`. `dart format` chạy đúng ba file Dart đã đổi; formatter gây churn ở các dòng cũ, phần định dạng ngoài thay đổi đã được khôi phục.
- `dart analyze lib/features/tournament/screens/tournament_management_section_screen.dart lib/features/tournament/screens/tournament_management_widgets.dart test/features/tournament_management_hub_screen_test.dart` exit 3, 1.728 lỗi vì không phân giải package Flutter/Dio/nội bộ; không cài dependencies. Không chạy Flutter test local.
- Git: branch không có upstream và chưa có ref `origin/thanh-tien-trinh-gon`; 9 commit ngoài `origin/main` là ancestry của nhánh hiện tại, không phải commit của session. Các thay đổi hiện tại chưa commit/push.
- Chưa xong: cloud App test và `openspec validate --strict` chưa chạy; `/home/runner/.omp/scripts/cloud-test-runner.py` và CLI OpenSpec không khả dụng theo lần kiểm trước.
- Tiếp theo: khi cloud runner khả dụng, chạy `cloud-test-runner.py run --target app --branch thanh-tien-trinh-gon`; validate strict rồi cập nhật task 2.4 bằng kết quả thật.

## Đã thử
| Cách | Kết quả | Vì sao / bằng chứng |
|---|---|---|
| `flutter gen-l10n` | Hoàn tất với thông báo dùng `l10n.yaml` | ARB vi/en sinh ra cùng getters mới |
| `dart format lib/features/tournament/screens/tournament_management_section_screen.dart lib/features/tournament/screens/tournament_management_widgets.dart test/features/tournament_management_hub_screen_test.dart` | Chạy xong; formatter báo 2 file được định dạng | Có cảnh báo không resolve `flutter_lints`; đã đảo lại churn ngoài phạm vi, giữ style gốc |
| `dart analyze` ba file đổi | Thất bại môi trường, exit 3, 1.728 chẩn đoán | `package:flutter/material.dart`, `flutter_riverpod`, `dio` và imports nội bộ không resolve |
| Flutter widget test / App cloud test / strict validate | Chưa chạy | Flutter test local bị cấm; cloud runner và OpenSpec CLI không khả dụng |

## Ràng buộc đang có
- Chỉ sửa worktree App nhánh `thanh-tien-trinh-gon` tại `HethongFrontEndApp_QLgiaidau.worktrees/thanh-tien-trinh-gon`.
- Không sửa worktree App `app-khai-mac-ket-thuc`; worktree đó đã sạch sau khi đảo riêng thay đổi session.
- Không chạy Flutter test local; dùng cloud runner khi khả dụng.
- Giữ `registrationOpen` do Backend trả về cho division; start chỉ gọi API hiện có `/tournaments/:id/start`.

## Ràng buộc thay đổi lần này
- Thêm: cảnh báo khai mạc khóa đăng ký mọi division, có bản dịch Việt/Anh; OpenSpec phản ánh hành vi mới.
- Bỏ: ô tick “Chốt đăng ký các nội dung còn mở luôn”, tham số tùy chọn của hộp xác nhận và helper `_start` chuyển tiếp.
- Không đổi: quyền mở lại riêng division sau khai mạc; đã so với requirement App hiện có.

## Câu hỏi còn mở
- Không có câu hỏi nghiệp vụ; còn chờ runner, dependencies được cung cấp qua quy trình và strict validation.
