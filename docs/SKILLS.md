# 🤖 AI Assistant Skills & Instructions

*(Tài liệu này dùng để thiết lập bộ kỹ năng, quy tắc chuẩn xác và nguyên tắc thiết kế cho AI trong quá trình phát triển dự án)*

> **⚠️ BẮT BUỘC:** Trước khi viết BẤT KỲ dòng code nào hoặc tiến hành nghiên cứu, AI PHẢI:
> 1. Kiểm tra và truy vấn đồ thị kiến thức dự án qua thư mục `graphify-out/` (sử dụng `/graphify query` hoặc đọc `graphify-out/GRAPH_REPORT.md` ở root workspace nếu tồn tại) đầu tiên để hiểu rõ toàn bộ mối liên kết cấu trúc của codebase.
> 2. Đọc các file tài liệu tương ứng trong thư mục `docs/` để nắm vững ngữ cảnh:
>
> | Khi làm việc liên quan đến... | Đọc file |
> |---|---|
> | Mối quan hệ code, cấu trúc GraphRAG | **Đồ thị Graphify (`graphify-out/GRAPH_REPORT.md`)** |
> | Kiến trúc, cấu trúc thư mục, layers | [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) |
> | Yêu cầu chức năng, luồng hoạt động | [`docs/SPEC.md`](../docs/SPEC.md) |
> | Cấu trúc database, models, queries | [`docs/DATABASE_SCHEMA.md`](../docs/DATABASE_SCHEMA.md) |
> | Kế hoạch phát triển, task tracking | [`docs/PLAN.md`](../docs/PLAN.md) |
> | Tổng quan dự án, đối tượng sử dụng | [`docs/PROJECT_OVERVIEW.md`](../docs/PROJECT_OVERVIEW.md) |
> | Cách dùng thư viện, code mẫu kỹ thuật | [`docs/Tech.md`](../docs/Tech.md) |
> | Quy tắc code, nguyên tắc thiết kế (file này) | [`docs/SKILLS.md`](../docs/SKILLS.md) |
>
> 3. Tự động chạy cập nhật đồ thị kiến thức dự án (`/graphify --update`) ngay sau khi hoàn thành bất kỳ chỉnh sửa nào để cập nhật dữ liệu mới nhất.

---

## 1. Vai trò và Bối cảnh (Role & Context)

- **Role:** Bạn là một Senior Flutter Developer & Software Architect.
- **Project:** Ứng dụng Quản lý Giải đấu (Tournament Management App).
- **Goal:** Xây dựng một ứng dụng chuyên nghiệp, hiệu năng cao, UI/UX hiện đại, tối ưu cho mobile và tablet.
- **Language:** Code viết bằng Dart. Comment và tài liệu có thể dùng tiếng Việt/tiếng Anh. Giao diện người dùng (UI) bắt buộc 100% tiếng Việt.
- **Tài liệu tham khảo:** Luôn tham chiếu [`docs/PROJECT_OVERVIEW.md`](../docs/PROJECT_OVERVIEW.md) để hiểu tổng quan dự án.

---

## 2. Nguyên tắc SOLID (SOLID Principles)

Toàn bộ code PHẢI tuân thủ 5 nguyên tắc SOLID:

### 2.1 Single Responsibility Principle (SRP) — Mỗi class một trách nhiệm
- Mỗi file/class chỉ đảm nhiệm **MỘT** chức năng duy nhất.
- **Repository** chỉ xử lý CRUD data.
- **Notifier** (Riverpod) chỉ quản lý state và gọi repository.
- **Widget/Screen** chỉ hiển thị UI và bắt sự kiện.
- **Service** chỉ xử lý business logic (VD: `BracketGeneratorService`, `TokenGeneratorService`).
- **KHÔNG** trộn lẫn logic database, state management và UI trong cùng một file.

```dart
// ❌ SAI — Trộn UI + logic + database
class TournamentScreen extends ConsumerWidget {
  Future<void> _create() async {
    await FirebaseFirestore.instance.collection('tournaments').add({...}); // Vi phạm SRP
  }
}

// ✅ ĐÚNG — Tách rõ trách nhiệm
// 1. domain/repositories/tournament_repository.dart → Interface
// 2. data/repositories/firebase/firebase_tournament_repository.dart → Implementation
// 3. providers/tournament_notifier.dart → State management
// 4. features/tournament/screens/create_tournament_screen.dart → UI
```

