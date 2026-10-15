## Context

Hợp đồng `GET /matches/:id/overlay` (Backend `add-live-overlay-view-model`):

```
data = { h2hVisible, bracketVisible,
  h2h:     { title:'ĐỐI ĐẦU', round:string|null, left:Side, right:Side } | null,
  bracket: { title, sport, columns:[{ title, cards:[{ id, final, live, litNext, nextId,
             rows:[{name|null, note|null, score|null, won}, {…}] }] }] } | null,
  bracketReason: string|null }
Side = { name, note|null, avatars:[{url|null, initial}] }
```

Socket `overlay:visibility` là `JSON.stringify(object)` một lớp chứa `id`, `matchId` và đủ hai cờ (Backend `live-score.gateway.ts:439-447`, đã đọc). Parser hiện có trong `match_socket_service.dart` giải mã một lớp rồi trả `Map` — đủ dùng.

Hạ tầng cờ của App (nghe socket, `copyWith`, `liveOverlayToShow`, nút điều khiển) **chưa nằm trên `origin/main`** (xem proposal). Mô tả dưới đây dựa trên bản sửa dở đã đọc; **số dòng phải đo lại** ở task 1.1.

## Decisions

**D1. Giữ nguyên cờ, thay phần vẽ.** Cờ ban đầu từ `MatchModel.h2hOverlayVisible/bracketOverlayVisible`, cập nhật qua `onOverlayVisibility` → `copyWith` (đọc ở `api_match_repository.dart` bản sửa dở, listener lọc `matchId ?? id`). Change này **không** sửa luồng đó.

**D2. Một phương thức repository mới**, `getMatchOverlay`, theo mẫu `setOverlayVisibility` (DioClient, phong bì `data`). Model `LiveOverlayView` trong `lib/domain/entities/live_overlay_view.dart`, `fromJson` thủ công như `match.dart` (repo không dùng Freezed). Phản hồi thiếu `data` hoặc sai kiểu → ném lỗi có tên, provider bắt và giữ khung cũ.

**D3. Provider tự quản làm mới.** `liveOverlayViewProvider` là `AsyncNotifier`/`StreamProvider.autoDispose.family` theo `matchId`, chỉ hoạt động khi widget gọi `ref.watch` (tức khi có overlay bật). Bên trong: số thứ tự yêu cầu tăng dần, bỏ phản hồi không phải mới nhất; `Timer.periodic(30s)`; debounce 1 s cho `score:update`; `ref.onDispose` huỷ timer. Tách thành lớp thuần `OverlayRefreshScheduler` nhận hàm fetch và bộ tạo `Timer` có thể tiêm. Test dùng `testWidgets` và `tester.pump(Duration)` (đã chạy trong vùng thời gian giả của `flutter_test`) nên không thêm package: `fake_async` không có trong `pubspec.yaml` và `AGENTS.md` cấm thêm package khi không được yêu cầu.

**D3b. Lý do tắt nút Bracket.** Provider ở D3 chỉ hoạt động khi overlay bật nên không cung cấp `bracketReason` lúc cả hai cờ tắt (lúc BTC cần bấm). Khi người có quyền mở bảng điều khiển, App gọi `getMatchOverlay` một lần (không qua scheduler) và chỉ dùng `bracketReason`. Chưa có phản hồi hoặc lỗi thì nút Bracket vẫn bấm được (Backend vẫn nhận PATCH; thiếu thông tin không được chặn người điều khiển). Nút điều khiển hiện chưa có trên `origin/main` (xem proposal), nên chi tiết nối vào nút phải đo lại ở task 1.1.

**D4. Khung cố định co đều.** `LiveOverlayCanvas({required Size design, required Widget child})` = `LayoutBuilder` + `FittedBox(fit: BoxFit.contain)` bọc `SizedBox(design.width, design.height)`. Bề rộng lấy từ ràng buộc của khung chứa (không từ tỉ lệ player). H2H 1320×225, Bracket 1568×882. Chữ nhỏ nhất sau co ≥ 9 logical px (kiểm bằng phép tính khi video 320 px; thấp hơn thì chấp nhận thu nhỏ tổng thể). Ngoại lệ có chủ đích của luật "không kích thước cứng": giữ đúng tỉ lệ ảnh mẫu.

