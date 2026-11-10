## Why

Khám phá vẫn tách khối "Vừa mở đăng ký / Vừa bắt đầu" khỏi danh sách mốc giờ. Người dùng muốn giải nằm ngay trong từng mốc giờ, mỗi mốc liệt kê đủ buổi Social và giải có trong đó (2026-11-10).

## What Changes

- Giải vừa mở đăng ký / vừa bắt đầu được xếp vào mốc giờ (HH:mm) của chính nó trong danh sách theo ngày; số đếm của mốc tính cả giải.
- Giải có mốc trước hôm nay (vd bắt đầu hôm qua) hiện ở hôm nay, giữ giờ gốc.
- Chọn ngày không có buổi Social nhưng có giải: hiện mốc giờ, không hiện "Không có buổi Social".
- Chế độ "Gần bạn" (không có mốc giờ) giữ khối giải như cũ.

## Out of scope

- Không đổi quy tắc chọn giải (7 ngày / 48 giờ, tối đa 6), không đổi nội dung thẻ, không đổi Web.
- Giải mở đăng ký có ngày bắt đầu ngoài dải ngày 6 ngày chưa hiện trong danh sách mốc giờ.

## Capabilities

### Modified Capabilities
- `explore-new-tournaments`: giải nằm trong mốc giờ thay vì khối riêng.