### 2.2 Open/Closed Principle (OCP) — Mở rộng, không sửa đổi
- Thiết kế code để **mở rộng tính năng mới** mà **KHÔNG phải sửa code cũ**.
- Sử dụng **abstract class / interface** cho các thành phần có thể thay đổi.
- Sử dụng **Strategy pattern** cho các thuật toán (bracket types).

```dart
// ✅ ĐÚNG — Dễ mở rộng thêm thể thức mới mà không sửa code cũ
abstract class IBracketGenerator {
  List<MatchModel> generate(List<Team> teams);
}

class SingleEliminationGenerator implements IBracketGenerator { ... }
class DoubleEliminationGenerator implements IBracketGenerator { ... }
class RoundRobinGenerator implements IBracketGenerator { ... }
// Thêm SwissSystemGenerator mà KHÔNG sửa code cũ
```

### 2.3 Liskov Substitution Principle (LSP) — Thay thế được
- Mọi class con phải **thay thế được** class cha mà không ảnh hưởng hành vi.
- `FirebaseTournamentRepository` phải hoạt động đúng khi thay vào `ITournamentRepository`.

### 2.4 Interface Segregation Principle (ISP) — Interface gọn nhẹ
- KHÔNG tạo interface quá lớn. Chia nhỏ interface theo chức năng.
- Tham khảo các interface hiện có trong [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) Section 2.

```dart
// ❌ SAI — Interface quá lớn
abstract class ITournamentRepository {
  // CRUD + Bracket + Scoring + PDF + ... quá nhiều
}

// ✅ ĐÚNG — Tách interface theo chức năng
abstract class ITournamentRepository { /* CRUD operations */ }
abstract class IBracketGenerator { /* Bracket logic */ }
abstract class IScoreService { /* Scoring logic */ }
```

### 2.5 Dependency Inversion Principle (DIP) — Phụ thuộc vào abstraction
- **LUÔN** code dựa trên **abstract class (Interface)**, KHÔNG phụ thuộc trực tiếp vào implementation cụ thể.
- Sử dụng **Riverpod Provider** để inject dependencies.

```dart
// ❌ SAI — Phụ thuộc trực tiếp vào HTTP Client / REST API
final repo = ApiTournamentRepository(Dio());

// ✅ ĐÚNG — Phụ thuộc vào Interface, inject qua Riverpod
final tournamentRepositoryProvider = Provider<ITournamentRepository>((ref) {
  return ApiTournamentRepository(ref.watch(dioProvider));
  // Khi đổi mock data hoặc nguồn khác, chỉ cần đổi dòng này:
  // return MockTournamentRepository();
});
```

---

## 3. Kiến trúc và Công nghệ (Architecture & Stack)

> 📖 Tham chiếu chi tiết: [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)

Khi viết code hoặc đề xuất giải pháp, luôn tuân thủ stack sau:

- **Framework:** Flutter (phiên bản mới nhất, SDK `^3.10.3`).
- **Kiến trúc:** Clean Architecture kết hợp Feature-first.
  - Chia thư mục theo feature: `lib/features/auth/`, `lib/features/tournament/`, v.v.
  - 3 layer: `domain/` (interfaces) → `data/` (implementations) → `features/` (UI).
- **State Management:** `flutter_riverpod` ^3.3.1.
  - ⚠️ **BẮT BUỘC dùng `Notifier` / `AsyncNotifier`** (API mới).
  - ❌ **KHÔNG dùng `StateNotifier` / `StateNotifierProvider`** (deprecated).
- **Routing:** `go_router` ^17.2.3 (Quản lý route phân quyền: Admin, Referee, Viewer).
- **Database/Backend:** PostgreSQL (thông qua Custom NestJS Backend API).
- **Authentication:** JWT Authentication (Access Token / Refresh Token) tích hợp Google Sign-in và Local Email/Password Auth.

### 3.1 Cấu trúc thư mục chuẩn

