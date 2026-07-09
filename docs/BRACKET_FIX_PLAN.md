# Kế Hoạch Fix Hệ Thống Bracket

> Ngày: 2026-07-08
> Dựa trên research từ 2 subagent phân tích Flutter app + Backend API

---

## Tổng Quan Các Vấn Đề

### 🔴 Nghiêm Trọng (4 vấn đề)

| # | Vấn đề | File | Ảnh hưởng |
|---|--------|------|-----------|
| 1 | Flutter gọi sai API: `/matches` thay vì `/tournaments/:id/bracket` | `api_match_repository.dart` | Mất cấu trúc stages/groups/branches → Double Elimination không có nhánh thắng/thua |
| 2 | Parse sai field: `matchNumber` thay vì `matchOrder` | `api_match_repository.dart:308` | Mọi match đều `matchNumber=1` → placement sai |
| 3 | Không parse `bracketBranch` từ API | `api_match_repository.dart` | Double Elimination không biết MAIN/LOSERS/GRAND_FINALS |
| 4 | Không parse `isBye` từ API | `api_match_repository.dart` | BYE match không được phát hiện |

### 🟡 Trung Bình (4 vấn đề)

| # | Vấn đề | File | Ảnh hưởng |
|---|--------|------|-----------|
| 5 | Dead code: `_buildBracketTree`, import `graphview` | `bracket_view_screen.dart` | Code rác ~200 dòng, import thừa |
| 6 | Typo "NHANH TUA" → "NHANH THUA" | `double_elim_diagram.dart:200,250,251` | UI sai chính tả |
| 7 | BYE-vs-BYE không được filter | `single_elim_diagram.dart` | Hiển thị match "Miễn đấu vs Miễn đấu" |
| 8 | Status `WALKOVER` không được map | `api_match_repository.dart:314` | BYE match hiển thị sai trạng thái |

---

## Kế Hoạch Fix Chi Tiết

### Giai Đoạn 1: Fix API Client (Critical)

#### 1.1 Sửa `api_match_repository.dart`

**File:** `lib/data/repositories/api/api_match_repository.dart`

**a) Sửa field name `matchNumber` → `matchOrder`** (dòng ~308, 365)

```dart
// TRƯỚC (sai):
matchNumber: (json['matchNumber'] ?? 1),

// SAU (đúng):
matchNumber: (json['matchOrder'] ?? json['matchNumber'] ?? 1),
```

**b) Thêm parse `bracketBranch`** (dòng ~310)

```dart
// XÓA:
bracketPosition: const BracketPosition(round: 1, position: 0),

// THAY BẰNG:
bracketPosition: json['bracketBranch'] != null
  ? BracketPosition(
    bracket: _mapBracketBranch(json['bracketBranch']),
    round: json['roundNumber'] ?? 1,
    position: json['matchOrder'] ?? 0,
  )
  : const BracketPosition(round: 1, position: 0),
```

**c) Thêm hàm map bracket branch**

```dart
String _mapBracketBranch(String? branch) {
  switch (branch?.toUpperCase()) {
    case 'MAIN': return 'winners';
    case 'LOSERS': return 'losers';
    case 'GRAND_FINALS': return 'grand_final';
    default: return 'winners';
  }
}
```

**d) Thêm parse `isBye`**

```dart
// THÊM field vào constructor:
final bool isBye;

// THÊM vào fromJson:
isBye: json['isBye'] ?? json['is_bye'] ?? false,
```

**e) Sửa status mapping cho WALKOVER**

```dart
// TRƯỚC (thiếu WALKOVER):
status: json['status'] == 'ONGOING' ? 'live' 
  : json['status'] == 'COMPLETED' ? 'completed' 
  : 'scheduled',

// SAU (dùng hàm map):
status: _mapMatchStatus(json['status']),

// THÊM hàm:
String _mapMatchStatus(String? status) {
  switch (status?.toUpperCase()) {
    case 'ONGOING': return 'live';
    case 'IN_PROGRESS': return 'live';
    case 'COMPLETED': return 'completed';
    case 'WALKOVER': return 'walkover';
    case 'CANCELLED': return 'cancelled';
    default: return 'scheduled';
  }
}
```

#### 1.2 Sửa `MatchModel` entity

**File:** `lib/domain/entities/match.dart`

```dart
// THÊM field isBye:
final bool isBye;

// SỬA constructor:
const MatchModel({
  // ... existing fields
  this.isBye = false,
});

// SỬA fromJson:
isBye: json['isBye'] ?? json['is_bye'] ?? false,
```

---

### Giai Đoạn 2: Fix UI Bugs

#### 2.1 Sửa typo `double_elim_diagram.dart`

**File:** `lib/features/bracket/widgets/double_elim_diagram.dart`

| Dòng | Trước (sai) | Sau (đúng) |
|------|-------------|------------|
| 200 | `'▼ NHANH TUA'` | `'▼ NHÁNH THUA'` |
| 250 | `'CK NHANH TUA'` | `'CK NHÁNH THUA'` |
| 251 | `'BK NHANH TUA'` | `'BK NHÁNH THUA'` |

