## ADDED Requirements

### Requirement: Nút phóng to và vuốt đổi vòng trên dải vòng
Sơ đồ playoff SHALL có nút phóng to cùng hàng với mũi tên đổi vòng để mở sơ đồ toàn màn hình, và SHALL đổi vòng khi người dùng vuốt ngang trên dải đó.

#### Scenario: Mở toàn màn hình
- **WHEN** người dùng bấm nút phóng to trên dải vòng
- **THEN** mở sơ đồ toàn màn hình của đúng hạng mục

#### Scenario: Vuốt đổi vòng
- **WHEN** người dùng vuốt sang trái trên dải vòng và còn vòng sau
- **THEN** sang vòng sau; vuốt sang phải ở vòng đầu thì giữ nguyên
