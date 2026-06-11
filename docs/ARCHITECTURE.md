# 🏗️ ARCHITECTURE — Kiến trúc hệ thống

---

## 1. Sơ đồ cấu trúc thư mục (Directory Structure)

Dự án được tổ chức theo chuẩn **Clean Architecture** kết hợp **Feature-first**, giúp mã nguồn rõ ràng, dễ bảo trì và dễ mở rộng:

```text
app_quanly_giaidau/
├── pubspec.yaml               # Quản lý các dependencies (Riverpod, Firebase, GoRouter...)
├── docs/                      # 📚 TÀI LIỆU DỰ ÁN
│   ├── ARCHITECTURE.md        # Kiến trúc hệ thống
│   ├── SPEC.md                # Đặc tả yêu cầu chức năng
│   ├── PLAN.md                # Kế hoạch phát triển chi tiết
│   ├── DATABASE_SCHEMA.md     # Cấu trúc CSDL Firestore
│   └── SKILLS.md              # Bộ quy tắc & kỹ năng chuẩn xác cho AI
│
├── lib/                       # 💻 MÃ NGUỒN CHÍNH
│   ├── main.dart              # Điểm khởi đầu: Khởi tạo Firebase, bọc ProviderScope
│   ├── app.dart               # Chứa MaterialApp.router, kết nối Theme & GoRouter
│   │
│   ├── core/                  # 🛠️ VÙNG DÙNG CHUNG (Global Utilities)
│   │   ├── config/            # Cấu hình UI (AppTheme), AppConstants, FirebaseConfig
│   │   ├── router/            # Điều hướng GoRouter & Phân quyền truy cập (RoleGuard)
│   │   ├── services/          # AppLogger, Error Handler
│   │   └── utils/             # Các hàm tiện ích dùng chung (TokenGenerator, DateParser, FirestoreHelpers)
│   │
│   ├── data/                  # 💾 DATA LAYER (Lớp Dữ liệu)
│   │   ├── models/            # Các Entities (Tournament, Team, Match, Token, Standing)
│   │   └── repositories/      # Chứa các hàm giao tiếp trực tiếp với Firestore (CRUD)
│   │
│   ├── providers/             # 🔗 STATE MANAGEMENT (Riverpod)
│   │   ├── app_providers.dart # Khởi tạo các StreamProvider/FutureProvider toàn cục
│   │   ├── auth_provider.dart # Notifier quản lý trạng thái đăng nhập (Role)
│   │
│   └── features/              # 🚀 CÁC TÍNH NĂNG (Presentation Layer)
│       ├── auth/              # Màn hình Splash, Giao diện nhập Token
│       ├── tournament/        # Danh sách giải, Tạo giải mới, Bảng điều khiển giải
│       ├── teams/             # Danh sách Đội/VĐV, Thêm mới, Import từ Excel
│       ├── bracket/           # Vẽ sơ đồ nhánh thi đấu (Bracket Tree bằng graphview)
│       ├── match/             # Giao diện trọng tài cập nhật điểm (Score Input)
│       └── live/              # Màn hình cho Viewer theo dõi tỷ số Real-time
```

---

## 2. Tổng quan các Layer (Clean Architecture)

```text
┌─────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                  │
│         (Screens, Widgets, Controllers)              │
│                                                      │
│  ┌─────────┐  ┌──────────┐  ┌────────────────────┐  │
│  │ Screens │  │ Widgets  │  │ Riverpod Providers │  │
│  │ (UI)    │  │ (Shared) │  │ (State/Controller) │  │
│  └────┬────┘  └────┬─────┘  └────────┬───────────┘  │
│       │             │                 │              │
├───────┼─────────────┼─────────────────┼──────────────┤
│       │      DOMAIN LAYER             │              │
│       │  (Models, Business Logic)     │              │
│       │                               │              │
│  ┌────▼───────────────────────────────▼───────────┐  │
│  │              Data Models (Entities)             │  │
│  │  Tournament | Team | Match | Token | Standing   │  │
│  └────────────────────┬───────────────────────────┘  │
│                       │                              │
│  ┌────────────────────▼───────────────────────────┐  │
│  │            Business Logic (Utils)               │  │
│  │  BracketGenerator | RoundRobinGen | TokenGen    │  │
│  └────────────────────┬───────────────────────────┘  │
│                       │                              │
├───────────────────────┼──────────────────────────────┤
│                DATA LAYER                            │
│         (Repositories, Firebase)                     │
│                       │                              │
│  ┌────────────────────▼───────────────────────────┐  │
│  │              Repositories                       │  │
│  │  TournamentRepo | TeamRepo | MatchRepo          │  │
│  └────────────────────┬───────────────────────────┘  │
│                       │                              │
│  ┌────────────────────▼───────────────────────────┐  │
│  │           Firebase Services                     │  │
│  │  Firestore | Auth | Storage                     │  │
│  └────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## 2. Data Flow

### 2.1 Write Flow (Admin/Referee nhập điểm)

```
User tap "+1" on Score Button
        │
        ▼
