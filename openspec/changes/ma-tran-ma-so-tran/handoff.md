# Handoff: mã trận (ma-tran-ma-so-tran)
Cập nhật: 2026-10-26 23:00 · bởi: claude · nhánh: ma-tran · OpenSpec: ma-tran-ma-so-tran

## Mục tiêu
Mỗi trận có mã `<mã nội dung><chữ nhánh><vòng>T<số trận>` (vd `DN1W2T3`) để gọi đúng một trận. Backend tính và trả `matchCode` (không thêm cột DB); Web/App ghép tên tắt 2 bên (chữ đầu 2 từ cuối). Overlay livestream KHÔNG hiện mã. Chi tiết: `proposal.md`, `design.md`, `specs/`.

## Trạng thái
- Xong: `matchCode` ở `MatchModel`/`TournamentAssignedMatch`, `lib/core/utils/match_code.dart`, hiển thị ở bracket row, ops, lưới lịch, Excel. Commit `2100a04d`…`016ce342`. `flutter test --no-pub` 4 file exit 0 (39 test), `flutter analyze --no-pub` exit 0. `flutter-reviewer` + `reviewer` GỘP ĐƯỢC.
- Đang dở: chưa đo thật ở 320dp (footer đã bọc `Flexible`) và chưa chạy `app-run.py status`.
- Tiếp theo: xác nhận spec cho nhánh `grand_final`/`losers` và round-robin có groupName (đang không hiện mã).

## Đã thử
| Cách | Kết quả | Vì sao / bằng chứng |
|---|---|---|
| Tên `José Núñez Çelik` | đỏ rồi xanh | trước sửa ra `NE` thay vì `NC`; thêm Latin-1 vào `_accentedLetters` |

P3 còn ghi: `tournament_workspace.dart:108-115` `localizedMatchLabel` tách `' / '` và không màn nào gọi `matchLabel`; `match_table_row.dart:98-101` nhánh `grand_final`/`losers` và `organizer_ops_screen.dart:3784-3792` không hiện mã; `match_round_label.dart:324` chuỗi cứng "Trận ${match.matchNumber}" chưa l10n; `MatchModel.copyWith` không đặt về null (cố ý); thiếu widget test overflow 320dp/`textScaler` 1.3.
Working tree có file sinh tự động (`generated_plugin_registrant.*`…) do flutter tooling, không phải của việc này, không `git add`.

## Ràng buộc đang có
- Chưa push, chưa lên staging/main; người dùng chưa cho phép (nguồn: CLAUDE.md Git).
- Backend gộp trước Web/App; không đổi trường cũ của DTO; trận câu lạc bộ/lẻ luôn `matchCode: null`; thiếu mã thì Web/App về "Trận #n"/"Trận N" cũ (nguồn: người dùng duyệt thiết kế).
- Tên tắt: Web và App đồng bộ fold dấu Latin-1 + tiếng Việt; vector test chung (`Éric Müller`→EM, `José Núñez Çelik`→NC).
- Không chạy Playwright E2E và test Postgres trên máy này; chạy qua `cloud-test-runner` (cần nhánh đã push).

## Ràng buộc thay đổi lần này
không đổi (đã so)

## Câu hỏi còn mở
- Cho phép push nhánh `ma-tran` (3 repo) để chạy spec tích hợp Postgres (Backend 3.1) và E2E qua cloud không?
- Có cần chạy `node scripts/sync-api-clients.js` sau khi gộp Backend không `[SUY LUẬN]` (chưa kiểm)?
