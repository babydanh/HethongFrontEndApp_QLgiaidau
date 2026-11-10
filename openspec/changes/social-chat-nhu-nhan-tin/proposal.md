## Why

Tab Trò chuyện của buổi giao lưu là bản chat tối giản (chỉ chữ, avatar chữ cái), trong khi App đã có màn nhắn tin đầy đủ. Ngoài ra danh sách Khám phá đặt giải "Mở đăng ký" theo giờ bắt đầu giải trong khi cửa sổ 7 ngày đo từ giờ mở đăng ký, nên một giải bị tính bằng hai mốc.

## What Changes

- Tab Trò chuyện nhúng `ChatDetailScreen` (cờ `embedded`, không AppBar) khi buổi có `chatRoomId` và chưa đóng: gửi ảnh, copy, avatar thật như chat trong App. Buổi đã đóng hoặc chưa có phòng giữ danh sách chỉ đọc cũ.
- `newTournamentEntriesForDay`: giải "Mở đăng ký" đặt theo giờ mở đăng ký (một mốc), không theo giờ bắt đầu giải; giải "Đang diễn ra" vẫn theo giờ bắt đầu. Không còn mục thứ hai ở ngày bắt đầu giải.
- Không đổi Backend, DTO hay route.

## Capabilities

### New Capabilities
- `social-chat-room`: tab chat buổi giao lưu dùng chat App; mốc giờ một lần của giải trong danh sách.

## Impact

- `lib/features/chat/screens/chat_detail_screen.dart`, `lib/features/social/widgets/chat_tab/social_chat_tab.dart`, `lib/features/home/widgets/explore_new_tournaments.dart` và test tương ứng.
- Chưa có dán ảnh từ bàn phím (cần thêm riêng); Web chưa có `pickNewTournaments` trên main nên không cần đồng bộ.
