# tournament-group-playoff-view Specification

## Purpose
Cho phép người xem giải chuyển giữa bảng xếp hạng vòng bảng và sơ đồ playoff trong cùng một hạng mục có thể thức kết hợp, đồng thời giữ nguyên cách hiển thị của các thể thức khác.

## Requirements

### Requirement: Xem vòng bảng và playoff qua hai tab
Hạng mục có vòng bảng và playoff MUST có hai tab **Bảng** và **Playoff**; tab **Bảng** được chọn mặc định và hiển thị thứ hạng vòng bảng, còn tab **Playoff** hiển thị sơ đồ loại trực tiếp. Nhãn tab MUST theo ngôn ngữ ứng dụng.

#### Scenario: Xem thứ hạng và sơ đồ playoff
- **WHEN** người xem mở hạng mục có trận vòng bảng và trận playoff
- **THEN** ứng dụng hiển thị hai tab, mặc định mở **Bảng**, và cho phép chuyển sang **Playoff** để xem sơ đồ chỉ gồm các trận loại trực tiếp

#### Scenario: Hạng mục chưa có trận
- **WHEN** hạng mục được cấu hình vòng bảng + playoff nhưng chưa có trận nào
- **THEN** ứng dụng vẫn hiển thị hai tab, từng tab có trạng thái rỗng phù hợp và không bị lỗi

#### Scenario: Thể thức riêng của hạng mục khác thể thức chung
- **WHEN** giải được cấu hình vòng tròn nhưng hạng mục được cấu hình vòng bảng + playoff
- **THEN** ứng dụng hiển thị hai tab và dùng thể thức của hạng mục để hiển thị bảng xếp hạng

### Requirement: Giữ cách hiển thị của thể thức khác
Hạng mục không kết hợp vòng bảng và playoff MUST tiếp tục dùng nội dung hiện có và MUST NOT hiển thị hai tab mới.

#### Scenario: Hạng mục chỉ có vòng bảng
- **WHEN** người xem mở hạng mục chỉ có thể thức vòng bảng
- **THEN** ứng dụng giữ nguyên bảng đấu vòng tròn hiện có và không hiển thị hai tab mới

#### Scenario: Hạng mục chỉ có loại trực tiếp
- **WHEN** người xem mở hạng mục chỉ có thể thức loại trực tiếp
- **THEN** ứng dụng giữ nguyên sơ đồ loại trực tiếp hiện có và không hiển thị hai tab mới