#### 2.2 Thêm BYE-vs-BYE filter

**File:** `single_elim_diagram.dart` — trong `_buildRoundMap`

```dart
final valid = widget.matches.where((m) {
  if (m.status == 'cancelled') return false;
  if (m.isBye || (m.team1Id == 'BYE' && m.team2Id == 'BYE')) return false;
  return true;
}).toList();
```

**File:** `double_elim_diagram.dart` — trong `_buildBands`

```dart
final valid = widget.matches
  .where((m) => m.status != 'cancelled' 
    && !(m.isBye || (m.team1Id == 'BYE' && m.team2Id == 'BYE')))
  .toList();
```

---

### Giai Đoạn 3: Dọn Dẹp Code + Xóa graphview

#### 3.1 Xóa `graphview` khỏi `pubspec.yaml`

```yaml
# XÓA dòng:
graphview: ^1.5.1
```

#### 3.2 Xóa dead code trong `bracket_view_screen.dart`

**File:** `lib/features/bracket/screens/bracket_view_screen.dart`

**Xóa:**
- `import 'package:graphview/GraphView.dart';` (dòng 8)
- `import 'package:app_quanly_giaidau/core/services/bracket_graph_service.dart';` (dòng 9)
- Class `SeparatedBuchheimWalkerAlgorithm` (dòng 20-63) — toàn bộ class
- Method `_buildBracketTree()` (dòng ~1077-1182) — toàn bộ method
- Tham chiếu đến `_buildBracketTree` trong `_buildBracketViewer` (dòng 958-960)

**Sửa `_buildBracketViewer`:**

```dart
Widget _buildBracketViewer() {
  if (isRoundRobin) {
    return _buildHorizontalRounds();
  } else {
    // Single/Double Elimination → mở diagram screen
    return BracketDiagramScreen(
      matches: matches,
      tournamentId: widget.tournamentId,
      bracketType: bracketType,
    );
  }
}
```

---

### Giai Đoạn 4: Gọi API `/bracket` (Nâng Cao)

#### 4.1 Thêm endpoint vào `api_tournament_repository.dart`

```dart
Future<BracketData?> getBracket(String tournamentId) async {
  final response = await dio.get('/tournaments/$tournamentId/bracket');
  if (response.statusCode == 200 && response.data['data'] != null) {
    return BracketData.fromJson(response.data['data']);
  }
  return null;
}
```

#### 4.2 Tạo model `BracketData`

```dart
class BracketData {
  final List<BracketStage> stages;
  // ...
}

class BracketStage {
  final String name;
  final String type;
  final int order;
  final List<BracketGroup> groups;
}

class BracketGroup {
  final String name;
  final List<MatchModel> matches;
}
```

#### 4.3 Chuyển `bracket_view_screen.dart` sang dùng API `/bracket`

Thay vì gọi `matchesProvider(tournamentId)` (trả về list phẳng), gọi `bracketProvider(tournamentId)` (trả về cấu trúc stages → groups → matches).

---

## Thứ Tự Ưu Tiên

| Bước | Công việc | File | Thời gian |
|------|-----------|------|-----------|
| **1** | Sửa `matchOrder` + `bracketBranch` + `isBye` + `WALKOVER` | `api_match_repository.dart` | 15 phút |
| **2** | Thêm field `isBye` vào `MatchModel` | `domain/entities/match.dart` | 5 phút |
| **3** | Sửa typo "NHANH TUA" | `double_elim_diagram.dart` | 5 phút |
| **4** | Thêm BYE filter | `single_elim_diagram.dart`, `double_elim_diagram.dart` | 10 phút |
| **5** | Xóa graphview + dead code | `bracket_view_screen.dart`, `pubspec.yaml` | 15 phút |
| **6** | Gọi API `/bracket` (nếu cần) | `api_tournament_repository.dart` + model mới | 30 phút |

**Tổng thời gian:** ~45 phút (bước 1-5) hoặc ~80 phút (cả bước 6)

---

## Kiểm Tra Sau Khi Fix

1. `flutter test` — tất cả Pass ✅
2. Chạy seed backend → generate bracket → match data đúng field
3. Mở Flutter app → kiểm tra 3 loại bracket:
   - **Single Elim:** cây dọc, có nhánh rõ ràng, BYE ẩn
   - **Double Elim:** nhánh Thắng + nhánh Thua, không còn "NHANH TUA"
   - **Round Robin:** cross table + bảng xếp hạng + lịch thi đấu
4. BYE match: không hiển thị (hoặc hiển thị "Miễn đấu")

---

## Ghi Chú

- `graphview` không cần thiết — có thể xóa khỏi dự án
- Flutter hiện tại dùng `CustomPainter` tự vẽ → đủ dùng, không cần thư viện ngoài
- Nếu gọi API `/bracket`, cần parse thêm model `BracketData`, `BracketStage`, `BracketGroup`
