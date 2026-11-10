## ADDED Requirements

### Requirement: Chat buổi giao lưu dùng màn nhắn tin của App

Tab Trò chuyện MUST hiển thị `ChatDetailScreen` ở chế độ nhúng khi buổi có `chatRoomId` và trạng thái không phải COMPLETED hoặc CANCELLED. Ngược lại MUST giữ danh sách chỉ đọc hiện có.

#### Scenario: Buổi có phòng chat
- **WHEN** người tham gia mở tab Trò chuyện của buổi OPEN có `chatRoomId`
- **THEN** hiển thị chat của App không có AppBar riêng, gồm gửi ảnh và copy tin

#### Scenario: Buổi đã đóng
- **WHEN** buổi COMPLETED
- **THEN** chỉ hiện danh sách tin nhắn, không có ô nhập

### Requirement: Giải trong danh sách chỉ tính một mốc

Mỗi giải trong danh sách Khám phá MUST xuất hiện tối đa một lần theo một mốc: giờ bắt đầu cho giải đang diễn ra, giờ mở đăng ký cho giải mở đăng ký.

#### Scenario: Giải mở đăng ký có giờ bắt đầu ở tương lai
- **WHEN** giải mở đăng ký hôm nay lúc 08:00 và bắt đầu ngày 12/11 14:30
- **THEN** xuất hiện hôm nay lúc 08:00 và không xuất hiện ở ngày 12/11
