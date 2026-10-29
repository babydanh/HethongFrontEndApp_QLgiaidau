# Design

## D1. Mốc chọn từ danh sách

Hai ô chọn Từ/Đến, giá trị 2.0 → 6.0 bước 0.5 và mục "Không giới hạn" (cùng Web). Giá trị ngoài khoảng đã có sẵn (đặt qua API) vẫn hiển thị đúng bằng cách thêm vào danh sách khi gặp. Chọn Từ lớn hơn Đến thì ô Đến về "Không giới hạn". Mục chỉ hiện khi `_isPickleball` (đã có trong `DivisionEditorSheet`); môn khác không gửi `minDupr`/`maxDupr`.

## D2. Kiểm ở client chỉ để hướng dẫn

Backend là nguồn sự thật. App đọc điểm DUPR của mình theo `categoryId` + `matchType` của nội dung (`TournamentDivisionOption`), chạy `checkDuprAgainstLimit`, khoá nút khi chưa hợp lệ. Điểm có thể đổi giữa lúc kiểm và lúc gửi nên lỗi `DUPR_LIMIT_VIOLATION` vẫn phải hiện ra.

`GET /tournaments/:id/divisions` không trả `categoryId` của nội dung (Backend kiểm DUPR theo `categoryId` cấp giải), nên `categoryId` tra điểm là `division.categoryId ?? tournament.categoryId`; màn cha truyền `categoryId` của giải vào `DuprLimitCard`. Không có category nào thì ẩn thẻ và coi là hợp lệ để Backend quyết định.

## D3. Điểm quốc tế

Repository mới `ExternalRatingRepository` (interface ở `lib/domain/repositories/`, bản API ở `lib/data/repositories/api/`, provider ở `lib/core/di/repository_providers.dart`): `getMyDuprRating(categoryId, matchType) -> double?` (dòng nguồn `API` ưu tiên hơn `SELF`) và `saveMyDuprRating(categoryId, matchType, value)` (PUT, `provider: 'DUPR'`, `isPublic: true`; PUT là upsert nên bấm đúp không tạo dòng thứ hai, nút vẫn tắt khi đang gửi). Hàm chọn dòng là hàm thuần để test.

## D4. Thành phần dùng chung

Một widget `DuprLimitCard` ở `lib/features/register/widgets/` nhận nội dung, tự đọc điểm, tự hiện trạng thái và ô khai, báo trạng thái hợp lệ lên màn cha qua callback `onValidityChanged(bool)`. Màn đăng ký đơn và màn đôi dùng chung; không viết hai lần.

## D5. Lỗi từ Backend

`ErrorParser` hiện lấy `message` của Backend. `DUPR_LIMIT_VIOLATION` mang `message` tiếng Việt nêu khoảng; nếu `ErrorParser` đã trả đúng message đó thì không sửa gì (chỉ thêm test), nếu không thì thêm một nhánh theo `code`. Không đổi xử lý lỗi khác.

## Rủi ro

- `app_vi.arb`/`app_en.arb` bị nhiều lane sửa: chỉ thêm khoá cuối nhóm, không đổi khoá cũ, sinh lại bằng `flutter gen-l10n`.
- Không chạy được app trên máy thật trong phiên apply này: kiểm bằng test đơn vị/widget; xem màn thực tế qua app chung (`app-run.py`) khi người dùng cần.
