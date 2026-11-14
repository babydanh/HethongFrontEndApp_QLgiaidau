import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/live/screens/live_match_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _tid = 'live-screen-test';

Tournament _tournament() => Tournament.fromJson({
  'name': 'Giải Trực Tiếp Test',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'ONGOING',
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, _tid);

MatchModel _match(
  String id,
  String status, {
  String t1 = 'Đội A',
  String t2 = 'Đội B',
  bool stale = false,
  String team1Id = 'a',
  String team2Id = 'b',
}) => MatchModel(
  id: id,
  tournamentId: _tid,
  round: 1,
  matchNumber: 1,
  team1Id: team1Id,
  team2Id: team2Id,
  team1Name: t1,
  team2Name: t2,
  status: status,
  isStaleLive: stale,
  bracketPosition: const BracketPosition(round: 1, position: 0),
  updatedAt: DateTime(2026, 1, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  required Stream<List<MatchModel>> Function() matches,
  List<Map<String, dynamic>> divisions = const [],
  Future<List<Map<String, dynamic>>> Function()? divisionsLoader,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const LiveMatchScreen(tournamentId: _tid),
      ),
      GoRoute(
        path: '/live/:matchId',
        builder: (_, state) => Scaffold(
          body: Text(
            'LIVE DETAIL ${state.pathParameters['matchId']} '
            '${state.uri.queryParameters['tournamentId']}',
          ),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('HOME PAGE')),
      ),
    ],
  );
  final overrides = <Override>[
    tournamentProvider(_tid).overrideWith((ref) => Stream.value(_tournament())),
    tournamentDivisionsProvider(
      _tid,
    ).overrideWith((ref) => (divisionsLoader ?? () async => divisions)()),
    matchesWithDivisionProvider((
      tournamentId: _tid,
      divisionId: null,
    )).overrideWith((ref) => matches()),
  ];
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: ThemeData.light(),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Finder _chipStartingWith(String label) => find.byWidgetPredicate(
  (w) =>
      w is ChoiceChip &&
      w.label is Text &&
      (w.label as Text).data!.startsWith(label),
);

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));
  final mixed = [
    _match('live-1', 'live', t1: 'Đội Lửa', t2: 'Đội Băng'),
    _match('soon-1', 'scheduled', t1: 'Đội Gió', t2: 'Đội Mây'),
    _match('done-1', 'completed', t1: 'Đội Đất', t2: 'Đội Nước'),
  ];

  testWidgets('hiện tên giải, tổng số trận và nhãn các nhóm trạng thái', (
    tester,
  ) async {
    await _pump(tester, matches: () => Stream.value(mixed));

    expect(find.text('Giải Trực Tiếp Test'), findsOneWidget);
    expect(find.text(l10n.matchesCount(3)), findsOneWidget);
    expect(find.text('Đội Lửa'), findsWidgets);
    expect(find.text('Đội Gió'), findsWidgets);
    expect(find.text('Đội Đất'), findsWidgets);
  });

  testWidgets('chip lọc hiện số trận từng trạng thái', (tester) async {
    await _pump(tester, matches: () => Stream.value(mixed));

    expect(find.text('${l10n.matchesFilterAll} (3)'), findsOneWidget);
    expect(find.text('${l10n.matchesStatusLive} (1)'), findsOneWidget);
    expect(find.text('${l10n.matchesStatusScheduled} (1)'), findsOneWidget);
    expect(find.text('${l10n.matchesStatusCompleted} (1)'), findsOneWidget);
  });

  testWidgets('lọc Đang thi đấu chỉ giữ trận live', (tester) async {
    await _pump(tester, matches: () => Stream.value(mixed));

    await tester.tap(_chipStartingWith(l10n.matchesStatusLive));
    await _settle(tester);

    expect(find.text('Đội Lửa'), findsWidgets);
    expect(find.text('Đội Gió'), findsNothing);
    expect(find.text('Đội Đất'), findsNothing);
  });

  testWidgets('lọc Hoàn thành chỉ giữ trận đã xong, Tất cả hiện lại đủ', (
    tester,
  ) async {
    await _pump(tester, matches: () => Stream.value(mixed));

    await tester.tap(_chipStartingWith(l10n.matchesStatusCompleted));
    await _settle(tester);
    expect(find.text('Đội Đất'), findsWidgets);
    expect(find.text('Đội Lửa'), findsNothing);

    await tester.tap(_chipStartingWith(l10n.matchesFilterAll));
    await _settle(tester);
    expect(find.text('Đội Lửa'), findsWidgets);
    expect(find.text('Đội Đất'), findsWidgets);
  });

  testWidgets(
    'lọc ra nhóm không có trận nào hiện thông báo không phù hợp bộ lọc',
    (tester) async {
      await _pump(
        tester,
        matches: () => Stream.value([_match('soon-1', 'scheduled')]),
      );

      await tester.tap(_chipStartingWith(l10n.matchesStatusLive));
      await _settle(tester);

      expect(find.text(l10n.liveMatchesFilteredEmpty), findsOneWidget);
    },
  );

  testWidgets(
    'trận đấu bị bỏ quên được tách sang nhóm Tạm dừng, không tính vào số live',
    (tester) async {
      await _pump(
        tester,
        matches: () => Stream.value([
          _match('stale-1', 'live', t1: 'Đội Cũ', t2: 'Đội Quên', stale: true),
        ]),
      );

      expect(find.text(l10n.matchStaleLiveStatus), findsWidgets);
      expect(find.text('${l10n.matchesStatusLive} (0)'), findsOneWidget);
    },
  );

  testWidgets(
    'trận còn ô TBD hoặc chưa có đội bị ẩn khỏi danh sách công khai',
    (tester) async {
      await _pump(
        tester,
        matches: () => Stream.value([
          _match('ok', 'scheduled', t1: 'Đội Thật', t2: 'Đội Thật Hai'),
          _match('tbd', 'scheduled', t1: 'TBD', t2: 'Đội Chờ'),
          _match('no-id', 'scheduled', team2Id: '', t1: 'Đội X', t2: 'Đội Y'),
        ]),
      );

      expect(find.text(l10n.matchesCount(1)), findsOneWidget);
      expect(find.text('Đội Chờ'), findsNothing);
      expect(find.text('Đội X'), findsNothing);
    },
  );

  testWidgets('bấm vào thẻ trận mở màn trực tiếp của trận kèm mã giải', (
    tester,
  ) async {
    await _pump(
      tester,
      matches: () => Stream.value([_match('live-1', 'live', t1: 'Đội Lửa')]),
    );

    await tester.tap(find.text('Đội Lửa').first);
    await _settle(tester);

    expect(find.text('LIVE DETAIL live-1 $_tid'), findsOneWidget);
  });

  testWidgets('có danh sách nội dung thi đấu thì hiện thanh chọn nội dung', (
    tester,
  ) async {
    await _pump(
      tester,
      matches: () => Stream.value(mixed),
      divisions: [
        {'id': 'd1', 'name': 'Đôi nam'},
        {'id': 'd2', 'name': 'Đôi nữ'},
      ],
    );

    expect(find.text('Đôi nam'), findsOneWidget);
    expect(find.text('Đôi nữ'), findsOneWidget);
  });

  testWidgets('chưa có trận nào hiện trạng thái rỗng thay vì danh sách', (
    tester,
  ) async {
    await _pump(tester, matches: () => Stream.value(const []));

    expect(find.text(l10n.liveMatchesNoMatches), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets(
    'tải trận lỗi hiện thông báo lỗi, bấm Thử lại tải lại và hiện trận',
    (tester) async {
      var attempts = 0;
      await _pump(
        tester,
        matches: () {
          attempts++;
          if (attempts == 1) return Stream.error(Exception('mất mạng'));
          return Stream.value(mixed);
        },
      );

      expect(find.text(l10n.matchesLoadError), findsOneWidget);
      expect(find.text('Đội Lửa'), findsNothing);

      await tester.tap(find.text(l10n.matchesRetry));
      await _settle(tester);

      expect(attempts, 2);
      expect(find.text(l10n.matchesLoadError), findsNothing);
      expect(find.text('Đội Lửa'), findsWidgets);
    },
  );

  testWidgets('lỗi tải danh sách nội dung cũng hiện khung lỗi có nút Thử lại', (
    tester,
  ) async {
    await _pump(
      tester,
      matches: () => Stream.value(mixed),
      divisionsLoader: () async => throw Exception('403'),
    );

    expect(find.text(l10n.matchesLoadError), findsOneWidget);
    expect(find.text(l10n.matchesRetry), findsOneWidget);
  });

  testWidgets('nút quay lại khi không có trang trước đưa về trang chủ', (
    tester,
  ) async {
    await _pump(tester, matches: () => Stream.value(mixed));

    await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
    await _settle(tester);

    expect(find.text('HOME PAGE'), findsOneWidget);
  });
}
