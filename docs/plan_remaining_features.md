# 📋 Plan Import Excel + Create Tournament Wizard

> **Ngày:** 30/06/2026
> **Tuân thủ:** SKILLS.md (SOLID, Clean Architecture, Riverpod, AppLogger, Error Handling)

---

## A. Import Excel UI

### Yêu cầu
- Chọn file Excel/CSV → parse → preview danh sách đội → confirm import
- Gọi API `POST /tournaments/:id/teams/import` (đã có trong `api_team_repository.dart`)

### Files cần tạo

| File | Chức năng |
|------|-----------|
| `features/teams/widgets/import_excel_sheet.dart` | Bottom sheet: chọn file, preview, confirm |
| `features/teams/providers/import_team_provider.dart` | State: file, parsed data, loading, error |

### UI Flow
```
1. Bấm "Import Excel" → showModalBottomSheet
2. Chọn file (file_picker) → parse (excel package)
3. Preview: Grid/List các đội đã parse
4. Checkbox: chọn/bỏ đội
5. Bấm "Import" → gọi API → success/error
6. Dismiss sheet → refresh team list
```

---

## B. Create Tournament Wizard

### Yêu cầu
Thay thế màn hình create hiện tại (3 fields) bằng multi-step wizard:
- **Step 1:** Thông tin cơ bản (tên, mô tả)
- **Step 2:** Cấu hình thể thức (môn, matchType, bracketType, hạng mục/giới tính)
- **Step 3:** Divisions (thêm nhiều division: tên, matchType, giới tính, entryFee)
- **Step 4:** Lịch + Địa điểm (startDate, endDate, location, hạn đăng ký)
- **Step 5:** Review + Xác nhận

### Files cần tạo

| File | Chức năng |
|------|-----------|
| `features/tournament/widgets/wizard/step_basic_info.dart` | Step 1 |
| `features/tournament/widgets/wizard/step_format_config.dart` | Step 2 |
| `features/tournament/widgets/wizard/step_divisions.dart` | Step 3 |
| `features/tournament/widgets/wizard/step_schedule.dart` | Step 4 |
| `features/tournament/widgets/wizard/step_review.dart` | Step 5 |
| `features/tournament/providers/create_tournament_provider.dart` | Wizard state |

### UI Flow
```
Step 1: [Tên giải] [Mô tả]
   ↓ Next
Step 2: [Môn: Badminton/Tennis/Pickleball] [Loại: Đơn/Đôi]
        [Thể thức: Single/Double/RoundRobin] [Hạng mục: Nam/Nữ/Mixed]
   ↓ Next
Step 3: [Thêm division: Tên, matchType, gender, fee, maxTeams]
        Danh sách divisions đã thêm
   ↓ Next
Step 4: [Ngày bắt đầu] [Ngày kết thúc] [Hạn đăng ký]
        [Địa điểm] [Phí tham gia]
   ↓ Next
Step 5: Review tất cả → [Tạo giải đấu]
```

---

## Thứ tự ưu tiên

1. **Import Excel** — dễ hơn, file_picker + excel package đã có
2. **Create Wizard** — khó hơn, cần refactor create screen hiện tại