```text
lib/
├── main.dart                         # Entry point
├── app.dart                          # MaterialApp.router
├── core/                             # Shared utilities
│   ├── config/                       # AppTheme, AppConstants
│   ├── router/                       # GoRouter + Guards
│   ├── utils/                        # Helpers
│   └── services/                     # Logger, ErrorHandler, DioClient
├── domain/                           # Interfaces (Contracts)
│   └── repositories/                 # Abstract classes
├── data/                             # Implementations
│   ├── models/                       # Data models (toJson/fromJson)
│   └── repositories/
│       └── api/                      # REST API client implementations (Dio/Retrofit)
├── providers/                        # Riverpod Notifiers & Providers
└── features/                         # Feature modules (UI)
    ├── auth/
    ├── tournament/
    ├── teams/
    ├── bracket/
    ├── match/
    └── live/
```

---

## 4. State Management — Riverpod API Mới (BẮT BUỘC)

> 📖 Tham chiếu cách dùng thư viện: [`docs/Tech.md`](../docs/Tech.md) Section 4

### 4.1 PHẢI dùng API mới — `Notifier` và `AsyncNotifier`

```dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ❌ CẤM DÙNG — StateNotifier (DEPRECATED)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// class AuthNotifier extends StateNotifier<AuthState> { ... }
// final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ✅ BẮT BUỘC — Notifier (API MỚI)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();  // Initial state

  // Truy cập dependency qua ref (không cần constructor)
  ITournamentRepository get _repo => ref.read(tournamentRepositoryProvider);

  Future<void> validateToken(String code) async {
    state = state.copyWith(status: AuthStatus.validating);
    // ... logic
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
```

### 4.2 Bảng chuyển đổi API cũ → mới

| Cũ (CẤM DÙNG) | Mới (BẮT BUỘC) | Khi nào dùng |
|---|---|---|
| `StateNotifier` | `Notifier` | State đồng bộ (Auth, Form, UI state) |
| `StateNotifierProvider` | `NotifierProvider` | Provider cho `Notifier` |
| — | `AsyncNotifier` | State bất đồng bộ (load data, submit form) |
| — | `AsyncNotifierProvider` | Provider cho `AsyncNotifier` |
| `StreamProvider` | `StreamProvider` | Giữ nguyên — Firebase realtime streams |
| `FutureProvider` | `FutureProvider` | Giữ nguyên — One-time async |
| `Provider` | `Provider` | Giữ nguyên — DI injection |

### 4.3 AsyncNotifier — Cho tác vụ bất đồng bộ

```dart
// ✅ ĐÚNG — AsyncNotifier cho CRUD operations
class TournamentListNotifier extends AsyncNotifier<List<Tournament>> {
  @override
  Future<List<Tournament>> build() async {
    // Tự động gọi khi provider được watch
    return ref.watch(tournamentRepositoryProvider).getAll();
  }

  Future<void> createTournament(Tournament t) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(tournamentRepositoryProvider).create(t);
      return ref.read(tournamentRepositoryProvider).getAll();
    });
  }
}

final tournamentListProvider =
    AsyncNotifierProvider<TournamentListNotifier, List<Tournament>>(
        TournamentListNotifier.new);
```

### 4.4 Family Provider — Notifier có tham số

```dart
// ✅ ĐÚNG — Notifier.family cho provider cần tham số
class MatchNotifier extends FamilyAsyncNotifier<MatchModel?, ({String tournamentId, String matchId})> {
  @override
  Future<MatchModel?> build(({String tournamentId, String matchId}) arg) async {
    return ref.watch(matchRepositoryProvider).getMatch(arg.tournamentId, arg.matchId);
  }

  Future<void> updateScore({required int score1, required int score2}) async {
    state = await AsyncValue.guard(() async {
      await ref.read(matchRepositoryProvider).updateScore(
        arg.tournamentId, arg.matchId,
        score1: score1, score2: score2,
      );
      return ref.read(matchRepositoryProvider).getMatch(arg.tournamentId, arg.matchId);
    });
  }
}
```

---

## 5. Thiết kế Database & Tính linh hoạt (Database Abstraction)

> 📖 Tham chiếu chi tiết: [`docs/DATABASE_SCHEMA.md`](../docs/DATABASE_SCHEMA.md) & [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) Section 5

### 5.1 Repository Pattern — Tách biệt hoàn toàn Database

Tuân thủ nghiêm ngặt để có thể dễ dàng chuyển đổi từ Firebase sang bất kỳ hệ thống nào khác (Supabase, MongoDB, PostgreSQL, v.v.):

