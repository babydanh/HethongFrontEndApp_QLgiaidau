# 📋 SPEC — Đặc tả chức năng chi tiết

---

## 1. Hệ thống Token & Xác thực

### 1.1 Tạo Token
- Khi Admin tạo giải đấu mới, hệ thống **tự động sinh 3 token**:
  - `ADM-XXXX-XXXX` → Quyền Admin
  - `REF-XXXX-XXXX` → Quyền Trọng tài
  - `VWR-XXXX-XXXX` → Quyền Viewer
- Token gồm **8 ký tự alphanumeric** + prefix vai trò, dễ nhập thủ công
- Token được lưu trong Firestore collection `tokens`
- Admin có thể **tái tạo (regenerate)** token bất cứ lúc nào
- Admin có thể **vô hiệu hóa (deactivate)** token

### 1.2 Nhập Token
- Màn hình đầu tiên khi mở app: **ô nhập token**
- Không có đăng nhập email/password
- App sử dụng **Firebase Anonymous Auth** để tạo session
- Sau khi nhập token hợp lệ → App xác định vai trò → Điều hướng đến giao diện phù hợp
- Token được lưu local (SharedPreferences) để không phải nhập lại

### 1.3 Chia sẻ Token
- Admin có thể chia sẻ token qua:
  - **Copy text** → Paste qua Zalo/Messenger
  - **QR Code** → Trọng tài/khán giả quét QR để nhập token tự động
  - **Share sheet** → Chia sẻ qua các app khác

---

## 2. Quản lý Giải đấu (Admin)

### 2.1 Tạo giải đấu
**Input fields:**
| Field | Type | Required | Mô tả |
|---|---|---|---|
| Tên giải | Text | ✅ | VD: "Giải Cầu lông Mùa hè 2025" |
| Môn thi đấu | Dropdown | ✅ | pickleball / badminton / football / tennis |
| Hình thức | Dropdown | ✅ | singles / doubles / team_5 / team_7 / team_11 |
| Thể thức | Dropdown | ✅ | single_elimination / double_elimination / round_robin |
| Số đội tối đa | Number | ✅ | 4, 8, 16, 32, 64 |
| Mô tả | Text | ❌ | Ghi chú thêm |

**Sau khi tạo:**
- Giải ở trạng thái `draft`
- 3 Token được sinh tự động
- Chuyển đến màn hình chi tiết giải

### 2.2 Trạng thái giải đấu (State Machine)

```
draft → registration → drawing → in_progress → completed
  ↑                                                  │
  └──────────── reset (admin can reset) ─────────────┘
```

| Trạng thái | Mô tả | Hành động được phép |
|---|---|---|
| `draft` | Mới tạo, chưa bắt đầu | Sửa thông tin, thêm đội |
| `registration` | Đang đăng ký | Thêm/sửa/xóa đội, import |
| `drawing` | Đang bốc thăm | Bốc thăm tự động/thủ công |
| `in_progress` | Đang thi đấu | Nhập điểm, xem bracket |
| `completed` | Đã kết thúc | Xem kết quả, xuất PDF |

---

## 3. Quản lý Đội/VĐV (Admin)

### 3.1 Nhập thủ công
- Form đơn giản: Tên đội + Danh sách thành viên
- Cho phép thêm ảnh đội (optional, upload Firebase Storage)
- Cho phép thêm email liên hệ

### 3.2 Import từ File
**Hỗ trợ format:**
- `.csv` — Comma-separated values
- `.xlsx` — Microsoft Excel

**Cấu trúc file mẫu:**
```
Tên đội,      Thành viên 1,    Thành viên 2,   Email
Đội Sấm sét,  Nguyễn Văn A,   Trần Văn B,     a@gmail.com
Đội Bão tố,   Lê Thị C,       Phạm Văn D,     c@gmail.com
```

**Flow import:**
1. Bấm "Import" → Chọn file
2. App parse file → Hiển thị preview danh sách
3. Admin kiểm tra → Xác nhận import
4. Dữ liệu được ghi lên Firestore

### 3.3 QR Check-in (Optional)
- App sinh QR code chứa ID nội bộ cho mỗi VĐV
- Ngày thi đấu: Quét QR → Đánh dấu "Có mặt"
- QR code có thể chia sẻ/in ra

---

## 4. Bốc thăm & Phân bảng

### 4.1 Bốc thăm tự động (Automated Random)
- Hệ thống sử dụng thuật toán **Fisher-Yates Shuffle**
- Xáo trộn toàn bộ danh sách → Phân vào các cặp/bảng
- Hỗ trợ **seeding** (hạt giống): Đội hạt giống sẽ được rải đều, không gặp nhau ở vòng đầu
- Kết quả bốc thăm hiển thị ngay lập tức

