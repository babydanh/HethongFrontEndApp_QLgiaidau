# Spec Delta

## Purpose

Quy định App hiện VĐV của mỗi đội trên thẻ trận ở Trang chủ và màn Chi tiết trận, gồm cả VĐV chưa có tài khoản SportO.

## ADDED Requirements

### Requirement: Đội đôi hiện từng VĐV

Khi API trận trả thành viên có tài khoản (`participant.members`) và/hoặc tên VĐV khách (`participant.guestNames`), App SHALL coi đó là danh sách VĐV của đội theo thứ tự: thành viên có tài khoản trước, VĐV khách sau. Đội có từ 2 VĐV trở lên SHALL hiện 2 vòng tròn trên thẻ trận Trang chủ và dưới tên đội ở Chi tiết trận. Mỗi vòng tròn là ảnh của VĐV đó, hoặc chữ viết tắt tên VĐV đó khi không có ảnh.

#### Scenario: Cặp VĐV khách

- **WHEN** trận có `participant1.members = []` và `participant1.guestNames = ["Nguyễn Minh Anh", "Trần Quốc Bảo"]`
- **THEN** thẻ trận Trang chủ hiện 2 vòng tròn "MA" và "QB" (chữ đầu hai từ cuối của tên, như VĐV có tài khoản) cho đội 1, không hiện "CP" của tên đội
- **AND** Chi tiết trận hiện 2 vòng tròn "N" và "T" dưới tên đội, nhãn ELO là "ELO Đôi"

#### Scenario: Một VĐV có tài khoản, một VĐV khách

- **WHEN** `members` có 1 người có ảnh và `guestNames` có 1 tên
- **THEN** vòng tròn thứ nhất là ảnh người có tài khoản, vòng tròn thứ hai là chữ viết tắt tên VĐV khách

#### Scenario: API chưa có guestNames

- **WHEN** payload trận không có trường `guestNames`
- **THEN** App hiện như trước thay đổi này

### Requirement: Tên đội "A / B" là hai VĐV

Đội không có VĐV nào trong payload mà tên đội có dạng "A / B" SHALL được hiện như đội 2 VĐV tên A và B, như Web. Chữ viết tắt tên đội chỉ dùng khi đội không có VĐV và tên đội không có dạng này.

#### Scenario: Tên đội "A / B" không kèm VĐV

- **WHEN** trận có `participant2.teamName = "Phan Anh Khoa / Hồ Minh Trí"`, `members = []`, không có `guestNames`
- **THEN** thẻ trận Trang chủ hiện 2 vòng tròn "AK" và "MT", không hiện "PA"
- **AND** Chi tiết trận hiện 2 vòng tròn "P" và "H"

### Requirement: VĐV khách không mở hồ sơ

Vòng tròn của VĐV khách SHALL không bấm được để mở hồ sơ, vì VĐV đó không có tài khoản.

#### Scenario: Bấm vào VĐV khách ở Chi tiết trận

- **WHEN** người xem bấm vòng tròn của VĐV khách
- **THEN** App không điều hướng sang hồ sơ người dùng nào
