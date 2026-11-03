## Why
Tab "Playoff" công khai luôn vẽ sơ đồ loại trực tiếp, kể cả khi playoff là nhánh thắng/thua. Web đã tách hai nhánh và phân trang theo 3 vòng (đợt 2 của `bang-dau-theo-web`).

## What Changes
- `PlayoffDoubleElimView`: tab Nhánh thắng / Nhánh thua, mỗi trang 3 vòng, chung kết tổng gộp cuối nhánh thắng, bấm trận mở popup chi tiết.
- `_GroupPlayoffTabs` dùng view này khi playoff có trận nhánh thắng/thua; playoff loại trực tiếp giữ `SingleElimDiagram`.
- Màn tổ chức không đổi.

## Impact
`lib/features/bracket/widgets/playoff_double_elim_view.dart`, `public_bracket_view.dart`, `group_stage_view.dart` (công khai `ModeChip`, `RoundMatchCard`), `app_{vi,en}.arb`.
