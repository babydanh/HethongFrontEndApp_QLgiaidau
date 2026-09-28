# Thiết kế tính năng Xé vé Social trong hệ thống quản lý giải đấu

## Câu hỏi của người dùng

Trong Flutter mobile app cho hệ thống quản lý giải đấu, tôi cần phát
triển tính năng xé vé social.

Tính năng này trong hệ thống quản lý sân lấy đối tượng chi nhánh sân làm
trung tâm. Khi user click vào sân → chọn đặt lịch xé vé social → default
filter theo ngày hôm nay (user có thể đổi ngày) → List ra danh sách các
social trong ngày hôm đó.

Các thông tin chi tiết như hình ảnh người dùng cung cấp.

Vấn đề cốt lõi hiện tại: Khi tôi áp dụng mô hình này vào quản lý giải
đấu (không có đối tượng chi nhánh sân) thì thiết kế như thế nào?

------------------------------------------------------------------------

# Phân tích và đề xuất

## 1. Không nên cố tìm một "đối tượng thay thế chi nhánh sân"

Với hệ thống quản lý giải đấu, không nên cố tìm một entity đóng vai trò
giống hệt `Branch`.

Nên đổi cách suy nghĩ từ:

``` text
Chi nhánh sân → các suất Social của chi nhánh
```

sang:

``` text
Đơn vị tổ chức / CLB → các sự kiện Social của đơn vị
```

Hoặc nếu muốn hệ thống mở rộng hơn:

``` text
Social Event → là một loại Event độc lập
```

------------------------------------------------------------------------

## 2. Phân biệt Tournament và Social

Một mô hình có thể là:

``` text
Club
 └── Tournament
      ├── Registration
      ├── Player
      ├── Match
      └── Result
```

Tuy nhiên Social không nên bị nhét vào Tournament.

### Tournament

Có thể có:

-   Tên giải
-   Thời gian
-   Nội dung thi đấu
-   Category
-   Luật
-   Đăng ký
-   Bracket
-   Match
-   Ranking / Result

### Social

Có thể có:

-   Thời gian chơi
-   Địa điểm
-   Số slot
-   Giá vé
-   Người tham gia
-   Trạng thái
-   Có thể xếp cặp
-   Có thể tạo trận
-   Có kết quả nếu muốn

Nhưng Social không nhất thiết có bracket hoặc đầy đủ cấu trúc của
Tournament.

Do đó có thể thiết kế:

``` text
Club / Organizer
       │
       ├── Tournament
       │
       └── Social Event
```

Thay vì:

``` text
Club
 └── Tournament
      └── Social
```

------------------------------------------------------------------------

# 3. Màn hình "Xé vé Social" nên bắt đầu từ đâu?

Nếu hệ thống quản lý sân hiện tại là:

``` text
Sân A
   ↓
Đặt lịch
   ↓
Xé vé Social
   ↓
Danh sách Social hôm nay
```

thì với hệ thống quản lý CLB/giải đấu có thể chuyển thành:

``` text
CLB / Đơn vị tổ chức
        ↓
     Social
        ↓
Danh sách Social theo ngày
```

Ví dụ:

``` text
Friendly Pickleball
        ↓
     Social
        ↓
Hôm nay 16/09
        ↓
14:00 - 17:00
17:00 - 22:00
```

Nếu người dùng không muốn chọn CLB trước, còn một cách tốt hơn:

``` text
Trang chủ
   ↓
Social
   ↓
Hôm nay
   ↓
Danh sách Social
```

Sau đó cho phép filter:

``` text
Ngày
Môn thể thao
Khu vực
CLB / Organizer
Trình độ
Giá
```

Cách này phù hợp nếu hệ thống hướng tới marketplace, nơi người chơi tìm
các buổi Social để tham gia.

------------------------------------------------------------------------

# 4. Nên cân nhắc mô hình Event-centric

