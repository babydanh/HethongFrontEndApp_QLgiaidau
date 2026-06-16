# 📡 API ENDPOINTS FOR MOBILE APP (FLUTTER)

Tài liệu này định nghĩa chi tiết các API endpoints dành riêng cho ứng dụng di động Flutter, bao gồm cấu trúc DTO (Request Body) và cấu trúc Response JSON để lập trình Client di động chuẩn xác.

---

## 1. Cơ chế Xác thực trên Mobile (Auth Protocol)

- **Đăng nhập/Refresh:** Tất cả các API Auth cho Mobile đều trả về Tokens (Access Token & Refresh Token) trực tiếp trong **JSON Response Body** (không lưu cookie như Web).
- **Gửi Token:** Ở tất cả các request yêu cầu xác thực sau đó, Client Flutter phải đính kèm Access Token vào Header `Authorization`:
  ```http
  Authorization: Bearer <your_access_token>
  ```
- **Làm mới Token:** Gửi Refresh Token qua JSON body (hoặc header `x-refresh-token`) lên endpoint `/auth/mobile/refresh`.

---

## 2. Chi tiết API Xác thực (Authentication)

### 2.1 Đăng nhập thông thường (Email & Password)
Đăng nhập bằng tài khoản và mật khẩu hệ thống.

- **URL:** `/api/v1/auth/mobile/login`
- **Method:** `POST`
- **Headers:**
  ```http
  Content-Type: application/json
  x-client-type: mobile
  ```
- **Request Body (LoginDto):**
  ```json
  {
    "email": "user@example.com",
    "password": "yourpassword123"
  }
  ```
- **Response Body (200 OK):**
  ```json
  {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "76d54fe1-bb38-48aa-b754-55cc89aa1456",
      "email": "user@example.com",
      "roles": ["PLAYER"]
    }
  }
  ```

---

### 2.2 Đăng ký tài khoản mới
Tạo tài khoản người chơi mới.

- **URL:** `/api/v1/auth/mobile/register`
- **Method:** `POST`
- **Headers:**
  ```http
  Content-Type: application/json
  ```
- **Request Body (RegisterDto):**
  ```json
  {
    "email": "user@example.com",
    "password": "yourpassword123",
    "fullName": "Nguyễn Văn A"
  }
  ```
- **Response Body (201 Created):**
  ```json
  {
    "id": "76d54fe1-bb38-48aa-b754-55cc89aa1456",
    "email": "user@example.com",
    "isEmailVerified": false,
    "isMock": false,
    "createdAt": "2026-06-16T20:20:00.000Z",
    "updatedAt": "2026-06-16T20:20:00.000Z"
  }
  ```

---

### 2.3 Đăng nhập bằng Google OAuth 2.0 (Google Sign-In)
Xác thực bằng ID Token sinh ra từ SDK Google Sign-in trên thiết bị di động.

- **URL:** `/api/v1/auth/mobile/google`
- **Method:** `POST`
- **Headers:**
  ```http
  Content-Type: application/json
  ```
- **Request Body:**
  ```json
  {
    "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjFhMmIzY..."
  }
  ```
  *(idToken là chuỗi token JWT nhận được từ SDK google_sign_in của Flutter)*
- **Response Body (200 OK):**
  - Trả về tokens hệ thống nếu verify ID Token Google thành công (tự động tạo tài khoản nếu chưa có).
  ```json
  {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "76d54fe1-bb38-48aa-b754-55cc89aa1456",
      "email": "googleuser@gmail.com",
      "roles": ["PLAYER"]
    }
  }
  ```

---

### 2.4 Làm mới Token (Refresh Token)
Lấy Access Token mới khi token cũ hết hạn (sử dụng Refresh Token lưu trong Secure Storage).

- **URL:** `/api/v1/auth/mobile/refresh`
- **Method:** `POST`
- **Headers:**
  ```http
  Content-Type: application/json
  ```
- **Request Body:**
  ```json
  {
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```
  *(Hệ thống cũng chấp nhận gửi Refresh Token qua custom header `x-refresh-token` thay vì body)*
- **Response Body (200 OK):**
  ```json
  {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "76d54fe1-bb38-48aa-b754-55cc89aa1456",
      "email": "user@example.com",
      "roles": ["PLAYER"]
    }
  }
  ```

---

## 3. Quản lý Giải đấu (Tournaments)

Các API quản lý giải đấu di động.

### 3.1 Lấy danh sách giải đấu công khai (Public Tournaments)
- **URL:** `/api/v1/tournaments/public`
- **Method:** `GET`
- **Headers:**
  ```http
  Content-Type: application/json
  ```
- **Query Parameters:**
  - `page` (optional): `number` (default: 1)
  - `limit` (optional): `number` (default: 10)
  - `search` (optional): `string`
  - `sportType` (optional): `string`
