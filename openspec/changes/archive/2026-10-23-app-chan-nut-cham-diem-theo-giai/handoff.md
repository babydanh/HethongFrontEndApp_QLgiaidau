# Handoff: app-chan-nut-cham-diem-theo-giai
Cập nhật: 2026-10-23 · bởi: claude · nhánh: app-chan-nut-cham-diem-theo-giai · OpenSpec: app-chan-nut-cham-diem-theo-giai

## Mục tiêu
Màn App "Chi Tiết Trận Đấu": chỉ chủ giải, trọng tài gán đúng trận, hoặc người được backend `score-access` cho phép mới thấy nút chấm điểm (ADMIN giải khác không); khung video chưa có tín hiệu giữ 16:9. Xem `proposal.md`.

## Trạng thái
- Xong (code): 1.1 `canControlTournamentLive`, 1.2 `matchScoreAccessProvider` + nối `live_score_screen.dart`, 2.1 `_NoSignalBox` AspectRatio 16/9 (cùng hunk với `94933d67` của lane scrcpy).
- Chưa có bằng chứng chạy local: ổ V: còn ~8 GB nên hook activity-ledger chặn test/analyze/format ở máy. Kiểm bằng cloud (`merge-lane` chạy target app: analyze + test).
- Tiếp theo: xem kết quả cloud; đỏ thì sửa theo log, xanh thì gộp, rồi `openspec archive app-chan-nut-cham-diem-theo-giai`.

## Đã thử
| Cách | Kết quả | Vì sao / bằng chứng |
|---|---|---|
| Chạy test local cho test mới | bỏ dở | hook chặn khi ổ < 10 GB |
| Lấy commit `94933d67` của lane scrcpy | thành công (chỉ 2 hunk video box + test) | lane scrcpy còn bị chặn vì xung đột `ParticipantLabel` |

## Ràng buộc đang có
- Super Lite: mọi người đăng nhập vẫn chấm được; trận đã kết thúc không có nút chấm (nguồn: spec `live-score-access`).
- Referee đăng nhập bằng token giải không có hồ sơ người dùng: giữ quyền cho đúng giải trong token (`isTokenReferee`) để không làm lùi hành vi cũ.
- `score-access` lỗi/đang tải = ẩn nút (trừ các nhánh trên).

## Ràng buộc thay đổi lần này
- Thêm: nhánh `isTokenReferee` cho trọng tài token giải.
- Hoặc: còn lại không đổi (đã so).

## Câu hỏi còn mở
- "Lỗi video" của người dùng được hiểu là khung no-signal co thấp; nếu thực tế là lỗi khác cần ảnh/log.