ScoreInputScreen (UI)
        │
        ▼
MatchNotifier.updateScore()     ← Riverpod Notifier
        │
        ▼
MatchRepository.updateMatch()   ← Repository pattern
        │
        ▼
FirebaseFirestore.update()      ← Firestore SDK
        │
        ▼
Cloud Firestore (Server)        ← Data persisted
        │
        ▼
Real-time sync to ALL listeners ← Automatic by Firestore
```

### 2.2 Read Flow (Viewer xem real-time)

```
Cloud Firestore (Data changed)
        │
        ▼
Firestore Snapshot Listener     ← Auto-triggered
        │
        ▼
MatchRepository.watchMatches()  ← Stream<List<Match>>
        │
        ▼
StreamProvider (Riverpod)       ← Auto rebuild UI
        │
        ▼
BracketViewScreen (UI updated)  ← User sees new score instantly
```

---

## 3. State Management (Riverpod)

### 3.1 Provider Architecture

```dart
// === AUTH ===
// Quản lý trạng thái xác thực token
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  ITokenRepository get _repo => ref.read(tokenRepositoryProvider);

  Future<bool> validateToken(String code) async {
    state = state.copyWith(status: AuthStatus.validating);
    // ... logic xác thực
  }
}

// === TOURNAMENT ===
// Stream realtime danh sách giải đấu
final tournamentsProvider = StreamProvider<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).watchAll();
});

// Chi tiết 1 giải đấu
final tournamentProvider = StreamProvider.family<Tournament, String>((ref, id) {
  return ref.watch(tournamentRepositoryProvider).watch(id);
});

// === TEAMS ===
// Stream danh sách đội trong 1 giải
final teamsProvider = StreamProvider.family<List<Team>, String>((ref, tournamentId) {
  return ref.watch(teamRepositoryProvider).watchByTournament(tournamentId);
});

// === MATCHES ===
// Stream danh sách trận đấu (REAL-TIME cho viewer)
final matchesProvider = StreamProvider.family<List<Match>, String>((ref, tournamentId) {
  return ref.watch(matchRepositoryProvider).watchByTournament(tournamentId);
});

// Trận đang live
final liveMatchesProvider = StreamProvider.family<List<Match>, String>((ref, tournamentId) {
  return ref.watch(matchRepositoryProvider).watchLive(tournamentId);
});
```

### 3.2 Auth State Machine

```dart
enum AuthStatus {
  unauthenticated,   // Chưa nhập token
  validating,        // Đang kiểm tra token
  authenticated,     // Token hợp lệ
  invalid,           // Token không đúng / hết hạn
}

