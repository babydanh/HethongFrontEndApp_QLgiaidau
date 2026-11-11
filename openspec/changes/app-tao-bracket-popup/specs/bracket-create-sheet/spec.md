## ADDED Requirements

### Requirement: Popup cài đặt khi tạo bracket Vòng bảng / Round Robin
Khi BTC bấm "Tạo bracket" cho nội dung Vòng bảng + Loại trực tiếp hoặc Round Robin, App SHALL mở popup cài đặt; chỉ khi xác nhận mới lưu cấu hình và tạo bracket.

#### Scenario: Vòng bảng có gợi ý theo số đội
- **WHEN** nội dung Vòng bảng có 16 đội và BTC mở popup
- **THEN** popup hiện gợi ý 4 bảng, 4 đội mỗi bảng, đi tiếp 2, kèm nút Áp dụng

#### Scenario: Xác nhận lưu rồi tạo
- **WHEN** BTC chỉnh số bảng và bấm Tạo
- **THEN** App gọi `updateDivisionConfig` rồi `generateBracket` đúng một lần, và khoá nút trong lúc chạy

#### Scenario: Thể thức khác tạo thẳng
- **WHEN** BTC bấm "Tạo bracket" ở nội dung Loại trực tiếp
- **THEN** App tạo ngay, không mở popup
