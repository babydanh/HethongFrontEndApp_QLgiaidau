import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/auto_draw_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

const _tournamentId = 'auto-draw-save-test';
const _managementRoute = '/quan-ly-test';

class _MockTournamentRepository extends Mock implements ITournamentRepository {}

Tournament _tournament({List<Map<String, dynamic>> divisions = const []}) =>
    Tournament.fromJson({
      'name': 'Giải lưu nhánh',
      'sport': 'badminton',
      'format': 'SINGLES',
      'bracketType': 'single_elimination',
      'status': 'upcoming',
      'maxTeams': 4,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'divisions': divisions,
    }, _tournamentId);

List<Team> _teams() => [
  for (var i = 1; i <= 4; i++)
    Team(id: 'team-$i', name: 'Đội $i', createdAt: DateTime.utc(2026)),
];

void main() {
  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(<String, dynamic>{});
  });

  late _MockTournamentRepository repo;
  late Tournament tournament;

  setUp(() {
    repo = _MockTournamentRepository();
    tournament = _tournament();
    when(
      () => repo.generateBracket(
        any(),
        divisionId: any(named: 'divisionId'),
        seedingType: any(named: 'seedingType'),
        allowReset: any(named: 'allowReset'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
  });

  Future<void> pumpRouter(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentRepositoryProvider.overrideWithValue(repo),
          teamsProvider(
            _tournamentId,
          ).overrideWith((ref) => Stream.value(_teams())),
          tournamentProvider(
            _tournamentId,
          ).overrideWith((ref) => Stream.value(tournament)),
          matchesProvider(
            _tournamentId,
          ).overrideWith((ref) => Stream.value(<MatchModel>[])),
        ],
        child: MaterialApp.router(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> drawAndSave(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.text(l10n.autoDraw_auto));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(l10n.autoDraw_saveStart), findsOneWidget);

    await tester.tap(find.text(l10n.autoDraw_saveStart));
    // Sau lưu có thể pop màn: Hero của snackbar đang bay làm hiện hai bản Text. Chờ hết hoạt ảnh để còn một bản.
    await tester.pumpAndSettle();
  }

  void expectSavedWithoutStatus(
    WidgetTester tester,
    AppLocalizations l10n, {
    required String? divisionId,
  }) {
    verify(
      () => repo.generateBracket(
        _tournamentId,
        divisionId: divisionId,
        seedingType: 'RANDOM',
        allowReset: false,
      ),
    ).called(1);
    verifyNever(() => repo.update(any(), any()));
    verifyNever(() => repo.updateStatus(any(), any()));
    expect(find.text(l10n.autoDraw_saved), findsOneWidget);
    expect(find.textContaining(l10n.autoDraw_error('')), findsNothing);
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'multi-division draw requires a division and sends no request before selection',
    (tester) async {
      tournament = _tournament(
        divisions: [
          {'id': 'division-1', 'name': 'Nội dung 1'},
          {'id': 'division-2', 'name': 'Nội dung 2'},
        ],
      );
      final router = GoRouter(
        initialLocation: '/draw',
        routes: [
          GoRoute(
            path: '/draw',
            builder: (context, state) =>
                const AutoDrawScreen(tournamentId: _tournamentId),
          ),
        ],
      );
      await pumpRouter(tester, router);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(AutoDrawScreen)),
      )!;
      await tester.tap(find.text(l10n.autoDraw_auto));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text(l10n.autoDraw_saveStart));
      await tester.pump();

      verifyNever(
        () => repo.generateBracket(
          any(),
          divisionId: any(named: 'divisionId'),
          seedingType: any(named: 'seedingType'),
          allowReset: any(named: 'allowReset'),
        ),
      );
      expect(find.text(l10n.registerSelectDivision), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selected division is sent when saving a multi-division draw', (
    tester,
  ) async {
    tournament = _tournament(
      divisions: [
        {'id': 'division-1', 'name': 'Nội dung 1'},
        {'id': 'division-2', 'name': 'Nội dung 2'},
      ],
    );
    final router = GoRouter(
      initialLocation: '/draw',
      routes: [
        GoRoute(
          path: '/draw',
          builder: (context, state) => const AutoDrawScreen(
            tournamentId: _tournamentId,
            initialDivisionId: 'division-1',
          ),
        ),
      ],
    );
    await pumpRouter(tester, router);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AutoDrawScreen)),
    )!;
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nội dung 2').last);
    await tester.pumpAndSettle();
    await drawAndSave(tester, l10n);

    verify(
      () => repo.generateBracket(
        _tournamentId,
        divisionId: 'division-2',
        seedingType: 'RANDOM',
        allowReset: false,
      ),
    ).called(1);
    verifyNever(() => repo.update(any(), any()));
    verifyNever(() => repo.updateStatus(any(), any()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('single division is sent automatically when saving', (
    tester,
  ) async {
    tournament = _tournament(
      divisions: [
        {'id': 'division-only', 'name': 'Nội dung duy nhất'},
      ],
    );
    final router = GoRouter(
      initialLocation: '/draw',
      routes: [
        GoRoute(
          path: '/draw',
          builder: (context, state) =>
              const AutoDrawScreen(tournamentId: _tournamentId),
        ),
      ],
    );
    await pumpRouter(tester, router);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AutoDrawScreen)),
    )!;
    await drawAndSave(tester, l10n);

    verify(
      () => repo.generateBracket(
        _tournamentId,
        divisionId: 'division-only',
        seedingType: 'RANDOM',
        allowReset: false,
      ),
    ).called(1);
    verifyNever(() => repo.update(any(), any()));
    verifyNever(() => repo.updateStatus(any(), any()));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mở bằng push: lưu nhánh không gửi status, không báo lỗi và quay lại màn trước',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push('/draw'),
                  child: const Text('mở bốc thăm'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/draw',
            builder: (context, state) => const AutoDrawScreen(
              tournamentId: _tournamentId,
              managementRouteBase: _managementRoute,
            ),
          ),
        ],
      );
      await pumpRouter(tester, router);
      await tester.tap(find.text('mở bốc thăm'));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(AutoDrawScreen)),
      )!;
      await drawAndSave(tester, l10n);

      expect(find.text('mở bốc thăm'), findsOneWidget);
      expectSavedWithoutStatus(tester, l10n, divisionId: null);
    },
  );

  testWidgets(
    'mở bằng go (không có route trước): lưu nhánh không báo lỗi và về trang quản lý',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/draw',
        routes: [
          GoRoute(
            path: '/draw',
            builder: (context, state) => const AutoDrawScreen(
              tournamentId: _tournamentId,
              managementRouteBase: _managementRoute,
            ),
          ),
          GoRoute(
            path: _managementRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('trang quản lý test')),
          ),
        ],
      );
      await pumpRouter(tester, router);
      await tester.pump(const Duration(milliseconds: 500));

      final l10n = AppLocalizations.of(
        tester.element(find.byType(AutoDrawScreen)),
      )!;
      await drawAndSave(tester, l10n);

      expect(find.text('trang quản lý test'), findsOneWidget);
      expectSavedWithoutStatus(tester, l10n, divisionId: null);
    },
  );
}
