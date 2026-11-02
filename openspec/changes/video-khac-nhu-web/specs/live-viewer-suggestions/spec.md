## ADDED Requirements

### Requirement: Gợi ý Video khác theo luật Web
Tab "Video khác" SHALL chỉ đưa trận đang diễn ra (LIVE, ONGOING, IN_PROGRESS, PLAYING) rồi tới trận sắp diễn ra, và MUST loại trận bye, trận đã hoàn tất, trận đã có người thắng và chính trận đang xem.

#### Scenario: Trận PLAYING được coi là đang diễn ra
- **WHEN** giải có một trận trạng thái PLAYING và một trận sắp diễn ra
- **THEN** trận PLAYING đứng trước trận sắp diễn ra

#### Scenario: Trận bye hoặc đã có người thắng bị loại
- **WHEN** danh sách có trận bye và trận đã có `winnerId`
- **THEN** hai trận đó không xuất hiện trong tab
