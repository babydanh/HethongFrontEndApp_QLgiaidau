# ⚠️ DANH SÁCH API CÒN THIẾU (LACK OF API FOR MOBILE)

Dưới đây là các API cần thiết để hoàn thiện ứng dụng di động Flutter (theo đặc tả của `baseline.vn`) nhưng chưa được triển khai hoàn chỉnh hoặc chưa được thiết kế endpoint trong NestJS Backend hiện tại:

---

## 1. Đăng ký Device Token cho Thông báo Đẩy (Push Notifications Device Token)
Hiện tại Backend mới chỉ lưu và đẩy thông báo qua Database & WebSockets (`notifications.gateway.ts`). Để nhận được thông báo đẩy (Push Notification) native trên di động ngay cả khi tắt app, ta cần API đăng ký thiết bị với FCM (Firebase Cloud Messaging).

- **Mục đích:** Đăng ký hoặc huỷ đăng ký token FCM/APNs của thiết bị di động.
- **Endpoint đề xuất:** `POST /api/v1/notifications/devices`
- **Method:** `POST`
- **Headers:**
  ```http
  Authorization: Bearer <your_access_token>
  ```
- **Request Body:**
  ```json
  {
    "deviceToken": "fcm_token_string_here...",
    "platform": "ANDROID" // hoặc "IOS"
  }
  ```

---

## 2. Xác nhận / Từ chối phân công Trọng tài (Referee Assignment Consent)
Hiện tại, Ban tổ chức gán trọng tài cho trận đấu qua API `PATCH /api/v1/matches/:id/schedule`. Tuy nhiên, chưa có API để trọng tài nhận được lịch phân công và bấm **Đồng ý / Từ chối** bắt chính trận đấu đó.

- **Mục đích:** Trọng tài xác nhận tham gia làm nhiệm vụ.
- **Endpoint đề xuất:** `PATCH /api/v1/matches/:id/referee-status`
- **Method:** `PATCH`
- **Headers:**
  ```http
  Authorization: Bearer <referee_access_token>
  ```
- **Request Body:**
  ```json
  {
    "assignmentStatus": "ACCEPTED" // hoặc "DECLINED", "PENDING"
  }
  ```

---

## 3. Check-in Vận động viên bằng mã QR (VĐV Điểm danh tại sân)
Để hỗ trợ trọng tài hoặc BTC điểm danh VĐV nhanh chóng tại sân thi đấu trước giờ đấu qua App di động.

- **Mục đích:** Quét mã QR trên màn hình VĐV để check-in trực tiếp vào trận/giải đấu.
- **Endpoint đề xuất:** `POST /api/v1/tournaments/:id/participants/:participantId/checkin`
- **Method:** `POST`
- **Headers:**
  ```http
  Authorization: Bearer <referee_or_organizer_token>
  ```
- **Response Body (200 OK):**
  ```json
  {
    "success": true,
    "checkedInAt": "2026-06-16T22:20:00.000Z"
  }
  ```

---

## 4. API Đồng bộ dữ liệu Offline (Offline Synchronization)
Trường hợp trọng tài nhập điểm tại các sân đấu có sóng 3G/4G yếu hoặc mất kết nối mạng cục bộ.

- **Mục đích:** Đồng bộ hàng loạt kết quả trận đấu được lưu tạm thời (Offline SQLite Cache) từ thiết bị di động lên máy chủ ngay khi có mạng trở lại.
- **Endpoint đề xuất:** `POST /api/v1/matches/sync-offline`
- **Method:** `POST`
- **Headers:**
  ```http
  Authorization: Bearer <referee_access_token>
  ```
- **Request Body:**
  ```json
  {
    "syncData": [
      {
        "matchId": "match-uuid-1",
        "score1": 21,
        "score2": 18,
        "isCompleted": true,
        "completedAt": "2026-06-16T22:00:00.000Z"
      }
    ]
  }
  ```
