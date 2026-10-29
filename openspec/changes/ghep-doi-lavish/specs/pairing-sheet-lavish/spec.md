## ADDED Requirements

### Requirement: Popup ghép đôi gọn chữ, chân một hàng
Popup "Ghép đôi" SHALL không hiện dòng mô tả hay chữ hướng dẫn, và chân popup SHALL xếp nút chính và nút phụ trên một hàng, không có nút "Hủy".

#### Scenario: Tab Thủ công
- **WHEN** mở popup ghép đôi
- **THEN** không có dòng mô tả; chân có đúng hai nút "Xếp ngẫu nhiên" và "Ghép N đôi" cùng một hàng; không có nút "Hủy"

#### Scenario: Tab Tự động
- **WHEN** chuyển sang tab Tự động
- **THEN** chỉ có ba lựa chọn nhãn ngắn Ngẫu nhiên, Cân bằng, Cùng trình, không câu gợi ý; chân có một nút "Bắt đầu ghép"

### Requirement: Hộp Tự ghép dùng cùng bộ chọn
Hộp "Tự ghép" SHALL dùng cùng ba lựa chọn nhãn ngắn và không hiện câu hướng dẫn.

#### Scenario: Chọn cách ghép
- **WHEN** mở hộp Tự ghép rồi chọn "Cân bằng" và bấm "Bắt đầu ghép"
- **THEN** chiến lược ELO_BALANCED được gửi cho hạng mục đang chọn; bấm "Hủy" thì không gửi gì