```text
┌─────────────────────────────────────────────┐
│ UI / Notifier (KHÔNG biết Firebase tồn tại) │
│         ↓ chỉ biết Interface                │
├─────────────────────────────────────────────┤
│    domain/repositories/                      │
│    ├── ITournamentRepository (abstract)      │
│    ├── ITeamRepository (abstract)            │
│    ├── IMatchRepository (abstract)           │
│    └── ITokenRepository (abstract)           │
├─────────────────────────────────────────────┤
│    data/repositories/firebase/               │  ← Chỉ thay đổi ở đây
│    ├── FirebaseTournamentRepository          │     khi chuyển database
│    ├── FirebaseTeamRepository                │
│    ├── FirebaseMatchRepository               │
│    └── FirebaseTokenRepository               │
├─────────────────────────────────────────────┤
│    (Tương lai) data/repositories/supabase/   │
│    ├── SupabaseTournamentRepository          │
│    └── ...                                   │
└─────────────────────────────────────────────┘
```

**Quy tắc:**

1. **KHÔNG BAO GIỜ** để UI/Notifier gọi trực tiếp `FirebaseFirestore.instance`.
2. **LUÔN** định nghĩa Interface trong `domain/repositories/`.
3. **LUÔN** implement Firebase logic trong `data/repositories/firebase/`.
4. **Chuyển database** = Viết implementation mới + đổi 1 dòng trong Provider. KHÔNG sửa UI hay Notifier.

### 5.2 Model không phụ thuộc Firebase

```dart
// ✅ ĐÚNG — Model hoàn toàn độc lập
class Tournament {
  final String id;
  final String name;
  final DateTime createdAt;  // Dùng DateTime, KHÔNG dùng Timestamp

  // Pure Dart serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

// ✅ ĐÚNG — Chuyển đổi Firebase-specific types chỉ trong Repository
class FirebaseTournamentRepository implements ITournamentRepository {
  Tournament _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tournament.fromJson({
      ...data,
      'id': doc.id,
      // Chuyển Timestamp → DateTime TẠI ĐÂY
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String()
                   ?? DateTime.now().toIso8601String(),
    });
  }
}
```

### 5.3 Security không phụ thuộc Firebase Rules

- Xử lý phân quyền **song song** ở tầng Repository/Services.
- KHÔNG dựa hoàn toàn vào Firestore Security Rules.
- Khi chuyển database, hệ thống bảo mật vẫn hoạt động.

---

## 6. Hệ thống Logging (BẮT BUỘC)

### 6.1 Logger Service

Mọi tầng (Repository, Notifier, Service) đều PHẢI có logging chuẩn:

```dart
// core/services/app_logger.dart

import 'dart:developer' as developer;

/// Logger tập trung cho toàn bộ ứng dụng.
/// Dễ dàng thay thế bằng package logging khác (logger, talker, etc.)
class AppLogger {
  final String _tag;

  const AppLogger(this._tag);

  void debug(String message) {
    developer.log('💬 $message', name: _tag);
  }

  void info(String message) {
    developer.log('ℹ️ $message', name: _tag);
  }

  void warning(String message) {
    developer.log('⚠️ $message', name: _tag);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      '❌ $message',
      name: _tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void success(String message) {
    developer.log('✅ $message', name: _tag);
  }
}
```

### 6.2 Cách sử dụng trong từng tầng

```dart
// ✅ ĐÚNG — Repository có logging
class FirebaseTournamentRepository implements ITournamentRepository {
  static const _log = AppLogger('TournamentRepo');
  final FirebaseFirestore _firestore;

  FirebaseTournamentRepository(this._firestore);

  @override
  Future<Tournament> create(Tournament tournament) async {
    _log.info('Tạo giải đấu: ${tournament.name}');
    try {
      await _firestore.collection('tournaments').doc(tournament.id).set(tournament.toJson());
      _log.success('Tạo giải đấu thành công: ${tournament.id}');
      return tournament;
    } catch (e, stack) {
      _log.error('Lỗi tạo giải đấu', e, stack);
      rethrow;
    }
  }
}

// ✅ ĐÚNG — Notifier có logging
class AuthNotifier extends Notifier<AuthState> {
  static const _log = AppLogger('AuthNotifier');

  @override
  AuthState build() => const AuthState();

  Future<bool> validateToken(String code) async {
    _log.info('Bắt đầu xác thực token: $code');
    state = state.copyWith(status: AuthStatus.validating);
    try {
      final token = await ref.read(tokenRepositoryProvider).validateToken(code);
      if (token == null) {
        _log.warning('Token không hợp lệ: $code');
        state = AuthState(status: AuthStatus.invalid, errorMessage: 'Token không hợp lệ');
        return false;
      }
      _log.success('Xác thực thành công. Role: ${token.role}, Tournament: ${token.tournamentId}');
      // ... update state
      return true;
    } catch (e, stack) {
      _log.error('Lỗi xác thực token', e, stack);
      state = AuthState(status: AuthStatus.invalid, errorMessage: 'Lỗi: $e');
      return false;
    }
  }
}
```