- **Response Body (200 OK):**
  ```json
  {
    "data": [
      {
        "id": "2b3c4d5e-6f7g-8h9i-0j1k-2l3m4n5o6p7q",
        "name": "Giải đấu Mùa Hè 2026",
        "description": "Giải đấu quy mô bán chuyên",
        "bannerUrl": "https://res.cloudinary.com/...",
        "status": "PUBLISHED",
        "maxParticipants": 16,
        "currentParticipants": 8,
        "startDate": "2026-07-01T08:00:00.000Z",
        "endDate": "2026-07-10T17:00:00.000Z"
      }
    ],
    "meta": {
      "totalItems": 1,
      "itemCount": 1,
      "itemsPerPage": 10,
      "totalPages": 1,
      "currentPage": 1
    }
  }
  ```

---

### 3.2 Tham gia giải đấu qua mã mời (Join Tournament via Invite Code)
- **URL:** `/api/v1/tournaments/join/:inviteCode`
- **Method:** `POST`
- **Headers:**
  ```http
  Authorization: Bearer <your_access_token>
  Content-Type: application/json
  ```
- **Request Body (RegisterTournamentDto):**
  ```json
  {
    "teamName": "Chiến binh Rồng",
    "contactPhone": "0987654321",
    "playerNames": ["Nguyễn Văn A", "Trần Văn B"]
  }
  ```
- **Response Body (201 Created):**
  ```json
  {
    "success": true,
    "message": "Tham gia giải đấu thành công.",
    "registration": {
      "id": "e4f5g6h7-i8j9-k0l1-m2n3-o4p5q6r7s8t9",
      "tournamentId": "2b3c4d5e-6f7g-8h9i-0j1k-2l3m4n5o6p7q",
      "teamName": "Chiến binh Rồng",
      "status": "APPROVED",
      "createdAt": "2026-06-16T21:00:00.000Z"
    }
  }
  ```

---

### 3.3 Lấy sơ đồ nhánh đấu (Get Tournament Bracket)
Dùng để vẽ sơ đồ thi đấu (Single/Double Elimination, Round Robin) trực tiếp trên giao diện của App.

- **URL:** `/api/v1/tournaments/:id/bracket`
- **Method:** `GET`
- **Headers:**
  ```http
  Content-Type: application/json
  ```
- **Response Body (200 OK):**
  ```json
  {
    "id": "2b3c4d5e-6f7g-8h9i-0j1k-2l3m4n5o6p7q",
    "name": "Giải đấu Mùa Hè 2026",
    "bracketType": "SINGLE_ELIMINATION",
    "rounds": [
      {
        "roundNumber": 1,
        "name": "Vòng 1/8",
        "matches": [
          {
            "id": "a1b2c3d4-e5f6-7g8h-9i0j-1k2l3m4n5o6p",
            "team1": {
              "id": "t1-uuid",
              "name": "Chiến binh Rồng"
            },
            "team2": {
              "id": "t2-uuid",
              "name": "Hổ Cánh Cụt"
            },
            "score1": 2,
            "score2": 1,
            "status": "COMPLETED",
            "nextMatchId": "next-match-uuid",
            "startTime": "2026-07-01T09:00:00.000Z"
          }
        ]
      }
    ]
  }
  ```

---

### 3.4 Lấy danh sách Vận động viên tham gia (Get Participants)
- **URL:** `/api/v1/tournaments/:id/participants`
- **Method:** `GET`
- **Headers:**
  ```http
  Content-Type: application/json
  ```
- **Response Body (200 OK):**
  ```json
  [
    {
      "id": "p1-uuid",
      "teamName": "Chiến binh Rồng",
      "status": "APPROVED",
      "rosters": [
        {
          "userId": "76d54fe1-bb38-48aa-b754-55cc89aa1456",
          "fullName": "Nguyễn Văn A"
        }
      ]
    }
  ]
  ```

---

## 4. Quản lý Trận đấu & Nhập điểm (Matches & Refereeing)

Dành cho người chơi xem lịch thi đấu và Trọng tài cập nhật kết quả/tỷ số trận đấu.

### 4.1 Lấy danh sách trận đấu (Get Matches List)
- **URL:** `/api/v1/matches`
- **Method:** `GET`
- **Headers:**
  ```http
  Content-Type: application/json
  ```
- **Query Parameters:**
  - `tournamentId` (optional): Lọc theo giải đấu cụ thể
  - `status` (optional): Lọc theo `PENDING`, `ONGOING`, `COMPLETED`
  - `refereeId` (optional): Lọc theo trọng tài được phân công
