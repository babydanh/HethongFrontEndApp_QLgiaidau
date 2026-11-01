## Why

Trang xem trận trực tiếp của App kém Web và các app xem live: video không dính khi cuộn, thẻ tỉ số lớn lặp lại điểm đã có trên video, chat bị giấu ở tab hai, không có số cổ vũ, không chia sẻ, không đi sang giải, không gợi ý trận khác. Thiết kế đã duyệt trên Lavish (`~/.lavish/trang-live-app/thiet-ke-trang-live.html`, bản 3).

## What Changes

- Người xem (không phải trọng tài/BTC, màn dọc): bỏ AppBar, nút Quay lại, nhãn Trực tiếp, Chia sẻ nằm trên khung video.
- Dưới video: tiêu đề "A vs B" + dòng phụ (đang xem · giải · vòng · "Xem thêm"), hàng nút tròn: cổ vũ có số đếm, Chia sẻ, mở giải.
- "Xem thêm" mở tấm "Chi tiết trận" (nội dung tab Tỉ số cũ: set, ELO, luật, địa điểm, thẻ phạt, chi tiết).
- Hai tab: **Chat** (mở sẵn) và **Video khác** (trận đang live/sắp diễn của cùng giải, rồi giải khác; bấm là chuyển sang trận đó).
- Bỏ huy hiệu người xem riêng dưới video (số này nằm ở dòng phụ).

## Out of scope

Báo cáo vi phạm (App chưa có API gửi báo cáo cho trận), toàn màn hình, PiP, chat phủ màn ngang, chat bám đáy và nhãn "tin mới", đa camera, tài trợ (làm ở lượt sau). Màn trọng tài/BTC và màn ngang giữ nguyên. Không đổi Backend/Web.

## Capabilities

### New Capabilities
- `live-viewer-layout`: bố cục người xem trận live: tiêu đề + Xem thêm, nút cổ vũ/chia sẻ/giải, hai tab Chat và Video khác.

### Modified Capabilities

## Impact

`lib/features/match/screens/live_score_screen.dart` (`_buildViewerState`, `build`); mới `lib/features/match/widgets/viewer/live_viewer_header.dart`, `live_viewer_suggestions.dart`; `lib/l10n/app_vi.arb`, `app_en.arb` và code sinh; test `test/features/match/live_viewer_header_test.dart`, `live_viewer_suggestions_test.dart`.