**D5. Tách file.** Hàm vẽ cũ là phương thức private của `_LiveScoreScreenState` dùng `context`, `ref`, `_effectiveTournamentId`, localization; không chuyển nguyên được. Widget mới là `ConsumerWidget` nhận `matchId` và callback đóng; chúng không đọc state của màn hình. `live_score_screen.dart` chỉ còn: chọn `LiveOverlayKind` (hạ tầng sẵn có) → dựng widget mới trong `Stack`/`AnimatedSwitcher`/`_withCloseButton` hiện có. Hàm vẽ cũ và import chỉ dùng cho chúng bị xoá (dọn nhánh thay thế, không để đường cũ).

**D6. Theme và chữ.** Màu panel/nhấn lấy từ token ở `app_theme.dart` khi có đúng token (nhấn xanh `AppTheme.primary`); các màu đặc thù overlay (nền `#0B1F44`~88%, bên đỏ `#E5484D`, khung tên trắng→`#D5E2F6`) là hằng số trong một file `live_overlay_tokens.dart` — ước lượng bằng mắt từ ảnh mẫu, chưa đo pixel. Chữ `GoogleFonts.inter` trọng 800/900. Overlay luôn tối trên video nên KHÔNG đổi theo light/dark của app.

**D7. Logo.** `SvgPicture.asset` đơn sắc từ `assets/images/sporto-wordmark-mono.svg`, `colorFilter` trắng. File này **chưa có trong App** (thư mục `assets/images/` hiện chỉ có `sporto.svg`, `sporto_v1.svg`, `sporto_v1_with_text.svg` và các PNG); task 3.4 tạo mới từ bản đã dò vtracer, nguồn hiện ở Backend `openspec/changes/add-live-overlay-view-model/assets/` (commit `d39a39c`, chưa push; không có `assets/` ở gốc Backend; sau archive chuyển vào `openspec/changes/archive/`). `assets/images/` đã khai báo trong `pubspec.yaml` nên không sửa `pubspec.yaml`. Chưa kiểm `flutter_svg` hiển thị SVG nhiều path này đúng; task 5.2 chụp ảnh. Nếu lệch hoặc không còn nguồn thì lùi về PNG `assets/images/sporto_v1_with_text.png` kèm `ColorFiltered` (chấp nhận mất đơn sắc).

**D8. Animation.** `flutter_animate`: vào 200–260 ms `Curves.easeOutCubic`, ra 160 ms, so le 40 ms giữa các thẻ bracket, tôn trọng `MediaQuery.disableAnimations`. Không `Curves.linear`/`easeInOut`.

**D9. Test.** Test widget (`testWidgets`, host `ProviderScope` + `MaterialApp` + `AppTheme.lightTheme` + localization) cho từng fixture chép từ Backend, đọc bằng `File('test/fixtures/overlay/…').readAsStringSync()`; chọn một test widget có thật trên `origin/main` làm mẫu ở task 1.1 (các mẫu cũ `public_bracket_view_test.dart`, `live_overlay_controls_test.dart` chỉ có trong sửa dở, chưa có trên `origin/main`). Kiểm: chữ hiển thị đúng, không có seed/mã trận, hai avatar đôi, thẻ `live` có nhãn, không `FlutterError` overflow ở 320/390/768. Test repository dùng Dio/interceptor giả như `test/api_match_repository_search_test.dart` (có trên `origin/main`).

## Alternatives đã loại

- Dùng lại `bracketMatchesWithDivisionProvider` rồi dựng tên/vòng ở client: payload không có tên vòng, member không avatar, không lọc roster → sai tên đôi; hai app sẽ lệch nhau.
- `flutter_screenutil` (`.w/.sp`): không có trong `pubspec.yaml`, thêm package không được yêu cầu; `FittedBox` đủ.
- Golden test: repo chưa có hạ tầng; ảnh golden phụ thuộc font tải qua mạng (`google_fonts`) nên không ổn định.

## Risks / Trade-offs

- **Chặn bởi hạ tầng overlay chưa lên `origin/main`.** Nếu chủ dự án không muốn đợi, cần change riêng đưa hạ tầng đó lên; không gộp vào đây.
- **Backend chưa deploy** → GET lỗi, overlay không hiện, nhưng màn hình không vỡ (giữ nguyên hoặc ẩn).
- **`live_score_screen.dart` rất lớn và đang bị sửa ở nơi khác**: xung đột ở dòng gần nhau; rebase ngay trước apply, commit hẹp, cổng `merge-lane` phân loại xung đột.
- **Font `google_fonts` tải qua mạng** có thể cho chữ khác lúc đầu; ngoài phạm vi, ghi nhận khi chụp ảnh.
- **Poll 30 giây**: Backend cache 3 giây theo trận, chi phí thấp; chu kỳ là một hằng số duy nhất.