- **Response Body (200 OK):**
  ```json
  {
    "data": [
      {
        "id": "a1b2c3d4-e5f6-7g8h-9i0j-1k2l3m4n5o6p",
        "tournamentId": "2b3c4d5e-6f7g-8h9i-0j1k-2l3m4n5o6p7q",
        "team1Id": "t1-uuid",
        "team2Id": "t2-uuid",
        "score1": 0,
        "score2": 0,
        "status": "PENDING",
        "court": "Sân số 1 - Nhà thi đấu Bách Khoa",
        "startTime": "2026-07-01T09:00:00.000Z"
      }
    ]
  }
  ```

---

### 4.2 Cập nhật trạng thái trận đấu (Update Match Status)
Dành cho Ban tổ chức / Trọng tài bắt đầu trận đấu (`ONGOING`) hoặc kết thúc trận đấu.
- **URL:** `/api/v1/matches/:id/status`
- **Method:** `PATCH`
- **Headers:**
  ```http
  Authorization: Bearer <your_access_token>
  Content-Type: application/json
  ```
- **Request Body (UpdateMatchStatusDto):**
  ```json
  {
    "status": "ONGOING"
  }
  ```
- **Response Body (200 OK):**
  ```json
  {
    "id": "a1b2c3d4-e5f6-7g8h-9i0j-1k2l3m4n5o6p",
    "status": "ONGOING"
  }
  ```

---

### 4.3 Cập nhật tỷ số & Kết quả Trận đấu (Update Match Score - Trọng tài nhập điểm)
Trọng tài nhập điểm số trực tiếp từ App di động.
- **URL:** `/api/v1/matches/:id/score`
- **Method:** `PATCH`
- **Headers:**
  ```http
  Authorization: Bearer <your_access_token>
  Content-Type: application/json
  ```
- **Request Body (UpdateMatchScoreDto):**
  ```json
  {
    "score1": 21,
    "score2": 19,
    "isCompleted": true,
    "winnerId": "t1-uuid",
    "setDetails": [
      {
        "setNumber": 1,
        "score1": 21,
        "score2": 19
      }
    ]
  }
  ```
- **Response Body (200 OK):**
  - Cập nhật tỷ số trận đấu thành công và tự động đẩy đội thắng lên vòng tiếp theo trong Bracket (nếu là giải đấu Single/Double Elimination).
  ```json
  {
    "id": "a1b2c3d4-e5f6-7g8h-9i0j-1k2l3m4n5o6p",
    "score1": 21,
    "score2": 19,
    "status": "COMPLETED",
    "winnerId": "t1-uuid"
  }
  ```

---

## 5. Quản lý Hồ sơ Người dùng (User Profile)

### 4.1 Xem thông tin cá nhân (Get My Profile)
- **URL:** `/api/v1/users/profile`
- **Method:** `GET`
- **Headers:**
  ```http
  Authorization: Bearer <your_access_token>
  ```
- **Response Body (200 OK):**
  ```json
  {
    "id": "76d54fe1-bb38-48aa-b754-55cc89aa1456",
    "email": "user@example.com",
    "fullName": "Nguyễn Văn A",
    "avatarUrl": "https://res.cloudinary.com/...",
    "phoneNumber": "0987654321",
    "roles": ["PLAYER"],
    "elo": 1200,
    "createdAt": "2026-06-16T20:20:00.000Z"
  }
  ```

---

### 4.2 Cập nhật thông tin cá nhân (Update Profile)
- **URL:** `/api/v1/users/profile`
- **Method:** `PATCH`
- **Headers:**
  ```http
  Authorization: Bearer <your_access_token>
  Content-Type: application/json
  ```
- **Request Body (UpdateUserDto):**
  ```json
  {
    "fullName": "Nguyễn Văn B",
    "phoneNumber": "0900112233",
    "avatarUrl": "https://res.cloudinary.com/..."
  }
  ```
- **Response Body (200 OK):**
  ```json
  {
    "id": "76d54fe1-bb38-48aa-b754-55cc89aa1456",
    "email": "user@example.com",
    "fullName": "Nguyễn Văn B",
    "phoneNumber": "0900112233",
    "avatarUrl": "https://res.cloudinary.com/...",
    "updatedAt": "2026-06-16T21:05:00.000Z"
  }
  ```

---

## 5. Mã lỗi phổ biến (Error Responses)

Khi có lỗi, Backend luôn trả về cấu trúc lỗi tiêu chuẩn:
```json
{
  "statusCode": 401,
  "message": "Xác thực Google ID Token thất bại.",
  "error": "Unauthorized"
}
```

- **`400 Bad Request`**: Dữ liệu gửi lên không đúng định dạng DTO (ví dụ: thiếu email, mật khẩu ngắn hơn 6 ký tự...).
- **`401 Unauthorized`**: Sai thông tin đăng nhập, token hết hạn, hoặc ID Token của Google không hợp lệ/hết hạn.
- **`403 Forbidden`**: Không có quyền truy cập tài nguyên.
- **`409 Conflict`**: Email đã được đăng ký trước đó.

