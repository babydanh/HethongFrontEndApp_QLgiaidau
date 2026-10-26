# Design — quan-ly-giai-web-parity

## Ngữ cảnh

Nguồn chuẩn chức năng là Web `V:/Duancanhan/Project_QuanLyGiaiDau/HethongFrontEndWeb_QLgiaidau`:
- `src/app/organizer/tournaments/[id]/manage/page.tsx` (3971 dòng) + `components/useManageState.ts` (3362 dòng): vòng đời, hạng mục, đăng ký, quick-edit.
- `components/CreateDivisionModal.tsx`, `RegistrationTab.tsx` (2159 dòng), `BracketSetupModal.tsx`, `CourtScheduleBoard.tsx` (6868 dòng), `LivestreamTab.tsx`, `OpsMatches.tsx`.
- Hợp đồng HTTP thật: repo Backend `src/modules/<feature>/*.controller.ts` (docs/README.md:18) — đối chiếu từng route TRƯỚC khi viết repository App, không bía trường.

Phiên bản App nhận thay đổi: hub quản lý `tournament_management_*` + `organizer_ops_screen.dart` (đã có kéo-thả lưới, bản nháp xếp tự động, 7 thao tác trận đặc biệt, thêm VĐV 2 tab, import Excel có preview server + Idempotency-Key — giữ nguyên, chỉ bổ sung).

## Quyết định

