## 1. Điều kiện tiên quyết và đối chiếu

- [ ] 1.1 Xác nhận hạ tầng overlay App đã có trên `origin/main`: `git grep -n -E "setOverlayVisibility|onOverlayVisibility|liveOverlayToShow" origin/main -- lib` phải có kết quả, và `live_score_screen.dart` có `_buildH2hOverlay`/`_buildBracketOverlay`. Xong khi: có kết quả; nếu = 0 thì DỪNG toàn bộ change (xem proposal "Điều kiện tiên quyết"); nếu có thì đo lại số dòng các hàm vẽ cũ.
- [ ] 1.2 Xác nhận Backend `GET /matches/:id/overlay` đã deploy và trả đúng hợp đồng (một trận đơn, một trận đôi). Xong khi: lưu phản hồi đã che dữ liệu cá nhân; nếu chưa thì DỪNG phần 3-5.
- [ ] 1.3 Chép fixture Backend `test/fixtures/overlay/*.json` vào App `test/fixtures/overlay/`. Xong khi: 3 file khớp byte với Backend.
- [ ] 1.4 Ghi baseline: `flutter analyze --no-pub lib/features/match lib/domain lib/data lib/providers` và `flutter test --no-pub` cho các test overlay hiện có. Xong khi: số lỗi/pass trước khi sửa được ghi lại để so sau.

## 2. Model, repository, provider (test viết trước, đỏ đúng lý do)

- [ ] 2.1 `LiveOverlayView` + con, `fromJson` thủ công, test parse cả 3 fixture, dòng `name` null, `bracket` null kèm `bracketReason`, thiếu `data`. Xong khi: test đỏ trước (model chưa có), xanh sau.
- [ ] 2.2 `getMatchOverlay` ở `MatchRepository` + `ApiMatchRepository`, test bằng Dio giả: đường dẫn, gỡ phong bì `data`, lỗi thiếu `data`, 404. Xong khi: test pass.
- [ ] 2.3 `OverlayRefreshScheduler` + provider: không gọi khi tắt, gọi khi bật, debounce `score:update` 1 s, 30 s, bỏ phản hồi cũ, giữ khung khi lỗi, huỷ khi dispose. Xong khi: cả 6 hành vi có test; thử phá (bỏ kiểm số thứ tự) làm đúng 1 test đỏ.

## 3. Widget (đọc fixture, không gọi mạng)

- [ ] 3.1 `LiveOverlayCanvas` (`FittedBox`) + test ở 320/390/768 không `FlutterError`. Xong khi: test pass.
- [ ] 3.2 `LiveH2hOverlay`: đơn, đôi (hai avatar chồng), `note`, `round` null, ảnh lỗi → chữ cái đầu, "ĐỐI ĐẦU", không seed/ELO. Xong khi: widget test cho từng tình huống pass.
- [ ] 3.3 `LiveBracketOverlay`: tối đa 4 cột, ô điểm, thẻ `live` + "ĐANG DIỄN RA", đường nối `litNext`, cúp cột chung kết, "Chờ kết quả", "BYE", không seed/mã trận. Xong khi: widget test cho 3 fixture pass; `grep` không còn "seed", "QF", "WIN", "HEAD TO HEAD" trong thư mục `live_overlay/`.
- [ ] 3.4 Logo SVG + token + animation (D6-D8). Xong khi: đọc mã thấy hằng số thời lượng/đường cong đúng, không `linear`/`easeInOut`.

## 4. Nối vào màn hình

- [ ] 4.1 `live_score_screen.dart` dùng widget mới; xoá hàm vẽ cũ và import chỉ dùng cho chúng. Xong khi: `flutter analyze --no-pub lib/features/match` không thêm lỗi, `grep` các tên hàm cũ = 0.
- [ ] 4.2 Nút Bracket tắt kèm lý do khi `bracketReason` có giá trị. Xong khi: widget test cho nút ở hai trạng thái.

## 5. i18n và kiểm chứng

- [ ] 5.1 Khoá mới ở `app_vi.arb` và `app_en.arb` cùng tên, `flutter gen-l10n` chạy sạch (không sửa tay `app_localizations*.dart`). Xong khi: gen-l10n exit 0 và hai file có đúng cùng bộ khoá.
- [ ] 5.2 Ảnh chụp thiết bị/giả lập thật cho H2H đơn, H2H đôi, Bracket 4 cột ở màn hẹp (nếu `adb devices` rỗng thì nhắc chủ dự án cắm điện thoại, không tự dựng máy ảo). Xong khi: ảnh được xem và so với hai ảnh mẫu, ghi lệch/không lệch; hoặc ghi rõ "chưa chụp".
- [ ] 5.3 `flutter analyze --no-pub` trên đúng thư mục đã sửa và `flutter test --no-pub` các file test của change. Xong khi: không thêm lỗi so với baseline 1.4. Bộ test đầy đủ không chạy cục bộ (máy yếu, `AGENTS.md`).
- [ ] 5.4 `openspec validate redesign-live-overlays-app --strict` và `openspec-gate.py`. Xong khi: cả hai exit 0.