class AuthState {
  final AuthStatus status;
  final UserRole? role;        // admin | referee | viewer
  final String? tournamentId;  // Giải đấu token thuộc về
  final String? tokenCode;     // Token code đã nhập
}
```

---

## 4. Navigation (GoRouter)

### 4.1 Route Structure

```
/                           → SplashScreen
/auth                       → TokenEntryScreen
/admin                      → AdminDashboard
/admin/tournament/:id       → TournamentDetailScreen
/admin/tournament/:id/teams → TeamListScreen
/admin/tournament/:id/draw  → DrawScreen
/admin/tournament/:id/bracket → BracketViewScreen
/admin/tournament/:id/match/:matchId → ScoreInputScreen
/referee                    → RefereeMatchList
/referee/match/:matchId     → ScoreInputScreen
/viewer                     → ViewerBracketScreen
/viewer/live                → LiveMatchScreen
```

### 4.2 Route Guards

```dart
// Redirect dựa trên role
GoRouter(
  redirect: (context, state) {
    final auth = ref.read(authProvider);

    // Chưa auth → về trang nhập token
    if (auth.status != AuthStatus.authenticated) {
      return '/auth';
    }

    // Đã auth nhưng vào route không đúng role
    if (state.matchedLocation.startsWith('/admin') && auth.role != UserRole.admin) {
      return '/viewer';
    }

    return null; // Không redirect
  },
);
```

---

## 5. Firebase Architecture

### 5.1 Firestore Collections

```
Root
├── tournaments/          ← Giải đấu
│   └── {tournamentId}/
│       ├── teams/        ← Đội/VĐV (subcollection)
│       ├── matches/      ← Trận đấu (subcollection)
│       └── standings/    ← Bảng xếp hạng (subcollection)
│
└── tokens/               ← Token xác thực (top-level)
```

### 5.2 Tại sao subcollection?

| Approach | Ưu | Nhược |
|---|---|---|
| Subcollection ✅ | Query scoped theo giải, Security rules dễ viết, Không cần index phức tạp | Không query cross-tournament dễ |
| Top-level collection | Query cross-tournament | Security rules phức tạp, Index nhiều |

→ Chọn **subcollection** vì mỗi entity (team, match) luôn thuộc về 1 giải.

### 5.3 Offline Cache

```dart
// Enable Firestore offline persistence (mặc định đã bật)
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

- Khi mất mạng → Đọc từ cache
- Khi có mạng lại → Auto sync
- Write khi offline → Queue lại, sync khi online

---

## 6. Thuật toán Core

### 6.1 Bracket Generator (Single Elimination)

```dart
/// Input: List<Team> teams (đã shuffle hoặc seeded)
/// Output: List<Match> matches (đầy đủ bracket)
///
/// Thuật toán:
/// 1. Tính số vòng: rounds = log2(nextPowerOf2(teams.length))
/// 2. Tạo bracket size = 2^rounds
/// 3. Seed teams vào bracket positions
/// 4. Fill BYE cho vị trí trống
/// 5. Sinh matches cho từng vòng
/// 6. Link nextMatchId giữa các vòng
```

### 6.2 Double Elimination

```dart
/// Gồm 2 nhánh:
/// - Winners Bracket: Giống Single Elimination
/// - Losers Bracket: Nhận đội thua từ Winners
///
/// Flow:
/// W-Round1 losers → L-Round1
/// W-Round2 losers → L-Round2
/// ...
/// Winners Final vs Losers Final → Grand Final
```

### 6.3 Round Robin Scheduler

```dart
/// Sử dụng thuật toán "Circle Method"
/// Input: n teams
/// Output: n-1 rounds, mỗi round có n/2 matches
///
/// Cố định team[0], rotate các team còn lại
/// Round k: team[i] vs team[n-1-i] (sau rotate k lần)
```

---

## 7. Error Handling Strategy

```dart
// Sealed class cho Result pattern
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;
  const Failure(this.message, [this.exception]);
}

// Usage trong Repository
Future<Result<Tournament>> createTournament(Tournament t) async {
  try {
    await _firestore.collection('tournaments').doc(t.id).set(t.toMap());
    return Success(t);
  } on FirebaseException catch (e) {
    return Failure('Lỗi tạo giải đấu: ${e.message}', e);
  }
}
```

---

## 8. Security Model

```
┌───────────────────────────────────────────────┐
│              Security Layers                   │
│                                                │
│  1. Firebase Auth (Anonymous)                  │
│     → Mỗi device có unique UID                │
│     → Không thể gọi Firestore nếu chưa auth   │
│                                                │
│  2. Firestore Security Rules                   │
│     → Kiểm tra token.role trước mọi operation  │
│     → Admin: full CRUD                         │
│     → Referee: chỉ update score fields         │
│     → Viewer: chỉ read                         │
│                                                │
│  3. Client-side Role Guard                     │
│     → GoRouter redirect theo role              │
│     → Widget ẩn/hiện theo quyền                │
│     → Double check, không thay thế rules       │
└───────────────────────────────────────────────┘
```
