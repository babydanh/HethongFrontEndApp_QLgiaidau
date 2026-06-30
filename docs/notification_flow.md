# 🔔 Plan Luồng Thông Báo — Flutter App

> **Tài liệu:** Notification Flow Design  
> **Phiên bản:** 1.0  
> **Ngày:** 30/06/2026  
> **Dựa trên:** Backend module `notifications` (Socket.IO + REST)

---

## 🎯 Mục Tiêu

Xây dựng luồng thông báo realtime cho Flutter app:

1. **Notification bell** trên Header — hiển thị badge đếm chưa đọc
2. **Notification list screen** — danh sách tất cả thông báo, phân trang
3. **Real-time push** — Socket.IO nhận thông báo mới ngay lập tức
4. **Deep link** — bấm vào thông báo → điều hướng đúng màn hình
5. **Toast** — thông báo mới hiện pop-up nhỏ khi đang ở app

---

## 🏗 Kiến Trúc

```
Backend Socket.IO                  Flutter App
─────────────────                  ───────────
                                   
Server ── notification:new ──▶  NotificationSocketService
                                    │
                                    ├─▶ ref.read(notificationProvider.notifier).addNotif()
                                    │      → unreadCount tăng
                                    │      → badge cập nhật
                                    │      → toast pop-up
                                    │
                                    ├─▶ Người dùng bấm bell
                                    │      → NotificationScreen
                                    │      → GET /notifications?page=1
                                    │
                                    └─▶ Người dùng bấm vào 1 notif
                                           → PATCH /notifications/:id/read
                                           → deep link redirect
```

---

## 📦 Cấu Trúc Files

```
lib/
├── core/
│   └── services/
│       └── notification_socket_service.dart    ← ✨ MỚI - Socket.IO client
│
├── domain/
│   └── entities/
│       └── notification.dart                   ← ✨ MỚI - Entity
│
├── data/
│   ├── models/
│   │   └── notification_model.dart             ← ✨ MỚI - Model
│   └── repositories/
│       └── api/
│           └── api_notification_repository.dart ← ✨ MỚI - API calls
│
├── providers/
│   └── notification_provider.dart              ← ✨ MỚI - Riverpod
│
└── features/
    └── notification/
        ├── screens/
        │   └── notification_screen.dart        ← ✨ MỚI - List screen
        └── widgets/
            ├── notification_card.dart          ← ✨ MỚI - 1 card
            └── notification_bell.dart          ← ✨ MỚI - Bell badge
```

---

## 📊 Data Flow Chi Tiết

### 1. Entity

```dart
// domain/entities/notification.dart
class AppNotification {
  final String id;
  final String type;         // TOURNAMENT | MATCH | PAYMENT | SYSTEM | CHAT | REMINDER
  final String title;
  final String? body;
  final String? redirectUrl; // deep link: /intro/:id, /match/:id, ...
  final bool isRead;
  final DateTime createdAt;

  // Icon & color mapping theo type
  IconData get icon { ... }
  Color get color { ... }
}
```

**Mapping type → icon + màu:**
| Type | Icon | Màu |
|------|------|:----:|
| `TOURNAMENT` | `emoji_events` | 🟡 `#F59E0B` |
| `MATCH` | `sports_tennis` | 🔵 `#2979FF` |
| `PAYMENT` | `payments` | 🟢 `#10B981` |
| `SYSTEM` | `admin_panel_settings` | 🔴 `#EF4444` |
| `CHAT` | `chat` | 🟣 `#8B5CF6` |
| `REMINDER` | `notifications` | ⚪ `#64748B` |

### 2. API Repository

```dart
// data/repositories/api/api_notification_repository.dart
class ApiNotificationRepository {
  Future<List<AppNotification>> getMyNotifications({int page = 1, int limit = 20});
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}
```

**API Endpoints:**
| Method | Path | Ghi chú |
|--------|------|---------|
| `GET` | `/notifications?page=1&limit=20` | List + meta.unreadCount |
| `GET` | `/notifications/unread-count` | `{ count: 3 }` |
| `PATCH` | `/notifications/:id/read` | Mark 1 cái |
| `PATCH` | `/notifications/read-all` | Mark all |

### 3. Socket.IO Service

```dart
// core/services/notification_socket_service.dart
class NotificationSocketService {
  Socket? _socket;

  void connect(String token) {
    _socket = io('$baseUrl/notifications', {
      'auth': { 'token': 'Bearer $token' },
      'transports': ['websocket'],
    });
    _socket?.emit('subscribe');
    _socket?.on('notification:new', _onNewNotification);
  }

  void disconnect() { _socket?.disconnect(); }

  Stream<AppNotification> get notificationStream => ...;
}
```

### 4. Provider

```dart
// providers/notification_provider.dart
final notificationProvider = AsyncNotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
}
```

---

## 📱 UI Design

### Notification Bell (Header)

```
┌──────┐
│ 🔔   │
│  3   │ ← Badge đỏ (chỉ hiện nếu > 0)
└──────┘
```

**Widget:** `notification_bell.dart`
- Hiển thị badge unread count
- Bấm → navigate `/notifications`
- Stream lắng nghe realtime → cập nhật badge

### Notification List Screen

