## Why

Sau khi Backend cho phép một người dùng đăng ký nhiều division trong cùng một giải, App vẫn dùng `GET /tournaments/:id/my-registration` như một trạng thái toàn giải. Do đó đăng ký ở một division làm App ẩn form và chặn đăng ký ở mọi division còn lại. Mỗi division phải giữ riêng luồng theo dõi trạng thái đơn hiện có; đăng ký lặp trong cùng division vẫn bị chặn.

## What Changes

- Đọc `GET /tournaments/:id/my-registrations`, phong bì `{ data: Registration[] }`; mỗi phần tử cùng shape với payload hiện tại của `/my-registration`, division ở `participant.tournamentDivisionId`.
- Trong màn đăng ký đơn, tra registration theo division đang chọn: division đã có đơn tiếp tục hiện trạng thái/thanh toán/rút lui; division khác vẫn hiện form; submit ở division đã đăng ký vẫn bị chặn phía client.
- Giữ nguyên `/my-registration` và các luồng đăng ký đôi vốn truy vấn theo division. Không đổi hợp đồng `registerParticipant`, chỉ tiếp tục gửi division đã chọn.
- Thêm test hồi quy có mã TC cho response nhiều division, bảo toàn khóa trùng division và không chặn division khác.

## Out of scope

- Không sửa Backend, Web, D1/D4 hoặc thay đổi chính sách đăng ký phía server.
- Không đổi GET `/tournaments/:id/my-registration` hay luồng trạng thái của division hiện tại.
- Không sửa generated plugin registrants.

## Feature Impact Review

- Màn/route: `TournamentRegisterScreen`; màn đăng ký đôi chỉ được rà để xác nhận khóa division-local hiện hành.
- Vai trò/quyền: người chơi đã xác thực; backend tiếp tục là nguồn chân lý về quyền, trạng thái và duplicate.
- Trạng thái: load nhiều registration; selected division có registration hiện thông tin cũ; division khác cho phép form; lỗi tải danh sách kết thúc loading và backend vẫn kiểm soát submit.
- Nút: division đã đăng ký không cho submit thêm; các division khác giữ hành vi submit hiện có; không ảnh hưởng trạng thái thanh toán/rút lui.
- Ca âm: response rỗng/sai định dạng, lỗi mạng, thiếu quyền, double tap submit, đăng ký đồng thời; lỗi quyền/mạng không được báo như registration thành công và server vẫn enforce invariant.
- Web/App parity: phù hợp contract multi-division của Backend/Web; Web và Backend là owner tương ứng của phần ngoài App.
- Quyết định: `GO_WITH_CONDITIONS` — dựa vào Backend cung cấp endpoint mới và duy trì unique protection theo division; kiểm thử App chưa chạy theo chỉ thị.

## Impact

- App screen: `lib/features/register/screens/tournament_register_screen.dart`.
- Tests: registration screen regression test với TC IDs.
- API contract consumer: chỉ thêm đọc endpoint list; POST register giữ nguyên payload có `divisionId`.
- Verification cần chạy sau handoff: `flutter test --no-pub test/registration/tournament_register_multi_division_test.dart`.