Nếu thiết kế backend/domain từ đầu, có thể dùng:

``` text
Organization / Club
        │
        └── Event
              │
              ├── Tournament
              │
              └── Social
```

Ví dụ:

``` text
Organization
ID: 100
Name: Friendly Pickleball
```

↓

``` text
Event
ID: 10001
Type: SOCIAL
Name: Pickleball 1 - 2
Start: 16/09 14:00
End: 16/09 17:00
Price: 40,000
Capacity: 20
```

và:

``` text
Event
ID: 10002
Type: SOCIAL
Name: Pickleball 1 - 2
Start: 16/09 17:00
End: 16/09 22:00
Price: 60,000
Capacity: 20
```

------------------------------------------------------------------------

# 5. UI nếu app thiên về quản lý CLB

Navigation có thể là:

``` text
Trang chủ
Giải đấu
CLB
Social
Tài khoản
```

User vào:

``` text
CLB
 ↓
Friendly Pickleball
 ↓
Social
```

Màn hình có thể giữ gần như nguyên UX của ảnh:

``` text
┌─────────────────────────────────────┐
│ ← Friendly Pickleball               │
│                                     │
│  Tổng quan   Giải đấu   Social      │
└─────────────────────────────────────┘

        Social hôm nay

┌──────────┬──────────┬──────────┐
│ Hôm nay  │  T5      │  T6      │
│ 16/09    │ 17/09    │ 18/09    │
└──────────┴──────────┴──────────┘

Đang diễn ra · 1 sự kiện

┌─────────────────────────────────────┐
│ 🔴 LIVE     🎟 Xé vé     #14597    │
│                                     │
│ 14:00        Pickleball 1 - 2      │
│  |                                  │
│ 17:00        40.000đ / vé           │
│                                     │
│             12 / 20 người           │
│                                     │
│ [ Xem chi tiết ]                    │
│                                     │
│       −   4   +                     │
│                                     │
│ 160.000đ (4 vé)                     │
│                                     │
│          [ Thanh toán ]             │
└─────────────────────────────────────┘
```

Ở đây chỉ cần thay context:

``` text
Chi nhánh sân
```

bằng:

``` text
CLB / Organizer
```

------------------------------------------------------------------------

# 6. Nhưng CLB có thực sự phải là trung tâm không?

Đây là điểm cần xác định từ nghiệp vụ.

Câu hỏi quan trọng là:

> User đang muốn tìm Social của ai?

Có 3 trường hợp.

## Trường hợp 1 --- User là member của một CLB

Ví dụ:

``` text
Tôi thuộc Friendly Pickleball
```

Khi đó CLB là context:

``` text
Friendly Pickleball
 ├── Giải đấu
 ├── Social
 └── Thành viên
```

## Trường hợp 2 --- User muốn tìm Social bất kỳ

Ví dụ:

> Tối nay có Social Pickleball nào không?

Khi đó không nên bắt user chọn CLB.

Nên:

``` text
Social
 ↓
Ngày
 ↓
Danh sách tất cả Social
```

Có thể filter:

``` text
Môn thể thao
Khu vực
CLB / Organizer
Trình độ
Giá
```

## Trường hợp 3 --- User là Club Manager

Ví dụ:

> Tôi muốn tổ chức Social cho CLB của tôi.

Khi đó context là:

``` text
My Club
 ↓
Social Management
 ↓
Create Social
```

------------------------------------------------------------------------

# 7. Nên tách 2 flow

Đây là điểm quan trọng.

## Flow A --- Người chơi mua vé

Không nhất thiết cần CLB làm entry point:

``` text
Home
 ↓
Social
 ↓
Ngày hôm nay
 ↓
List Social
 ↓
Social Detail
 ↓
Chọn số vé
 ↓
Thanh toán
```

UI có thể là:

