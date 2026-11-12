## ADDED Requirements

### Requirement: Phát lại hiện H2H và Sơ đồ đúng giây đã bật khi live
Khi App phát lại bản ghi trận và phản hồi replay có `overlayEvents`, App MUST hiện overlay H2H hoặc Sơ đồ theo vị trí hiện tại trên timeline: với mỗi loại, sự kiện cuối cùng có `offsetSec` không muộn hơn vị trí quyết định bật hay tắt. App MUST dùng cùng widget và cùng quy tắc "một overlay một lúc" với phát trực tiếp.

#### Scenario: Phát qua đoạn H2H được bật
- **WHEN** `overlayEvents` có `H2H visible=true` ở 30s và `H2H visible=false` ở 50s, và vị trí phát lại là 40s
- **THEN** overlay H2H hiện

#### Scenario: Qua mốc tắt
- **WHEN** vị trí phát lại đi qua 50s
- **THEN** overlay H2H ẩn

#### Scenario: Tua lùi vào đoạn đang bật
- **WHEN** người xem tua từ 70s về 40s
- **THEN** overlay H2H hiện lại ngay, không cần chờ phát qua mốc bật

#### Scenario: Cả hai overlay cùng bật
- **WHEN** tại vị trí hiện tại cả H2H và Sơ đồ đều đang `visible=true`
- **THEN** chỉ Sơ đồ hiện, giống phát trực tiếp

### Requirement: Dữ liệu thiếu hoặc sai không làm hỏng phát lại
App MUST coi `overlayEvents` vắng mặt, rỗng hoặc có phần tử sai dạng (kind lạ, `visible` không phải boolean, `offsetSec` không phải số hữu hạn không âm) là không có sự kiện đó, và MUST NOT làm phát lại lỗi.

#### Scenario: Trận cũ chưa có mốc
- **WHEN** phản hồi replay không có `overlayEvents`
- **THEN** phát lại chạy như hiện nay, không hiện H2H hay Sơ đồ

#### Scenario: Một phần tử sai dạng
- **WHEN** `overlayEvents` có một phần tử `kind="XYZ"` cùng các phần tử hợp lệ
- **THEN** phần tử sai bị bỏ qua, các phần tử hợp lệ vẫn có tác dụng
