# match-round-label Specification

## Purpose
Quy định chữ App hiện cho vòng/bảng của một trận, cùng cách Web hiện (`src/utils/match-round-label.ts` của Web), để người xem hiểu trận thuộc giai đoạn nào.

## Requirements

### Requirement: Nhãn trận vòng bảng giống Web

Khi trận thuộc vòng bảng/vòng tròn và có tên bảng riêng (khác "Vòng bảng", "Group Stage", "Chung", "Default"), App SHALL hiện "Bảng <ký hiệu> • Lượt <n>". Tên bảng dạng "B" hoặc "Bảng B"/"Group B" SHALL thành "Bảng B"; tên bảng khác SHALL giữ nguyên. Thẻ hẹp SHALL hiện "Bảng <ký hiệu>" không kèm lượt.

#### Scenario: Bảng "B" lượt đi

- **WHEN** trận có `group.name = "B"`, `leg = 1`
- **THEN** thẻ trận Trang chủ hiện "BẢNG B • LƯỢT 1" (thẻ ngang hẹp hiện "BẢNG B"), không hiện "B"

#### Scenario: Tên bảng đã có chữ "Bảng"

- **WHEN** `group.name = "Bảng A"`
- **THEN** nhãn là "Bảng A • Lượt 1", không thành "Bảng Bảng A"

#### Scenario: Trận lượt về

- **WHEN** trận bảng B có `leg = 2`
- **THEN** nhãn là "Bảng B • Lượt 2"