1. **Chuẩn popup = bottom sheet của App, chức năng khớp Web 1-1** (chốt người dùng): sheet 92% màn hình cho form ≥5 trường (`showModalBottomSheet(isScrollControlled: true, showDragHandle: true)` + `FractionallySizedBox 0.92` + `ConstrainedBox 640`), `AlertDialog` chỉ cho xác nhận nhanh/form ≤4 trường. Mọi sheet mới dùng khung chung `TournamentManageSheet` (mới, ~150 dòng): tiêu đề + thân cuộn + thanh thao tác sticky + cờ `busy` (spinner trong nút, chống double-tap) + `PopScope(canPop: !busy)` + padding `viewInsets.bottom`. KHÔNG copy bố cục 2 cột của Web.
2. **Validate dịch đúng luật Web**: cùng trường bắt buộc, cùng khoảng (thời lượng 15–240 phút bội 5, ELO min ≤ max, VĐV ảo tối đa theo sức chứa, wildcard bắt buộc email + tên đội, lý do kick ≥5 ký tự...). Lỗi server hiển thị nguyên văn qua `ErrorParser.parse` như hiện có.
3. **Vòng đời**: khai mạc — nếu còn hạng mục mở thì sheet liệt kê từng hạng mục với toggle "đóng đăng ký" (mặc định đóng hết, tương đương checkbox Web nhưng rõ hơn trên mobile), các cảnh báo (`openingWarnings` tương đương: hạng mục chưa có sơ đồ, VĐV chờ duyệt) hiển thị trước nút xác nhận; gửi `close-registration` (body `divisionIds` của các hạng mục chọn đóng) rồi `POST /start`. Kết thúc — sheet checklist: "trận đã xong X/Y", danh sách trận LIVE (chặn nút, như `endChecklist` Web), hạng mục còn trận chưa xong; **bỏ hạn chế chỉ admin** (`_canFinalizeTournament`) để organizer cũng kết thúc được — Web cho phép, backend vẫn kiểm quyền. Prompt hạng mục đủ chỗ: khi `registered >= capacity` của hạng mục đang mở, hiện sheet đề nghị "Đóng đăng ký / Giữ mở", ghi nhớ đã hỏi bằng state trong phiên màn (không persist).
4. **Hạng mục**: một sheet duy nhất cho tạo + sửa, bố cục cuộn theo phần (Nhận dạng → Thể thức → Giới hạn → Luật theo môn → Vòng bảng/Swiss), tái dùng `SwissConfigEditor` hiện có; preset theo môn port từ `getSportRulePresets` của Web thành helper Dart thuần (không gọi API). Sheet cấu hình từng vòng: chọn vòng của stage (khi bracket đã sinh), sửa sân/giờ mặc định/luật → `PATCH /tournaments/stages/:stageId` (Web `handleSaveStageDetails`).
5. **Ghép cặp**: sheet thủ công dùng `ReorderableListView`/`LongPressDraggable` (không thêm package — Flutter core có đủ): thả VĐV này lên VĐV khác để thành cặp (như dnd-kit Web), xáo trộn Fisher-Yates, TextField tên cặp, tối đa 24; submit `POST /pairing/batch`. Tự động: 3 radio RANDOM/ELO_BALANCED/SAME_LEVEL → `POST /pairing/generate`. Tách cặp từ menu dòng VĐV (confirm) → `POST /pairing/:pid/unpair`.
6. **Lịch**: cascade = client tính giờ kết thúc của ô được chọn rồi xếp nối tiếp (port logic `court-schedule-cascade.ts` của Web sang Dart util, có test riêng). Khay chưa xếp nâng cấp: checkbox chọn nhiều + chọn sân đích + khung giờ bắt đầu → ghi tuần tự (giữ báo "đã ghi i/n" như áp bản nháp hiện có). Editor khung giờ: giờ mở/đóng + bước ô (5/10/15/30/60) lưu vào `scheduleSettings` qua config giải (đối chiếu route Web dùng trước khi làm). Xung đột VĐV: util Dart tính từ danh sách trận đã xếp (port `scheduleConflicts`), hiện sheet cảnh báo sau mỗi thao tác ghi nếu có. AI lịch: sheet textarea lệnh chữ → `POST /ai/tournaments/:id/schedule-preview` → hiển thị kế hoạch như bản nháp (dùng lại draft bar) → áp dụng tuần tự.
7. **Livestream camera**: gỡ chặn phần camera trong `tournament_management_livestream_section.dart` (comment dòng 18-33): thêm CRUD camera (PUSH/PULL + sân), kéo camera vào thẻ sân, QR stream key (`qrcode` đã dùng cho token/join nên không thêm package) với issue tự động/thủ công, rotate, rename; **không log key ra console**. Backend vẫn là lớp chốt quyền (403 → error state hiện có).
8. **Xuất Excel VĐV**: mở rộng `ExcelExportService` thêm sheet roster (tên, liên hệ, hạng mục, trạng thái, phí) — dữ liệu đã có trong provider; không thêm package (dùng cùng lib excel hiện có).
9. **Import Excel**: giữ parser + preview server + Idempotency-Key hiện có; thêm bước "tạo hạng mục còn thiếu" từ tên hạng mục trong file (gọi `createDivision` trước preview, như Web), kèm xác nhận từng hạng mục sẽ tạo.
10. **i18n & test**: key mới thêm ở CẢ `app_vi.arb` + `app_en.arb` rồi `flutter gen-l10n`; không sửa file sinh. Mỗi nhóm chức năng có test widget ID `TC-WP-<nhóm>-nn` + test repository (dio mock) cho route mới; test nặng chạy cloud theo skill `cloud-test-runner`, local chỉ chạy file lẻ `flutter test --no-pub`.

## Rủi ro & cách gỡ

- **Xung đột lane khác**: các file nóng `organizer_ops_screen.dart`, `tournament_management_divisions_section.dart`, ARB — ghi Chủ file chung trong tasks, rebase từng nhóm nhỏ thay vì một nhánh khổng lồ (nếu lane khác đụng cùng file, tách commit theo nhóm 1→5).
- **Backend thiếu route AI** (phụ thuộc khoá AI): nếu 404 thì ẩn mục AI lịch (feature flag theo response), không phá flow còn lại.
- **Quyền organizer kết thúc giải**: backend có thể đã chặn organizer (Web gọi được tức là không chặn) — test API thật qua cloud trước khi bỏ `_canFinalizeTournament`.
- **Sheet lớn dễ chậm**: dựng list bằng `ListView.builder`, tránh `Column` phẳng hàng nghìn dòng như AddAthleteSheet đã làm đúng.

## Câu hỏi mở (không chặn propose)

- AI layout file Excel của Web (`/ai/tournaments/:id/roster-layout`) có đáng kéo vào App không, hay parser hiện tại đã đủ (đã đo 409/409)? Đề xuất: chỉ làm nếu người dùng gặp file layout lạ thật.