``` text
Social

[ Hôm nay 16/09 ] [ T5 17/09 ] [ T6 18/09 ]

Filter:
[ Môn ▼ ] [ Khu vực ▼ ] [ Trình độ ▼ ]

Đang diễn ra

┌─────────────────────────────┐
│ 🔴 LIVE                     │
│ Friendly Pickleball         │
│ Pickleball 1 - 2            │
│ 14:00 - 17:00               │
│ 40.000đ / vé                │
│ 12/20                       │
│                             │
│              [ Xem ]        │
└─────────────────────────────┘
```

## Flow B --- Club Manager quản lý Social

CLB trở thành context:

``` text
My Club
   ↓
Quản lý
   ↓
Social
```

Ví dụ:

``` text
┌────────────────────────────────┐
│ Social                          │
│                                │
│ [ Hôm nay ] [ Tuần này ]       │
│                                │
│ + Tạo Social                   │
│                                │
│ Đang diễn ra                   │
│                                │
│ Pickleball 1 - 2               │
│ 14:00 - 17:00                  │
│ 12 / 20                        │
│                                │
│ [ Quản lý ]                    │
└────────────────────────────────┘
```

Manager bấm:

``` text
+ Tạo Social
```

→

``` text
Tên Social
Môn thể thao
Ngày
Giờ bắt đầu
Giờ kết thúc
Địa điểm
Số người tối đa
Giá vé
Trình độ
```

→ Create.

------------------------------------------------------------------------

# 8. Data model không nên phụ thuộc vào Branch

Không nên thiết kế:

``` text
Branch
  └── Social
```

và cũng không nên:

``` text
Tournament
  └── Social
```

Một hướng tốt hơn:

``` text
Organization / Club
       │
       │
       ▼
      Event
       │
       ├──────────────┐
       │              │
       ▼              ▼
 Tournament         Social
```

Ví dụ:

``` text
Event
--------------------
id
organizationId
type
name
sportId
startAt
endAt
venueId
capacity
price
status
createdAt
```

Có thể có enum:

``` csharp
public enum EventType
{
    Tournament,
    Social
}
```

Sau đó:

``` text
Social
-----
eventId
skillLevel
ticketType
...
```

và:

``` text
Tournament
----------
eventId
registrationStart
registrationEnd
...
```

------------------------------------------------------------------------

# 9. Địa điểm cũng không nhất thiết phải là Branch

Social có thể tổ chức ở:

``` text
Sân A
Sân B
Nhà thi đấu X
CLB Y
Địa điểm tự do
```

Do đó có thể dùng:

``` text
Event
   ↓
Venue
```

thay vì:

``` text
Event
   ↓
Branch
```

Ví dụ:

``` text
Venue
----------------
id
name
address
latitude
longitude
```

Sau này có thể mở rộng:

``` text
Venue
 └── Facility
      ├── Court 1
      ├── Court 2
      ├── Court 3
      └── Court 4
```

------------------------------------------------------------------------

# 10. Domain tổng thể

Theo hướng hệ thống CLB + Tournament:

``` text
                    ┌──────────────┐
                    │ Organization │
                    │     / Club   │
                    └──────┬───────┘
                           │
                           │
                    ┌──────▼───────┐
                    │     Event    │
                    └──────┬───────┘
                           │
              ┌────────────┴────────────┐
              │                         │
       ┌──────▼──────┐           ┌──────▼──────┐
       │  Tournament │           │    Social   │
       └──────┬──────┘           └──────┬──────┘
              │                         │
       ┌──────▼──────┐           ┌──────▼──────┐
       │ Registration│           │   Ticket    │
       └──────┬──────┘           └──────┬──────┘
              │                         │
       ┌──────▼──────┐           ┌──────▼──────┐
       │   Match     │           │ Participant │
       └─────────────┘           └─────────────┘
```

Còn:

``` text
Event
  │
  └── Venue
```

để biết Social/Tournament diễn ra ở đâu.

------------------------------------------------------------------------

