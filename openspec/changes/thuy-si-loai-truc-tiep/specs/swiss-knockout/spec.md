## ADDED Requirements

### Requirement: Cấu hình số đội vào loại trực tiếp trên App
Editor cấu hình Thụy Sĩ SHALL có ô "Số đội vào loại trực tiếp" nhận 0 hoặc số nguyên 2..64 và gửi `swiss.advanceTopN`; ô MUST chỉ đọc khi nội dung đã sinh sơ đồ; khi lưu qua PATCH stage, App MUST gửi lại đúng giá trị đã lưu của `advanceTopN`.

#### Scenario: Đặt khi tạo nội dung
- **WHEN** BTC chọn Thụy Sĩ, nhập 8 và lưu
- **THEN** payload nội dung có `roundConfig.swiss.advanceTopN = 8`

#### Scenario: Sửa sau khi đã sinh sơ đồ
- **WHEN** nội dung có stage Swiss với `advanceTopN = 8` và BTC đổi số vòng rồi lưu
- **THEN** PATCH stage mang `swiss.advanceTopN = 8` (không đổi) và ô hiển thị 8 ở dạng chỉ đọc

### Requirement: Sơ đồ Thụy Sĩ có loại trực tiếp
Khi giải có cả trận Thụy Sĩ và trận loại trực tiếp, màn sơ đồ và `PublicBracketView` SHALL hiển thị hai phần theo thứ tự (Thụy Sĩ, loại trực tiếp) thay vì chỉ Thụy Sĩ; khi stage loại trực tiếp chưa có đội MUST hiển thị trạng thái chờ; bảng xếp hạng Swiss MUST kẻ một đường ngăn sau hạng `advanceTopN` khi `advanceTopN > 0`.

#### Scenario: Đã đổ cây
- **WHEN** giải có 12 trận Swiss và cây 8 đội đã có đội
- **THEN** người xem thấy phần Thụy Sĩ (bảng xếp hạng, các vòng) và phần loại trực tiếp với 8 đội

#### Scenario: Chờ Thụy Sĩ
- **WHEN** stage loại trực tiếp tồn tại nhưng chưa có đội
- **THEN** phần loại trực tiếp hiện trạng thái chờ, phần Thụy Sĩ hiển thị bình thường

#### Scenario: Thụy Sĩ thuần
- **WHEN** giải không có stage loại trực tiếp
- **THEN** hiển thị đúng như trước thay đổi này
