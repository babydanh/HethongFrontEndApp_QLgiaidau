## Why

Chủ dự án muốn H2H và Bracket phủ trên video **giống hệt giữa Web và App**, đơn lẫn đôi, theo hai ảnh mẫu. Backend đã có `GET /matches/:id/overlay` (OpenSpec `add-live-overlay-view-model`, Backend commit `7451ab1`, **chưa push**) trả dữ liệu dựng sẵn: tên đôi, nhãn vòng tiếng Việt, tối đa 4 cột, điểm = số set, trận đang xem nổi bật.

Overlay hiện có ở App (đọc trên bản sửa dở của checkout chính, xem Điều kiện tiên quyết) vẽ `_buildH2hOverlay` và `_buildBracketOverlay` trong `lib/features/match/screens/live_score_screen.dart` từ `MatchModel`: đôi chỉ hiện `team1Name` và avatar người đầu, Bracket nhóm trận từ `bracketMatchesWithDivisionProvider` không có ô điểm/đường nối, không khung cố định, nhãn vòng suy từ dữ liệu client.

## Điều kiện tiên quyết (CHẶN apply)

**Mã overlay của App chưa nằm trên `origin/main`.** Đã đo: `git grep` `overlay-visibility|h2hOverlayVisible|onOverlayVisibility|setOverlayVisibility` trên `origin/main` (`590876b`) = 0 kết quả; `live_score_screen.dart` ở `origin/main` dài 3.257 dòng và không có `_buildH2hOverlay`/`_buildBracketOverlay`/`liveOverlayToShow`. Mã đó chỉ có ở:
- cây làm việc chưa commit của checkout chính (108 file sửa dở, HEAD chậm `origin/main` 6 commit, `live_score_screen.dart` 3.898 dòng; các file untracked `live_overlay_controls.dart`, `live_overlay_kind.dart`, `overlay_team_name.dart`, `test/api_match_overlay_visibility_test.dart`);
- nhánh cục bộ `snapshot/main-local-20261015` (`78ff410`, "chụp thay đổi local chưa commit") và nhánh `schedule-empty-and-sponsor-tab` (9 commit trước `origin/main`, cũng chứa `live_overlay_controls.dart`); không nhánh nào có bản `origin/`.

Change này **không** mang theo, không gộp, không động tới sửa dở đó. Task 1.1 đo lại: chỉ apply khi hạ tầng overlay (cờ + `overlay:visibility` + `liveOverlayToShow` + nút điều khiển) đã có trên `origin/main`, do người sở hữu nó đưa lên. Nếu chủ dự án muốn change này tự kéo hạ tầng đó vào thì cần quyết định riêng vì phạm vi tăng gấp nhiều lần (xem Impact).

## What Changes

- `MatchRepository` thêm `getMatchOverlay(String matchId)` (GET `/matches/$matchId/overlay`, mẫu `setOverlayVisibility` dùng `DioClient`, đọc phong bì `data`); model `LiveOverlayView` và con (`fromJson` thủ công theo `lib/domain/entities/match.dart`), kiểu có tên, không `dynamic` lan rộng.
- Provider `liveOverlayViewProvider(matchId)` (autoDispose family) chỉ nạp khi có cờ overlay bật: GET lúc bật, lúc nối lại socket, khi `score:update` (debounce ~1 s) và mỗi 30 s; bỏ phản hồi cũ; lỗi thì giữ khung đang hiện.
- Widget mới ở `lib/features/match/widgets/live_overlay/`: `LiveH2hOverlay`, `LiveBracketOverlay`, `LiveOverlayCanvas` (khung cố định + `FittedBox`), `SportoWordmark` (SVG đơn sắc qua `flutter_svg`, đã có trong `pubspec.yaml`; file `assets/images/sporto-wordmark-mono.svg` **chưa có** trong App, task 3.4 tạo mới từ bản đã dò vtracer ở Backend `openspec/changes/add-live-overlay-view-model/assets/`, commit `d39a39c` chưa push; nếu không còn nguồn thì dùng PNG hiện có `assets/images/sporto_v1_with_text.png`). `live_score_screen.dart` chỉ thay hai lời gọi cũ bằng widget mới và xoá các hàm vẽ cũ (`_buildH2hOverlay`, `_h2hVersusBadge`, `_h2hTeam`, `_buildBracketOverlay`, `_bracketRounds`, `_bracketMatchCard`, `_bracketTeamLine`) nếu không còn nơi dùng.
- Vẽ theo mẫu: tiêu đề "ĐỐI ĐẦU", đôi hiện hai avatar chồng nhau, bên 1 viền xanh, bên 2 viền đỏ, "VS"; Bracket tối đa 4 cột, thẻ tên vs tên cộng ô điểm, không mã trận, không seed, nhãn tiếng Việt từ server, thẻ đang xem nổi bật + "ĐANG DIỄN RA", thẻ khác mờ, đường nối sáng.
- Nút Bracket trong điều khiển tắt kèm lý do khi `bracketReason` có giá trị. Provider làm mới chỉ chạy khi overlay bật nên không có `bracketReason` lúc cả hai cờ tắt; vì vậy khi người có quyền mở bảng điều khiển, App gọi `getMatchOverlay` **một lần** chỉ để đọc `bracketReason`. Chưa có dữ liệu hoặc lỗi thì nút vẫn bấm được.

## Out of scope

- Không đổi Backend (change riêng) và Web (change `redesign-live-overlays-web`).
- Không đưa lên `origin/main` các sửa dở của session khác; không sửa logic cờ `overlay:visibility`, `liveOverlayToShow`, nút điều khiển hiện có ngoài phần nêu trên.
- Không hiện thành tích đối đầu, seed, ELO, mã trận; không in đồ hoạ vào luồng AQP.
- Không vẽ vòng bảng/loại kép/tranh hạng ba (server trả `bracket: null` + lý do).
- Không đổi `public_bracket_view.dart` và các màn bracket công khai khác; không thêm package (đã có `flutter_svg`, `google_fonts`, `flutter_animate`).
- Không golden test (repo chưa có hạ tầng golden); kiểm hiển thị bằng widget test + ảnh chụp thiết bị thật.

## Impact

- Phụ thuộc cứng: (1) Backend `GET /matches/:id/overlay` đã deploy; (2) hạ tầng overlay App đã vào `origin/main`. Thiếu một trong hai thì DỪNG.
- Đổi hành vi: tên đôi và nhãn vòng từ server thay cho dữ liệu client; ô điểm mới; khung cố định co đều (ngoại lệ có chủ đích của luật "không kích thước cứng": giữ đúng tỉ lệ mẫu; `FittedBox` thu nhỏ khi video nhỏ).
- `LiveVideoBox` luôn `AspectRatio 16/9` nhưng player thật có thể đổi tỉ lệ sau khi đọc metadata; khung overlay độc lập tỉ lệ video, lấy bề rộng khung chứa làm chuẩn co.
- Tệp: `lib/domain/entities/live_overlay_view.dart` (mới), `lib/domain/repositories/match_repository.dart`, `lib/data/repositories/api/api_match_repository.dart`, `lib/providers/query_providers.dart`, `lib/features/match/widgets/live_overlay/*` (mới), `lib/features/match/screens/live_score_screen.dart`, `lib/l10n/app_vi.arb` + `app_en.arb`, `test/features/match/live_overlay/*` (mới), `test/fixtures/overlay/*.json` (chép từ Backend).
- Rủi ro: `live_score_screen.dart` đang bị sửa dở ở checkout chính và nhánh khác; phải rebase lên `origin/main` ngay trước khi apply và chỉ commit hẹp file của change này.