# 11. Không nên biến Social thành con của Tournament

Không nên thiết kế:

``` text
Tournament
 ├── Social
 ├── Match
 ├── Registration
 └── ...
```

chỉ vì hệ thống đang xây dựng xung quanh Tournament.

Nếu làm vậy sẽ phát sinh các câu hỏi nghiệp vụ:

-   Social có cần tạo Tournament không?
-   Social giao lưu 20 người có cần bracket không?
-   Social hàng tuần có phải là Tournament không?
-   Một CLB tổ chức Social mỗi tối thì có tạo hàng trăm Tournament
    không?

Domain sẽ bị lệch.

------------------------------------------------------------------------

# 12. Mô hình đề xuất

Nếu mục tiêu của app là:

> CLB → tổ chức giải đấu giao lưu → xếp cặp → đánh → xem kết quả

thì có thể hình dung:

``` text
                 CLUB
                  │
          ┌───────┴────────┐
          │                │
          ▼                ▼
     TOURNAMENT          SOCIAL
          │                │
          │                │
       MATCH            TICKET
          │                │
       RESULT          PARTICIPANT
```

Nếu muốn generic hơn:

``` text
                 CLUB
                  │
                  ▼
                 EVENT
              /         \
             /           \
       TOURNAMENT       SOCIAL
```

Nếu hệ thống xác định sẽ phát triển thêm các loại hoạt động như:

``` text
Tournament
Social
Training
Friendly Match
League
Workshop
...
```

thì `Event` chung sẽ phù hợp hơn.

------------------------------------------------------------------------

# 13. Flutter architecture đề xuất

Nên có hai entry point.

``` text
User
│
├── Home
│    └── Social
│         └── SocialListPage
│
└── My Club
     └── Manage
          └── Social
               └── SocialManagementPage
```

Dùng chung các màn hình:

``` text
SocialListPage
SocialDetailPage
TicketCheckoutPage
```

Ví dụ cấu trúc:

``` text
features/
└── social/
    ├── data/
    │   ├── models/
    │   ├── repositories/
    │   └── datasources/
    │
    ├── domain/
    │   ├── entities/
    │   └── repositories/
    │
    └── presentation/
        ├── pages/
        │   ├── social_list_page.dart
        │   ├── social_detail_page.dart
        │   ├── social_create_page.dart
        │   └── ticket_checkout_page.dart
        │
        └── widgets/
            ├── social_card.dart
            ├── date_selector.dart
            ├── ticket_counter.dart
            └── social_filter.dart
```

Như vậy Social trở thành một feature độc lập, không phải sub-feature của
Tournament.

------------------------------------------------------------------------

# 14. Kết luận

Nếu lấy UX trong ảnh làm reference:

### Hệ thống quản lý sân

``` text
Branch
   ↓
Social
   ↓
Social theo ngày
```

### Hệ thống CLB / Tournament

``` text
Club / Organizer
       ↓
     Event
       ↓
 ┌─────┴─────┐
Social    Tournament
```

Nhưng đối với người chơi, không nhất thiết phải:

``` text
Chọn Club → Social
```

mà nên:

``` text
Home
 ↓
Social
 ↓
Ngày hôm nay
 ↓
Danh sách Social
 ↓
Chọn vé
 ↓
Thanh toán
```

Còn đối với Club Manager:

``` text
My Club
 ↓
Quản lý Social
 ↓
Tạo / sửa / đóng Social
 ↓
Quản lý người tham gia
```

Điểm quan trọng nhất là **giữ UX của màn hình Xé vé gần như nguyên
mẫu**, nhưng thay đổi context nghiệp vụ: `Branch` không cần có một
entity thay thế trực tiếp. `Social` nên là một hoạt động/sự kiện độc
lập, có thể thuộc `Club/Organizer`, và nếu cần generic hơn thì nằm dưới
một abstraction `Event`.