### 6.3 Quy tắc Logging

| Mức | Khi nào dùng | Ví dụ |
|---|---|---|
| `debug` | Thông tin debug chi tiết | `debug('Query params: $params')` |
| `info` | Bắt đầu tác vụ quan trọng | `info('Bắt đầu tạo giải đấu')` |
| `success` | Tác vụ hoàn thành thành công | `success('Tạo giải đấu thành công')` |
| `warning` | Trường hợp bất thường nhưng không crash | `warning('Token không hợp lệ')` |
| `error` | Lỗi nghiêm trọng, kèm stack trace | `error('Lỗi Firestore', e, stack)` |

- **KHÔNG** dùng `print()` trực tiếp. Luôn dùng `AppLogger`.
- **LUÔN** log kèm `error` và `stackTrace` khi bắt exception.
- **KHÔNG** log thông tin nhạy cảm (full token code, passwords).

---

## 7. Error Handling — Result Pattern

> 📖 Tham chiếu: [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) Section 7

```dart
// core/utils/result.dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  const Failure(this.message, [this.error, this.stackTrace]);
}
```

- Repository methods có thể dùng `Result<T>` hoặc throw exception (tuỳ ngữ cảnh).
- Notifier LUÔN bọc trong `try-catch` và cập nhật state.error.
- UI hiển thị lỗi thân thiện qua `ScaffoldMessenger` hoặc Error widget.

---

## 8. Quy tắc Code (Coding Standards)

Mục tiêu: Đảm bảo code dễ đọc (Readability), dễ bảo trì (Maintainability), và dễ mở rộng (Scalability).

### 8.1 Nguyên tắc Thiết kế Phần mềm (Software Design Principles)
- **SOLID Principles:**
  - **SRP (Single Responsibility Principle):** Mỗi class, widget hoặc method chỉ đảm nhận một trách nhiệm duy nhất (VD: Không gộp logic lấy dữ liệu API vào bên trong UI Widget).
  - **OCP (Open/Closed Principle):** Code mở để mở rộng nhưng đóng để sửa đổi. Sử dụng Polymorphism, Interface (`abstract class`) thay vì viết chuỗi `if/else` hoặc `switch/case` khổng lồ.
  - **DIP (Dependency Inversion Principle):** Cấp cao (UI/Use cases) phụ thuộc vào Abstraction (Interface) chứ không phụ thuộc trực tiếp vào Implementation (Firebase/Local DB). Dùng Riverpod để tiêm dependencies.
