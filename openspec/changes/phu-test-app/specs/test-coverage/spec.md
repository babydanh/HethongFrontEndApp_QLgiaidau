## ADDED Requirements

### Requirement: Repository API có test hành vi cho parse, lọc và lỗi
Mỗi repository API được phủ lại SHALL có test chạy bằng `DioClient` thật với adapter giả, kiểm các nhánh: dạng payload khác nhau, lọc dữ liệu, tham số gửi đi, và xử lý lỗi (ném lại hoặc trả giá trị rỗng theo đúng hợp đồng hiện tại).

#### Scenario: Backend trả 500 cho danh sách CLB
- **WHEN** `getCommunities` nhận HTTP 500
- **THEN** repository ném lại `DioException` thay vì trả danh sách rỗng

#### Scenario: Con trỏ phân trang không tiến
- **WHEN** backend trả `nextCursor` bằng con trỏ vừa gửi
- **THEN** `getMembersPaged` trả `hasMore=false` để UI không lặp vô hạn

### Requirement: Test phải đỏ khi hành vi bị phá
Mỗi nhóm test mới SHALL được chứng minh đỏ khi cố ý phá hành vi production tương ứng, và kết quả ghi trong `handoff.md`.

#### Scenario: Phá bộ lọc PRIVATE
- **WHEN** điều kiện loại CLB PRIVATE bị bỏ tạm thời
- **THEN** ít nhất một test của nhóm thất bại
