## ADDED Requirements
### Requirement: Playoff nhánh thắng/thua phân trang
Tab Playoff công khai SHALL hiển thị nhánh thắng và nhánh thua riêng, mỗi lần tối đa 3 vòng.

#### Scenario: Nhánh thắng có 5 vòng
- **WHEN** nhánh thắng (kèm chung kết tổng) có 5 vòng
- **THEN** hiện 3 vòng đầu, bấm "Vòng sau" trượt cửa sổ tới vòng 4 và chung kết tổng (bản vẽ bracket: `playoff-bracket-theo-web`)
