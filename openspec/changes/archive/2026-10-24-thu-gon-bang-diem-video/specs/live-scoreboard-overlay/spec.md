# Spec Delta

## Purpose

Bảng điểm đè video gọn theo tên đội, che ít khung hình, hai ô điểm luôn thẳng cột.

## ADDED Requirements

### Requirement: Bảng điểm co theo tên và thẳng cột
Bảng điểm SHALL rộng theo tên viết tắt dài nhất của hai đội, tối đa 150 px; tên dài hơn MUST cắt "…". Hai ô điểm MUST nằm cùng một cột ở mép phải bảng.

#### Scenario: Tên ngắn
- **WHEN** hai đội là "Đội A" và "Đội B"
- **THEN** bảng rộng dưới 100 px và cao không quá 44 px

#### Scenario: Tên dài ngắn khác nhau
- **WHEN** hai đội là "son bao b" và "Sơn Bảo Phan / Tiến Minh"
- **THEN** hai ô điểm có cùng tâm ngang, bảng rộng không quá 150 px
