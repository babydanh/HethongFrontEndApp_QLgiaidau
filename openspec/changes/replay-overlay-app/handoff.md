# Handoff: replay-overlay-app

## Mục tiêu
Khi App phát lại bản ghi, H2H và Sơ đồ đấu hiện đúng theo giây video (đọc `overlayEvents` của `GET /livestream/matches/{matchId}/replay`), thay vì theo cờ server của thời điểm live.

## Trạng thái
- Xong và test xanh: task 1.1, 1.2, 2.1, 2.2 (TC-REPLAYOV-01..14).
- Review `flutter-reviewer`: GỘP ĐƯỢC; đã sửa P2 dismiss rò giữa live và replay (reset khi đổi chế độ, listener cờ server bỏ qua khi đang replay).
- Chưa làm: 3.2 (thử máy thật trên trận sau `d0445b04`, cần người cầm máy). 3.1 (review) chạy riêng, xem phần dưới.
- Chưa push, chưa gộp. Chờ người dùng nói "lên staging" / "lên main".

## Đã thử (cách → kết quả → vì sao)
- Báo `null` từ player khi dispose để thoát chế độ phát lại → bỏ → notify trong dispose gây assert "tree locked". Chế độ phát lại suy ra từ `matchPlaybackProvider`/`matchReplayProvider`.
- `--no-test-assets` khi chạy flutter test → bỏ → thiếu shader ripple, test hỏng.
- Test 12 ban đầu bấm nút tua lần hai → trượt vì Sơ đồ phủ nút giữa → đổi sang bấm cuối thanh timeline.

## Ràng buộc đang có
- Overlay không nằm trong file MP4; App vẽ lại từ sự kiện bật/tắt theo giây nguyên (trễ dưới 1 giây chấp nhận được).
- Trận trước `d0445b04` không có sự kiện → replay không hiện overlay (có chủ đích).
- Sửa `live_score_screen.dart` tránh vùng import dòng ~20 và class State ~754/764 (lane `app-staff-score-button` đang sửa).

## Thay đổi lần này so với ràng buộc cũ
- Thiết kế ban đầu dùng `ValueChanged<int?>` với null báo thoát phát lại → đổi thành `ValueChanged<int>` + suy ra từ provider.

## Câu hỏi mở
- Trọng tài/admin xem bản ghi: menu bật/tắt H2H/Sơ đồ chỉ đổi cờ server (cho live), hình bản ghi vẫn theo sự kiện nên nút trông như không tác dụng. Review (P2) gợi ý ẩn mục menu khi đang phát lại; chưa làm vì là quyết định hành vi.
- Nút X ẩn panel: hiện reset khi loại overlay tại giây đó đổi (kể cả khi tua). Nếu muốn X giữ đến hết bản ghi thì sửa `_onReplayPosition`.
