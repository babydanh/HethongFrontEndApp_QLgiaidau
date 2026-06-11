# 🛠️ SKILLS — Các kỹ năng & thư viện kỹ thuật

Tài liệu này mô tả chi tiết cách sử dụng từng thư viện trong dự án.

---

## 1. Firebase Core — `firebase_core`

### Khởi tạo Firebase
```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### Setup
```bash
# Cài FlutterFire CLI
dart pub global activate flutterfire_cli

# Cấu hình Firebase project
flutterfire configure
```

---

## 2. Cloud Firestore — `cloud_firestore`

### CRUD cơ bản
```dart
final firestore = FirebaseFirestore.instance;

// CREATE
await firestore.collection('tournaments').doc(id).set({
  'name': 'Giải CL 2025',
  'sport': 'badminton',
  'status': 'draft',
  'createdAt': FieldValue.serverTimestamp(),
});

// READ (single)
final doc = await firestore.collection('tournaments').doc(id).get();
final data = doc.data();

// READ (query)
final snapshot = await firestore
    .collection('tournaments')
    .where('status', isEqualTo: 'in_progress')
    .orderBy('createdAt', descending: true)
    .get();

// UPDATE
await firestore.collection('tournaments').doc(id).update({
  'status': 'in_progress',
  'updatedAt': FieldValue.serverTimestamp(),
});

// DELETE
await firestore.collection('tournaments').doc(id).delete();
```

### Real-time Streams
```dart
// Stream 1 document
Stream<Tournament> watchTournament(String id) {
  return firestore
      .collection('tournaments')
      .doc(id)
      .snapshots()
      .map((doc) => Tournament.fromMap(doc.data()!, doc.id));
}

// Stream collection
Stream<List<Match>> watchLiveMatches(String tournamentId) {
  return firestore
      .collection('tournaments/$tournamentId/matches')
      .where('status', isEqualTo: 'live')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Match.fromMap(doc.data(), doc.id)).toList());
}
```

### Subcollection
```dart
// Thêm đội vào giải
await firestore
    .collection('tournaments')
    .doc(tournamentId)
    .collection('teams')
    .doc(teamId)
    .set(team.toMap());
```

### Batch Write (Import nhiều đội cùng lúc)
```dart
Future<void> importTeams(String tournamentId, List<Team> teams) async {
  final batch = firestore.batch();

  for (final team in teams) {
    final ref = firestore
        .collection('tournaments/$tournamentId/teams')
        .doc(team.id);
    batch.set(ref, team.toMap());
  }

  await batch.commit(); // Atomic write
}
```

---

## 3. Firebase Auth — `firebase_auth`

### Anonymous Auth (không cần email/password)
```dart
final auth = FirebaseAuth.instance;

// Đăng nhập ẩn danh
Future<UserCredential> signInAnonymously() async {
  return await auth.signInAnonymously();
}

// Lấy UID hiện tại
String? get currentUserId => auth.currentUser?.uid;