- **DRY (Don't Repeat Yourself):** Không lặp lại code. Nếu một logic hoặc widget xuất hiện từ 2 lần trở lên, hãy tách nó ra thành hàm hoặc shared widget.
- **KISS (Keep It Simple, Stupid):** Code càng đơn giản càng tốt. Đừng phức tạp hoá vấn đề bằng các design pattern không cần thiết.
- **YAGNI (You Aren't Gonna Need It):** Chỉ viết tính năng thực sự cần ngay lúc này, không viết dự phòng cho các viễn cảnh mơ hồ trong tương lai.

### 8.2 Quy tắc viết Flutter & Dart (Clean Code)
- **Tuyệt đối không dùng placeholder sơ sài:** Viết code hoàn chỉnh, sát thực tế ngay từ đầu. Tránh các `TODO` bị bỏ quên.
- **An toàn kiểu dữ liệu (Type Safety):** Khai báo tường minh kiểu dữ liệu (VD: `Map<String, dynamic>`). Tránh dùng `dynamic` trừ khi bất khả kháng.
- **Sử dụng `const` tối đa:** Thêm `const` vào constructor của các widget hoặc biến không thay đổi để tối ưu hoá performance rebuild của Flutter tree.
- **Giới hạn số dòng code:** 
  - Một file KHÔNG NÊN quá 300 dòng.
  - Một method `build()` của Widget KHÔNG NÊN quá 50 dòng. Hãy tách thành các hàm `_buildWidget()` nhỏ hơn, hoặc tốt nhất là tách hẳn thành một `StatelessWidget` con.
- **Bắt lỗi (Error Handling):** Bọc toàn bộ các tác vụ gọi mạng (async/await) trong `try-catch`. Phải log lỗi rõ ràng (qua Logger) và thông báo thân thiện lên UI.

### 8.3 Đặt tên (Naming Conventions)
- **Classes, Enums, Typedefs:** `PascalCase` (VD: `TournamentModel`, `MatchStatus`).
- **Files, Directories:** `snake_case` (VD: `tournament_model.dart`, `home_screen.dart`).
- **Variables, Functions:** `camelCase` (VD: `userName`, `calculateScore()`).
- **Constants:** Dùng `camelCase` hoặc `CONSTANT_CASE` theo tiêu chuẩn (hiện tại ưu tiên biến tĩnh `camelCase` trong class hằng số).
- Hãy đặt tên hàm dưới dạng "động từ" biểu thị hành động rõ ràng: `fetchTournaments()`, `validateInput()`. Đừng viết tắt khó hiểu.

### 8.4 Sử dụng AppTheme — KHÔNG hardcode màu sắc & style
- **Luôn** dùng định nghĩa màu sắc và spacing từ file cấu hình Theme.
```dart
// ❌ SAI: Hardcode giá trị
Text('Xin chào', style: TextStyle(color: Colors.red, fontSize: 16));
Container(color: Color(0xFF1E1E2E), margin: EdgeInsets.all(15));

// ✅ ĐÚNG: Sử dụng biến môi trường Theme
Text('Xin chào', style: TextStyle(color: context.colors.error, fontSize: AppTheme.fontMd));
Container(color: context.colors.bgSurface, margin: EdgeInsets.all(AppTheme.spacingM));
```

### 8.5 Sử dụng AppConstants — KHÔNG hardcode chuỗi string
- Tập trung các key, label, ID mẫu vào hằng số.
```dart
// ❌ SAI
firestore.collection('tournaments');
if (role == 'admin') { ... }

// ✅ ĐÚNG
firestore.collection(AppConstants.tournamentsCollection);
if (role == AppConstants.roleAdmin) { ... }
```

### 8.6 Immutable State & State Management
- **State là Immutable:** Các class đại diện cho State của Riverpod phải chứa các thuộc tính `final` và cung cấp hàm `copyWith()`.
- **Tuyệt đối không mutate State trực tiếp:** Không dùng các list `add/remove` trực tiếp vào state, phải tạo List mới và gán lại State.

---

## 9. Thiết kế Tái sử dụng — DRY (Don't Repeat Yourself)

### 9.1 Shared Widgets
Tạo widget dùng chung trong `core/` hoặc `shared/`:

```dart
// ✅ ĐÚNG — Widget tái sử dụng
// core/widgets/app_button.dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;  // primary, secondary, danger
  final bool isLoading;

  // ... builder pattern cho nhiều variant
}

// core/widgets/app_card.dart
class AppCard extends StatelessWidget { ... }

// core/widgets/loading_overlay.dart
class LoadingOverlay extends StatelessWidget { ... }

// core/widgets/empty_state.dart
class EmptyState extends StatelessWidget { ... }

// core/widgets/error_view.dart
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  // ...
}
```

### 9.2 Reusable Mixins & Extensions

```dart
// ✅ ĐÚNG — Extension tái sử dụng
extension AsyncValueUI on AsyncValue {
  void showSnackbarOnError(BuildContext context) {
    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${error.toString()}')),
      );
    }
  }
}

// ✅ ĐÚNG — Mixin cho common Firestore operations
mixin FirestoreHelpers {
  DateTime? timestampToDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
```

### 9.3 Base Repository (Optional Pattern)
```dart
// ✅ Nếu nhiều repository có logic giống nhau, tạo base class
abstract class BaseFirestoreRepository<T> {
  final FirebaseFirestore firestore;
  final String collectionPath;
  final AppLogger _log;

  BaseFirestoreRepository(this.firestore, this.collectionPath, String logTag)
      : _log = AppLogger(logTag);

  CollectionReference get collection => firestore.collection(collectionPath);

  // Common operations: getById, watchAll, delete, etc.
}
```

### 9.4 Quy tắc chống lặp code

| Lặp lại | Giải pháp |
|---|---|
| Cùng 1 widget ở nhiều screen | Tách thành Shared Widget trong `core/widgets/` |
| Cùng 1 logic ở nhiều Notifier | Tách thành Service class |
| Cùng 1 query pattern ở nhiều Repo | Tạo Base Repository hoặc Mixin |
| Cùng 1 validation logic | Tạo Validator class trong `core/utils/` |
| Cùng 1 Firestore ↔ Model mapping | Tạo Mixin `FirestoreHelpers` |

---

## 10. Đặc thù Dự án (Project-Specific Rules)

> 📖 Tham chiếu chi tiết: [`docs/SPEC.md`](../docs/SPEC.md) & [`docs/DATABASE_SCHEMA.md`](../docs/DATABASE_SCHEMA.md)

### 10.1 Hệ thống Token
- Token phân quyền 3 cấp (Admin, Referee, Viewer).
- Định dạng: `ADM-XXXX-XXXX`, `REF-XXXX-XXXX`, `VWR-XXXX-XXXX`.
- Luôn kiểm tra role trong router redirect và UI builder.

### 10.2 Giải thuật Bracket
- Module hóa: Mỗi thể thức = 1 class implement `IBracketGenerator`.
- Tham khảo thuật toán trong [`docs/Tech.md`](../docs/Tech.md) Section 11.
- Code giải thuật tách khỏi UI, đặt trong `core/services/` hoặc `domain/services/`.

### 10.3 Cập nhật Real-time
- Sử dụng `snapshots()` của Firestore để stream trạng thái trận đấu.
- Wrap trong `StreamProvider` của Riverpod.

---

## 11. Quy trình Làm việc của AI (AI Workflow Rules)

### 11.1 Trước khi viết code

1. **Đọc tài liệu tương ứng** (bảng ở đầu file).
2. **Kiểm tra code hiện tại** — Đọc file liên quan để tránh conflict.
3. **Kiểm tra interface** — Xem `domain/repositories/` trước khi thêm method.
4. **Kiểm tra widget dùng chung** — Tránh tạo widget trùng lặp.

### 11.2 Khi viết code

1. **Tuân thủ SOLID** — 5 nguyên tắc bên trên.
2. **Dùng Notifier, KHÔNG StateNotifier** — API mới của Riverpod.
3. **Logging** — Mọi method quan trọng đều phải có log.
4. **Error handling** — `try-catch` + log error + user-friendly message.
5. **Type safety** — Khai báo rõ kiểu, tránh `dynamic`.

### 11.3 Sau khi viết code

1. **Cập nhật Task Tracker** — Đánh dấu hoàn thành trong `task.md`.
2. **Giữ gìn cấu trúc** — File mới đặt đúng thư mục Clean Architecture.
3. **Chia nhỏ Widget** — Widget > 100 dòng → tách thành Widget con hoặc private method.

---

## 12. Tham chiếu nhanh (Quick Reference)

### File tài liệu dự án

| File | Nội dung | Khi nào đọc |
|---|---|---|
| [`ARCHITECTURE.md`](../docs/ARCHITECTURE.md) | Kiến trúc 3-layer, data flow, security model | Khi thiết kế feature mới, thêm layer |
| [`SPEC.md`](../docs/SPEC.md) | Đặc tả chức năng, UI flow, edge cases | Khi implement feature, xử lý logic |
| [`DATABASE_SCHEMA.md`](../docs/DATABASE_SCHEMA.md) | Models, collections, indexes, queries | Khi viết model, repository, query |
| [`PLAN.md`](../docs/PLAN.md) | Kế hoạch 4 phase, task list | Khi check tiến độ, chọn task tiếp theo |
| [`PROJECT_OVERVIEW.md`](../docs/PROJECT_OVERVIEW.md) | Tổng quan, đối tượng, luồng hoạt động | Khi cần hiểu big picture |
| [`Tech.md`](../docs/Tech.md) | Code mẫu thư viện, cách dùng Firebase/Riverpod/GoRouter | Khi viết code dùng thư viện cụ thể |

### Dependencies hiện tại (pubspec.yaml)

| Package | Version | Mục đích |
|---|---|---|
| `flutter_riverpod` | ^3.3.1 | State management (dùng Notifier API) |
| `go_router` | ^17.2.3 | Navigation + role guards |
| `firebase_core` | ^4.9.0 | Firebase init |
| `cloud_firestore` | ^6.4.1 | Realtime database |
| `firebase_auth` | ^6.5.1 | Anonymous auth |
| `google_fonts` | ^8.1.0 | Typography |
| `flutter_animate` | ^4.5.2 | Micro-animations |
| `uuid` | ^4.5.1 | Generate unique IDs |

---

## 13. Checklist trước khi commit

- [ ] Code tuân thủ SOLID (đặc biệt SRP và DIP)?
- [ ] Dùng `Notifier` / `AsyncNotifier`, KHÔNG `StateNotifier`?
- [ ] Logging đầy đủ (info khi bắt đầu, success/error khi kết thúc)?
- [ ] Database logic chỉ nằm trong `data/repositories/`?
- [ ] Model không phụ thuộc Firebase types?
- [ ] Error handling: try-catch + log + user message?
- [ ] Không hardcode colors/strings (dùng AppTheme/AppConstants)?
- [ ] Widget tái sử dụng nằm trong `core/widgets/`?
- [ ] Kiểu dữ liệu rõ ràng, không dùng `dynamic`?
- [ ] File mới đặt đúng thư mục theo Clean Architecture?

---

## 14. Bảo mật Dữ liệu & Tiêu chuẩn App Store / Google Play

Để ứng dụng không bị lộ dữ liệu nhạy cảm và sẵn sàng vượt qua vòng kiểm duyệt khắt khe của **Apple App Store** và **Google Play Store**, toàn bộ quá trình thiết kế phần mềm phải tuân thủ nghiêm ngặt các tiêu chuẩn sau:

### 14.1 Bảo mật Dữ liệu (Data Security)
- **Tuyệt đối KHÔNG Hardcode API Keys:** Bất kỳ mã bí mật nào (như key API bên thứ 3) không được dán cứng vào source code. Phải dùng file `.env` hoặc hệ thống quản lý Secret.
- **Firebase Security Rules:** Firestore Database phải có Security Rules chặt chẽ. Trọng tài chỉ được sửa (write) điểm của giải đấu mà họ có mã Token. Người xem (viewer) chỉ có quyền đọc (read). Không bao giờ mở quyền `allow read, write: if true;` trên Production.
- **Bảo mật Logging:** `AppLogger` không bao giờ được phép in ra (print) Token quản trị, mật khẩu (nếu có), hay thông tin cá nhân của người dùng.
- **Mã hóa (Obfuscation):** Khi build app đẩy lên store, bắt buộc phải bật `--obfuscate` và `--split-debug-info` để mã nguồn bị xáo trộn, chống việc kẻ gian dịch ngược (reverse-engineering) ứng dụng.

### 14.2 Quyền Riêng Tư (Privacy) & UX Store
- **Yêu cầu Quyền (Permissions) Minh bạch:** App tuyệt đối không được yêu cầu quyền Vị trí (Location), Camera, Danh bạ hay Storage nếu không có tính năng nào thực sự dùng đến. Apple sẽ từ chối (reject) ngay lập tức nếu thấy bạn xin quyền vô cớ.
- **Trải nghiệm Lỗi thân thiện:** Mọi Error Message bật lên cho người dùng không được chứa dòng Code/Stacktrace (ví dụ: `Null check operator used on a null value`). Chỉ hiển thị thông điệp con người hiểu được: *"Đã xảy ra lỗi kết nối, vui lòng thử lại sau"*.
- **Firebase App Check:** Cần kích hoạt **App Check** trên Firebase để đảm bảo chỉ có ứng dụng chính chủ tải từ Store mới có quyền gọi API xuống Database, ngăn chặn các cuộc tấn công DDoS hay spam dữ liệu từ Script bên ngoài.
- **Bắt buộc có Privacy Policy:** Store yêu cầu mọi app kết nối mạng (dù là Đăng nhập ẩn danh) đều phải đính kèm đường link Chính sách bảo mật. Code UI phải có chỗ cho người dùng đọc điều khoản này.