### 4.2 Bốc thăm thủ công (Interactive Manual Draw)
- Giao diện "rút thăm" trực quan:
  1. Hiển thị danh sách các đội chưa bốc
  2. Admin/đại diện đội bấm "Rút thăm"
  3. Animation xáo trộn → Hiện vị trí bốc được
  4. Lặp lại cho đến khi hết
- Có thể bốc thăm cho từng vòng riêng (tứ kết, bán kết...)
- **Hiệu ứng animation** tăng tính kịch tính khi chiếu lên màn hình lớn

### 4.3 Phân bảng (Round Robin)
- Nếu chọn Round Robin: Chia đội vào các bảng (Group A, B, C...)
- Số bảng tùy thuộc số đội
- Mỗi bảng thi đấu vòng tròn → Top team vào vòng knockout

---

## 5. Thể thức thi đấu

### 5.1 Single Elimination (Đấu loại trực tiếp)
```
Vòng 1          Tứ kết         Bán kết       Chung kết
Đội 1 ─┐
        ├── W1 ─┐
Đội 2 ─┘        │
                 ├── W5 ─┐
Đội 3 ─┐        │        │
        ├── W2 ─┘        │
Đội 4 ─┘                 ├── 🏆 Vô địch
Đội 5 ─┐                 │
        ├── W3 ─┐        │
Đội 6 ─┘        │        │
                 ├── W6 ─┘
Đội 7 ─┐        │
        ├── W4 ─┘
Đội 8 ─┘
```

- **Thuật toán:** Seed-based seeding, đội mạnh ở 2 đầu bracket
- **Số trận:** N-1 trận (N = số đội)
- **Bye:** Nếu số đội không phải lũy thừa 2, một số đội sẽ được BYE vòng 1

### 5.2 Double Elimination (Đấu loại kép)
- **Nhánh thắng (Winners Bracket):** Giống Single Elimination
- **Nhánh thua (Losers Bracket):** Đội thua từ nhánh thắng rơi xuống đây
- **Grand Final:** Đội vô địch nhánh thắng vs đội vô địch nhánh thua
- Phải thua **2 trận** mới bị loại → Công bằng hơn
- **Số trận:** 2N-2 đến 2N-1 trận

### 5.3 Round Robin (Vòng tròn)
- Mỗi đội gặp tất cả đội khác trong bảng **1 lần**
- Tính điểm: Thắng = 3 điểm, Hòa = 1, Thua = 0
- Xếp hạng theo: Điểm > Hiệu số > Đối đầu trực tiếp
- **Số trận mỗi bảng:** n(n-1)/2 (n = số đội trong bảng)

---

## 6. Nhập điểm & Real-time

### 6.1 Giao diện nhập điểm
- Dành cho **Admin** và **Trọng tài**
- Hiển thị: Tên 2 đội + Điểm hiện tại
- Nút **+1 / -1** cho mỗi đội (bấm nhanh)
- Hỗ trợ nhập điểm theo **set** (Cầu lông: Best of 3 sets)
- Nút "Kết thúc trận" → Xác định người thắng → Cập nhật bracket

### 6.2 Real-time Updates
- Sử dụng **Firestore Realtime Listeners** (snapshots)
- Khi điểm thay đổi → Tất cả Viewer nhận update **ngay lập tức** (< 1 giây)
- Bracket tự động cập nhật khi trận kết thúc
- Không cần F5 hay refresh

### 6.3 Màn hình Live (Viewer)
- Hiển thị **bracket tổng quan** với điểm real-time
- Highlight trận đang diễn ra (status = `live`)
- Animation khi có thay đổi điểm
- Tối ưu cho xem trên **projector/TV lớn**

---

## 7. Kết quả & Xuất PDF

### 7.1 Bảng kết quả
- Hiển thị thứ hạng cuối cùng
- Đội vô địch, á quân, hạng 3
- Thống kê: Số trận thắng/thua, tổng điểm

### 7.2 Xuất PDF
- Bao gồm:
  - Tên giải đấu + thông tin
  - Danh sách các đội
  - Sơ đồ bracket hoàn chỉnh
  - Kết quả từng trận
  - Bảng xếp hạng cuối
- Nút "In" hoặc "Chia sẻ PDF"

---

## 8. Edge Cases & Xử lý đặc biệt

| Tình huống | Xử lý |
|---|---|
| Số đội lẻ (không phải 2^n) | Tự động BYE cho các đội thừa ở vòng 1 |
| Mất mạng giữa chừng | Firestore offline cache, sync khi có mạng lại |
| 2 người nhập điểm cùng lúc | Firestore transaction, last-write-wins |
| Token bị lộ | Admin có thể regenerate token mới |
| Đội bỏ cuộc giữa giải | Admin đánh dấu Walkover, đội đối thủ tự thắng |
