## Nguồn sự thật

- Giao diện và hành vi: `reference/design-prototype.html` (mở bằng trình duyệt; phần viền hồng "MỚI" là phần thêm, còn lại giữ như App hiện tại).
- Logic tham chiếu đã kiểm: `reference/scoring-engine.js` + `reference/scoring-engine.test.js` (`node reference/scoring-engine.test.js` → `OK 52`). Dart và TypeScript phải cho cùng kết quả với các ca trong file test này. Đây là tham chiếu, không đưa vào bản build.

## Luật chốt cho từng môn (ngắn)

| Môn | Luật hiển thị/tính |
|---|---|
| Pickleball side-out | Chỉ đội giao ghi điểm. Đôi: Giao 1 → Giao 2 → đổi giao; mở màn 0-0-2 thua ngay là đổi giao. Đơn: không có Giao 2. Bấm "+" đội nhận = đội giao thua pha. |
| Pickleball rally/Lite | Ai thắng pha +1 và được giao. Lite không xướng, không hiện giao bóng. |
| Cầu lông | Thắng pha +1, được giao; 21 hơn 2, trần 30; ô giao: điểm người giao chẵn = phải, lẻ = trái; đôi: người giao thắng thì hai VĐV đổi ô; banner nghỉ 60s khi bên dẫn đạt 11, nghỉ 120s giữa game. |
| Bóng bàn | 11 hơn 2; đổi giao mỗi 2 điểm, từ 10-10 mỗi 1 điểm; người giao đầu mỗi game đổi luân phiên; game cuối nhắc đổi sân ở 5. |
| Tennis | 0-15-30-40, Deuce/AD; No-Ad: điểm kế tiếp ở 40-40 quyết định game; set 6 game hơn 2; 6-6 tie-break (`tiebreakPoints`, hơn 2); set quyết định: `TB7`, `TB10_FINAL`, `NO_TB_FINAL`, `MATCH_TB10` (10 điểm thay set 3); người giao đổi mỗi game; tie-break giao 1 điểm đầu rồi mỗi 2 điểm. |
| Bóng đá | Ghi bàn chỉ trong hiệp/bù giờ/hiệp phụ; vàng thứ 2 = đỏ (ghi diễn biến cả hai); còn dưới 7 người thì trận dừng, đội kia thắng; thay người tối đa `subsLimit` (mặc định 5). |

## Quyết định thiết kế

- Giữ nguyên khung màn của App; chỉ thêm phần hiển thị và đổi hành vi nút ở chỗ đã nêu.
- Hàm luật là hàm thuần (đầu vào: trạng thái, đầu ra: trạng thái mới) đặt riêng để test không cần widget; widget chỉ gọi và vẽ.
- Cấu hình lấy từ `sportRules` đã có (`noAd`, `finalSetMode`, `tiebreakMode`, `tiebreakPoints`); thiếu thì dùng mặc định cũ (không đổi hành vi giải đang chạy).
- Không đổi hợp đồng API. `scoreDetails` chỉ thêm trường tuỳ chọn nếu cần lưu trạng thái giao; trường cũ giữ nguyên.

## Phương án đã loại

- Công tắc Rally/Side-out trong Lite: cần Backend lưu cấu hình, để lại.
- Chỉ đổi nhãn nút "ĐỔI GIAO" (Q1-B): người chấm vẫn bấm "+" đội thắng pha và thấy không có gì xảy ra.

## Ràng buộc chung cho mọi nhánh làm việc

- Nhánh pickleball nhặt trước 2 commit `324b7074`, `402ffbaf` (nhánh `giao-bong-mo-man-app`: luật giao mở màn) rồi mới làm tiếp.
- Mỗi nhánh viết test đỏ trước (`TC-CBD-<MÔN>-NN`), chạy test hẹp của mình, không chạy `flutter analyze` toàn repo và không chạy E2E.
- Chuỗi hiển thị mới ở `app_vi.arb` và `app_en.arb` (App) với khoá có tiền tố riêng từng nhánh: `cbdPb*`, `cbdRally*`, `cbdTennis*`, `cbdFb*`; xong chạy `flutter gen-l10n`. Không sửa tay file sinh.