```
┌──────────────────────────────────┐
│  🔙  Thông báo                  │
├──────────────────────────────────┤
│  [Đọc tất cả]                   │ ← Nếu có unread
│                                  │
│  ┌─── HÔM NAY ────────────────┐ │ ← Section header
│  │                            │ │
│  │ 🟡 Đăng ký thành công     │ │ ← NotificationCard
│  │    Đơn đăng ký giải...    │ │
│  │    10:30                    │ │
│  │                            │ │
│  │ 🔵 Trận đấu sắp diễn ra  │ │
│  │    Trận của bạn tại...    │ │
│  │    09:15                    │ │
│  └────────────────────────────┘ │
│                                  │
│  ┌─── HÔM QUA ────────────────┐ │
│  │                            │ │
│  │ 💳 Thanh toán thành công  │ │
│  │    Lệ phí giải đấu...     │ │
│  │    Hôm qua                 │ │
│  └────────────────────────────┘ │
│                                  │
│  [Xem thêm]                     │ ← Load more
└──────────────────────────────────┘
```

### Notification Card

```
┌──────────────────────────────────────┐
│  ┌────┐                              │
│  │ 🟡 │  Đăng ký thành công         │ ← Title bold
│  │    │  Đơn đăng ký của bạn...     │ ← Body 2 dòng
│  │icon│  10:30                    │ ← Time
│  └────┘  ●                          │ ← Dot xanh nếu chưa đọc
└──────────────────────────────────────┘
```

**Widget:** `notification_card.dart`
- Icon theo type + màu
- Title bold, body 2 dòng ellipsis
- Time relative (vừa xong, 5p trước, hôm qua, ...)
- Dot xanh báo unread
- Swipe để mark as read
- Bấm → deep link

---

## 🔄 Luồng Chi Tiết

### Khi App Mở

```
1. App khởi động
2. AuthProvider init → nếu có JWT
3. NotificationSocketService.connect(token)
4. Socket.IO kết nối /notifications namespace
5. socket.emit('subscribe') → join room user:{id}
6. notificationProvider gọi GET /notifications/unread-count
7. Bell badge cập nhật số
```

### Khi Có Thông Báo Mới (realtime)

```
1. Backend gửi socket → notification:new
2. SocketService nhận → parse thành AppNotification
3. NotificationNotifier.addNotif(notification)
4. unreadCount tăng lên 1
5. Bell badge cập nhật ngay lập tức
6. Nếu đang ở trong app → show SnackBar/Toast nhỏ
```

### Khi Bấm Vào Bell

```
1. Navigate /notifications
2. NotificationScreen gọi GET /notifications?page=1
3. Hiển thị danh sách (Section header theo ngày)
4. Pull-to-refresh → reload
5. Scroll hết → load more (pagination)
```

### Khi Bấm Vào 1 Notification

```
1. Gọi PATCH /notifications/:id/read
2. Provider update isRead = true
3. unreadCount -= 1
4. Nếu có redirectUrl:
   → Deep link navigate
   → VD: /intro/:id , /match/:id , /tournaments/:id
```

### Khi Bấm "Đọc tất cả"

```
1. Gọi PATCH /notifications/read-all
2. Provider set isRead = true cho tất cả
3. unreadCount = 0
```

---

## 🧪 States

### Notification List Screen

| State | Xử lý |
|-------|-------|
| **Loading** | Shimmer list |
| **Empty** | Icon chuông + "Chưa có thông báo nào" |
| **Error** | ErrorView + retry |
| **Data** | List notification cards |
| **Load more** | Loading indicator cuối list |
| **No more** | "Đã hiển thị tất cả" |

### Notification Bell

| State | Xử lý |
|-------|-------|
| **Chưa login** | Ẩn badge |
| **Đã login, 0 unread** | Bell trơn |
| **Đã login, có unread** | Bell + badge đỏ |
| **Socket chưa kết nối** | Bell trơn |

---

## 📈 Tiến Độ

```
Phase 1: Entity + Model + API Repo   ░░░░░░░░░░  Chưa làm
Phase 2: Provider + Socket Service   ░░░░░░░░░░  Chưa làm
Phase 3: Notification List Screen    ░░░░░░░░░░  Chưa làm
Phase 4: Notification Bell + Badge   ░░░░░░░░░░  Chưa làm
Phase 5: Deep Link + Toast Realtime  ░░░░░░░░░░  Chưa làm
```

---

## 🎯 Thứ Tự Ưu Tiên

| Ưu tiên | Nội dung | Vì sao? |
|:-------:|----------|---------|
| 1 | **Entity + Model + Repo** | Nền tảng để làm mọi thứ |
| 2 | **Provider + Socket** | Data flow + realtime |
| 3 | **Notification List Screen** | UI chính, người dùng thấy |
| 4 | **Bell + Badge** | Header, dễ thấy nhất |
| 5 | **Deep Link + Toast** | UX nâng cao |

---

## 🔗 Liên Kết

- [Backend Notification Module](../../backend-api_qlgiaidau/src/modules/notifications/)
- [Notification Schema](../../backend-api_qlgiaidau/src/database/schema/notifications.schema.ts)
- [Notification Builder](../../backend-api_qlgiaidau/src/modules/notifications/notification-builder.ts)
- [Socket Gateway](../../backend-api_qlgiaidau/src/modules/notifications/notifications.gateway.ts)
- [Trạng thái hiện tại](../CURRENT_STATUS.md)
