# Spec Delta

## Purpose

App hiển thị badge bậc trình độ, tiến độ lên bậc và chú giải bậc theo đúng nguồn bậc Backend trả về: ELO của SportO, hoặc DUPR đã liên kết ở môn pickleball.

## ADDED Requirements

### Requirement: Badge theo nguồn DUPR không suy từ ELO

Khi một rank có `tierSource = 'DUPR'`, App MUST chỉ dùng `tierName` của API để chọn badge. Khi `tierName` là `null` hoặc rỗng, App MUST NOT hiện badge bậc ở bảng xếp hạng, hồ sơ, bottom sheet hồ sơ và badge trên avatar, và MUST NOT suy bậc từ `eloPoints`.

#### Scenario: Có DUPR liên kết

- **WHEN** bảng xếp hạng pickleball có dòng `tierSource: 'DUPR'`, `tierName: 'High Tier C'`, `eloPoints: 1100`
- **THEN** dòng đó hiện badge `HTC`, không phải bậc suy từ ELO 1100

#### Scenario: Chưa liên kết DUPR

- **WHEN** hồ sơ có rank pickleball `tierSource: 'DUPR'`, `tierName: null`
- **THEN** không có badge bậc cho rank đó, và badge trên avatar cũng không hiện bậc pickleball

### Requirement: Nguồn ELO giữ nguyên

Khi `tierSource = 'ELO'` hoặc JSON không có `tierSource`, App MUST hiển thị badge như trước change này, gồm cả việc suy bậc từ `eloPoints` khi thiếu `tierName`.

#### Scenario: Rank cầu lông

- **WHEN** rank có `tierSource: 'ELO'`, `tierName: 'Low Tier B'`
- **THEN** hiện badge `LTB` như hiện nay

#### Scenario: JSON cũ không có tierSource

- **WHEN** rank không có `tierSource`, `tierName` rỗng, `eloPoints: 1450`
- **THEN** hiện badge suy từ ELO như hiện nay

### Requirement: Ẩn tiến độ ELO ở nguồn DUPR

Khi `tierSource = 'DUPR'`, App MUST NOT hiện "còn X ELO để lên {bậc}" (`ranking_eloToNext`) cho rank đó. Ở nguồn `ELO`, tiến độ MUST giữ như hiện nay.

#### Scenario: Thẻ tiến độ pickleball nguồn DUPR

- **WHEN** `elo_progress_card` hiển thị rank có `tierSource: 'DUPR'`
- **THEN** không có dòng "còn X ELO để lên …"

#### Scenario: Thẻ tiến độ nguồn ELO

- **WHEN** rank có `tierSource: 'ELO'`, `eloPoints: 1450`
- **THEN** vẫn hiện "còn 50 ELO để lên High Tier B" (theo ngôn ngữ đang chọn)

### Requirement: Chú giải bậc theo DUPR

Khi các bậc trả về từ `GET /api/v1/categories/:id/elo-tiers` có `tierSource: 'DUPR'`, chú giải bậc MUST hiện 8 bậc với khoảng `minValue`–`maxValue` (bậc cao nhất hiện "từ {minValue}"), không có Tier S, kèm dòng "Bậc theo DUPR" lấy từ key i18n có ở cả `app_vi.arb` và `app_en.arb`. Danh sách rỗng MUST hiện trạng thái trống như hiện nay.

#### Scenario: Chú giải pickleball nguồn DUPR

- **WHEN** API trả 8 bậc `tierSource: 'DUPR'`, trong đó `High Tier C` có `minValue: 3.5`, `maxValue: 4.0`
- **THEN** chú giải hiện `High Tier C` với khoảng 3.50–3.99 và dòng "Bậc theo DUPR", không có Tier S

#### Scenario: API trả danh sách rỗng

- **WHEN** API trả danh sách bậc rỗng
- **THEN** chú giải hiện trạng thái trống như hiện nay, không lỗi
