## ADDED Requirements

### Requirement: Ô nhập tay cùng chiều cao khi đã nhập
Các ô nhập tay của popup "Thêm VĐV" SHALL giữ cùng một chiều cao dù ô còn trống hay đã có chữ, và ô "Loại điểm" SHALL cao bằng ô "Điểm".

#### Scenario: Ô đã nhập cạnh ô chọn
- **WHEN** nhập chữ vào Tên, Email, SĐT, Điểm trên tab "Nhập tên"
- **THEN** cả 5 ô, gồm ô chọn Loại điểm, có cùng chiều cao và nhãn luôn nổi