// Kiểm tra đã đăng nhập chưa
bool get isSignedIn => auth.currentUser != null;
```

### Flow xác thực token
```dart
Future<AuthState> validateToken(String tokenCode) async {
  // 1. Đăng nhập anonymous nếu chưa
  if (!isSignedIn) {
    await signInAnonymously();
  }

  // 2. Query token từ Firestore
  final snapshot = await firestore
      .collection('tokens')
      .where('code', isEqualTo: tokenCode)
      .where('isActive', isEqualTo: true)
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) {
    return AuthState.invalid('Token không hợp lệ');
  }

  final token = TokenModel.fromMap(snapshot.docs.first.data());

  // 3. Trả về auth state với role
  return AuthState.authenticated(
    role: token.role,
    tournamentId: token.tournamentId,
  );
}
```

---

## 4. Riverpod — `flutter_riverpod`

### Setup
```dart
// main.dart
void main() async {
  // ... Firebase init
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### Provider Types sử dụng
```dart
// 1. NotifierProvider — Cho state đồng bộ phức tạp (Auth, Form)
//    ⚠️ KHÔNG dùng StateNotifierProvider (deprecated)
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();  // Initial state

  // Truy cập dependency qua ref (không cần constructor)
  ITokenRepository get _repo => ref.read(tokenRepositoryProvider);

  Future<bool> validateToken(String code) async {
    state = state.copyWith(status: AuthStatus.validating);
    final token = await _repo.validateToken(code);
    if (token == null) {
      state = AuthState(status: AuthStatus.invalid);
      return false;
    }
    state = AuthState(status: AuthStatus.authenticated, role: token.role);
    return true;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// 2. AsyncNotifierProvider — Cho state bất đồng bộ (CRUD, load data)
class TournamentListNotifier extends AsyncNotifier<List<Tournament>> {
  @override
  Future<List<Tournament>> build() async {
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

// 3. StreamProvider — Cho Firestore realtime (giữ nguyên)
final matchesProvider = StreamProvider.family<List<Match>, String>((ref, tournamentId) {
  return ref.watch(matchRepositoryProvider).watchByTournament(tournamentId);
});

// 4. FutureProvider — Cho one-time async (giữ nguyên)
final importProvider = FutureProvider.family<List<Team>, String>((ref, filePath) {
  return ref.watch(csvParserProvider).parse(filePath);
});

// 5. Provider — Cho dependency injection (giữ nguyên)
final tournamentRepositoryProvider = Provider<ITournamentRepository>((ref) {
  return FirebaseTournamentRepository(ref.watch(firestoreProvider));
});
```

### Bảng chuyển đổi API cũ → mới
| Cũ (DEPRECATED) | Mới (BẮT BUỘC) | Khi nào dùng |
|---|---|---|
| `StateNotifier` | `Notifier` | State đồng bộ (Auth, Form) |
| `StateNotifierProvider` | `NotifierProvider` | Provider cho `Notifier` |
| — | `AsyncNotifier` | State bất đồng bộ (load data) |
| — | `AsyncNotifierProvider` | Provider cho `AsyncNotifier` |

---

## 5. GoRouter — `go_router`

### Cấu hình Router
```dart
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = auth.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (!isAuth && !isAuthRoute) return '/auth';
      if (isAuth && isAuthRoute) {
        switch (auth.role) {
          case UserRole.admin:   return '/admin';
          case UserRole.referee: return '/referee';
          case UserRole.viewer:  return '/viewer';
          default: return '/auth';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const TokenEntryScreen()),
      // ... other routes
    ],
  );
});
```

---

## 6. GraphView — `graphview`

### Vẽ Bracket Tournament
```dart
import 'package:graphview/GraphView.dart';

class BracketWidget extends StatelessWidget {
  final List<Match> matches;

  Widget build(BuildContext context) {
    final graph = Graph();
    final algorithm = BuchheimWalkerConfiguration()
      ..siblingSeparation = 50
      ..levelSeparation = 100
      ..subtreeSeparation = 80
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;

    // Thêm nodes (mỗi match = 1 node)
    for (final match in matches) {
      graph.addNode(Node.Id(match.id));
    }

    // Thêm edges (link giữa các vòng)
    for (final match in matches) {
      if (match.nextMatchId.isNotEmpty) {
        graph.addEdge(
          Node.Id(match.id),
          Node.Id(match.nextMatchId),
        );
      }
    }

    return GraphView(
      graph: graph,
      algorithm: BuchheimWalkerAlgorithm(
        algorithm, TreeEdgeRenderer(algorithm),
      ),
      builder: (node) {
        final matchId = node.key!.value as String;
        final match = matches.firstWhere((m) => m.id == matchId);
        return MatchCard(match: match);  // Widget tùy chỉnh
      },
    );
  }
}
```

---

## 7. Excel & CSV Import — `excel` + `csv` + `file_picker`

### Chọn & Parse file
```dart
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

Future<List<Team>> importFromFile() async {
  // 1. Chọn file
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv', 'xlsx'],
  );
  if (result == null) return [];

  final file = result.files.first;

  // 2. Parse theo loại file
  if (file.extension == 'csv') {
    return _parseCsv(file.bytes!);
  } else {
    return _parseExcel(file.bytes!);
  }
}

List<Team> _parseCsv(Uint8List bytes) {
  final csvString = utf8.decode(bytes);
  final rows = const CsvToListConverter().convert(csvString);

  return rows.skip(1).map((row) => Team(
    name: row[0].toString(),
    members: [row[1].toString(), row[2]?.toString() ?? ''],
    contactEmail: row[3]?.toString() ?? '',
  )).toList();
}

List<Team> _parseExcel(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);
  final sheet = excel.tables.values.first;

  return sheet.rows.skip(1).map((row) => Team(
    name: row[0]?.value?.toString() ?? '',
    members: [
      row[1]?.value?.toString() ?? '',
      row[2]?.value?.toString() ?? '',
    ],
    contactEmail: row[3]?.value?.toString() ?? '',
  )).toList();
}
```

---

## 8. PDF Export — `pdf` + `printing`

### Tạo & In PDF kết quả
```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> exportResults(Tournament tournament, List<Match> matches) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text(tournament.name, style: pw.TextStyle(fontSize: 24)),
        ),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['Trận', 'Đội 1', 'Tỷ số', 'Đội 2', 'Kết quả'],
          data: matches.map((m) => [
            'V${m.round}-T${m.matchNumber}',
            m.team1Name,
            '${m.score1} - ${m.score2}',
            m.team2Name,
            m.winnerId == m.team1Id ? m.team1Name : m.team2Name,
          ]).toList(),
        ),
      ],
    ),
  );

  // Hiện dialog in/preview
  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}
```

---

## 9. QR Code — `qr_flutter` + `mobile_scanner`

### Tạo QR
```dart
import 'package:qr_flutter/qr_flutter.dart';

Widget buildQRCode(String data) {
  return QrImageView(
    data: data,
    version: QrVersions.auto,
    size: 200.0,
    backgroundColor: Colors.white,
  );
}
```

### Quét QR
```dart
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        final barcode = capture.barcodes.first;
        final value = barcode.rawValue; // VD: "VDV_042"

        // Xử lý check-in
        _checkInPlayer(value);
      },
    );
  }
}
```

---

## 10. Token Generator

### Tạo token ngẫu nhiên
```dart
import 'dart:math';

class TokenGenerator {
  static final _random = Random.secure();
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Bỏ 0,O,1,I,L

  /// Sinh token với prefix theo role
  /// VD: "ADM-X7K9-M2P4"
  static String generate(String role) {
    final prefix = switch (role) {
      'admin'   => 'ADM',
      'referee' => 'REF',
      'viewer'  => 'VWR',
      _         => 'UNK',
    };

    final part1 = _randomString(4);
    final part2 = _randomString(4);

    return '$prefix-$part1-$part2';
  }

  static String _randomString(int length) {
    return List.generate(length, (_) => _chars[_random.nextInt(_chars.length)]).join();
  }
}
```

---

## 11. Bracket Algorithms

### Fisher-Yates Shuffle (Bốc thăm ngẫu nhiên)
```dart
List<T> shuffle<T>(List<T> list) {
  final random = Random.secure();
  final result = List<T>.from(list);

  for (var i = result.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final temp = result[i];
    result[i] = result[j];
    result[j] = temp;
  }

  return result;
}
```

### Single Elimination Bracket
```dart
List<Match> generateSingleElimination(List<Team> teams) {
  final n = teams.length;
  final bracketSize = _nextPowerOf2(n);
  final rounds = (log(bracketSize) / log(2)).round();
  final matches = <Match>[];

  // Vòng 1: Tạo cặp đấu
  for (var i = 0; i < bracketSize ~/ 2; i++) {
    final team1 = i < n ? teams[i] : null;
    final team2 = (bracketSize - 1 - i) < n ? teams[bracketSize - 1 - i] : null;

    matches.add(Match(
      round: 1,
      matchNumber: i + 1,
      team1Id: team1?.id ?? '',
      team2Id: team2?.id ?? '',
      status: (team1 == null || team2 == null) ? 'walkover' : 'scheduled',
    ));
  }

  // Các vòng tiếp theo
  for (var round = 2; round <= rounds; round++) {
    final matchesInRound = bracketSize ~/ (1 << round);
    for (var i = 0; i < matchesInRound; i++) {
      matches.add(Match(
        round: round,
        matchNumber: i + 1,
        status: 'scheduled',
      ));
    }
  }

  // Link nextMatchId
  _linkMatches(matches);

  return matches;
}

int _nextPowerOf2(int n) {
  var p = 1;
  while (p < n) p *= 2;
  return p;
}
```

---

## 12. Wakelock — `wakelock_plus`

### Giữ màn hình sáng (chế độ Projector)
```dart
import 'package:wakelock_plus/wakelock_plus.dart';

// Bật khi vào chế độ chiếu bracket
await WakelockPlus.enable();

// Tắt khi thoát
await WakelockPlus.disable();
```