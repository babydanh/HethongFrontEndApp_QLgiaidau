## Why

Trên màn xem trực tiếp của App, bảng điểm đè lên chữ "Chưa phát trực tiếp", còn tab "Video khác" chỉ là danh sách trận lấy từ sơ đồ giải, nút lọc xấu và thiếu so với Web. Web có khung "Video gợi ý" lấy từ Backend (`GET /livestream/matches/:matchId/suggestions`): trận đang live và trận có bản ghi phát lại, lọc Tất cả / Đang live / Phát lại / Cùng giải, thẻ thumbnail có điểm và thời lượng, tải thêm khi cuộn.

## What Changes

- Thanh header của người xem (dọc) nằm trên hình video thay vì đè lên nó; bảng điểm bám góc trên trái của hình video. Toàn màn hình ngang (header buộc phải đè video) thì bảng điểm hạ xuống dưới header.
- Tab "Video khác" dùng đúng API `suggestions` như Web (phân trang cursor), thay cho danh sách trận từ sơ đồ giải.
- Bốn nút lọc dạng viên thuốc như Web: Tất cả (nền tối khi chọn), Đang live, Phát lại, Cùng giải.
- Thẻ như Web: thumbnail 16:9 màu theo giải có vạch sân, chấm LIVE hoặc thời lượng, điểm; bên phải tên hai bên, "giải · vòng", nhãn "Phát lại".
- Luật gợi ý như Web: trận live luôn hiện, bản phát lại phải dài ít nhất 180 giây.
- Nút nhập điểm giữ nguyên là icon trên header, không thêm nút mới.

## Out of scope

- Không đổi Backend (endpoint đã có sẵn, công khai, không cần đăng nhập).
- Không làm tự làm mới 30 giây như Web; App tải lại khi mở tab.
- Không đổi bố cục màn điều khiển của trọng tài.

## Capabilities

### New Capabilities

### Modified Capabilities
- `live-viewer`: vị trí bảng điểm của người xem và danh sách "Video khác".

## Impact

- `lib/features/match/screens/live_score_screen.dart`, `lib/features/match/widgets/viewer/live_viewer_suggestions.dart`.
- Thêm `lib/data/models/match_suggestion_model.dart`; thêm `getMatchSuggestions` vào `IMatchPlaybackRepository` / `ApiMatchPlaybackRepository`.
- `lib/l10n/app_vi.arb`, `app_en.arb` (+ file sinh bởi `flutter gen-l10n`).
- Test: `test/match/live_score_header_scoring_test.dart`, `test/features/match/live_viewer_suggestions_test.dart`, `test/match/match_replay_live_video_box_test.dart` (fake).
