## ADDED Requirements

### Requirement: Thông tin giải dùng một nút Lưu cố định
Màn Thông tin giải SHALL gom nội dung thành bốn nhóm (Chung, Nhận diện, Giải thưởng, Liên hệ), mỗi nhóm thu gọn hoặc mở được, và SHALL có đúng một nút "Lưu thay đổi" cố định ở đáy, vô hiệu khi chưa có thay đổi và khi đang lưu.

#### Scenario: Chưa sửa gì
- WHEN người quản lý mở màn Thông tin giải và chưa sửa trường nào
- THEN nút Lưu thay đổi bị vô hiệu

#### Scenario: Sửa rồi lưu
- WHEN người quản lý sửa tên giải và bấm Lưu thay đổi
- THEN app gọi cập nhật giải đúng một lần với payload cũ (name, description, tournamentConfig) cộng các trường Giải thưởng/Liên hệ chỉ khi chúng đổi, và nút quay lại vô hiệu cho tới khi lưu xong

#### Scenario: Thoát khi chưa lưu
- WHEN có thay đổi chưa lưu và người quản lý thoát khỏi màn
- THEN app hỏi xác nhận bỏ thay đổi trước khi thoát

### Requirement: Địa điểm và sân gọn, che URL camera
Mỗi sân SHALL hiện trên một dòng gồm tên sân, trạng thái camera và hành động; URL camera SHALL NOT hiện ngoài danh sách; sheet camera SHALL che URL bằng dấu chấm cho tới khi bấm Hiện.

#### Scenario: Trạng thái camera trên dòng sân
- WHEN sân đã có URL camera
- THEN dòng sân ghi "Đã gắn camera" và không chứa chuỗi URL

#### Scenario: Sheet camera che URL
- WHEN người quản lý bấm sửa camera của sân
- THEN ô URL được che, bấm Hiện thì mới thấy, Lưu gọi ghi URL, Gỡ camera gọi ghi URL rỗng sau xác nhận

#### Scenario: Xoá sân
- WHEN người quản lý chọn Xoá sân trong menu ⋮
- THEN app hiện hộp xác nhận và chỉ xoá khi đồng ý
