import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_session_repository.dart';
import 'package:app_quanly_giaidau/features/home/widgets/global_search_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Một lần gọi GET /social-sessions mà scope kèo bắn ra.
class _SessionRequest {
  const _SessionRequest({
    required this.date,
    required this.sport,
    required this.search,
    required this.page,
  });

  final String date;
  final String? sport;
  final String? search;
  final int page;
}

class _SearchSocialSessionRepository extends Fake
    implements ISocialSessionRepository {
  _SearchSocialSessionRepository({this.sessions = const [], this.total = 0});

  final List<SocialSessionModel> sessions;
  final int total;
  final requests = <_SessionRequest>[];

  @override
  Future<SocialSessionListResponse> listByDate({
    required String date,
    String? sport,
    String? communityId,
    String? search,
    int page = 1,
    int limit = 20,
    double? lat,
    double? lng,
    double? radiusKm,
    String? sortBy,
  }) async {
    requests.add(
      _SessionRequest(date: date, sport: sport, search: search, page: page),
    );
    // Backend đã lọc sẵn bằng unaccent ILIKE — chỉ cần phân trang.
    final start = (page - 1) * limit;
    final items = start >= sessions.length
        ? const <SocialSessionModel>[]
        : sessions.skip(start).take(limit).toList();
    return SocialSessionListResponse(
      items: items,
      page: page,
      limit: limit,
      total: total,
    );
  }
}

SocialSessionModel _session(
  String title, {
  String id = 'session-1',
  String venueName = 'Sân Tân Bình',
  String venueAddress = '12 Nguyễn Văn Cừ',
  DateTime? startAt,
}) => SocialSessionModel(
  id: id,
  hostUserId: 'host-1',
  title: title,
  playFormat: 'Đá chân 5 người',
  startAt: startAt ?? DateTime(2026, 9, 29, 18),
  venueName: venueName,
  venueAddress: venueAddress,
  sport: 'bong-da',
  sportName: 'Bóng đá',
  community: const SocialCommunitySummary(
    id: 'community-1',
    name: 'CLB Test',
  ),
);

String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

Future<GoRouter> _pumpSessionsScope(
  WidgetTester tester,
  _SearchSocialSessionRepository repository,
) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const GlobalSearchScreen(
          initialTabIndex: 2,
          initialQuery: '',
        ),
      ),
      GoRoute(
        path: '/social/:id',
        builder: (context, state) => Scaffold(
          body: Text('Social detail ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [socialSessionRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  testWidgets('kèo scope is reachable and is anchored to the play date', (
    tester,
  ) async {
    final repository = _SearchSocialSessionRepository(
      sessions: [_session('Kèo bóng đá cuối tuần')],
      total: 1,
    );
    await _pumpSessionsScope(tester, repository);

    expect(find.text(l10n.homeSearchScopeSessions), findsOneWidget);
    expect(find.text(l10n.homeGlobalSearchSessionNote), findsOneWidget);
    expect(repository.requests.single.date, _todayKey());
    expect(repository.requests.single.search, isNull);
    expect(find.text('Kèo bóng đá cuối tuần'), findsOneWidget);
  });

  testWidgets('accent-free keyword keeps the diacritic kèo the backend matched', (
    tester,
  ) async {
    // Backend unaccent: gõ "bong da" vẫn ra kèo "Kèo bóng đá cuối tuần".
    // Màn hình không được lọc lại bằng contains — sẽ loái mất đúng kết quả này.
    final repository = _SearchSocialSessionRepository(
      sessions: [_session('Kèo bóng đá cuối tuần')],
      total: 1,
    );
    await _pumpSessionsScope(tester, repository);

    await tester.enterText(find.byType(TextField), 'bong da');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(repository.requests.last.search, 'bong da');
    expect(find.text('Kèo bóng đá cuối tuần'), findsOneWidget);
  });

  testWidgets('kèo row shows time and venue, then opens the kèo detail', (
    tester,
  ) async {
    final startAt = DateTime(2026, 9, 29, 18, 30);
    final repository = _SearchSocialSessionRepository(
      sessions: [
        _session('Kèo bóng đá cuối tuần', id: 'session-42', startAt: startAt),
      ],
      total: 1,
    );
    await _pumpSessionsScope(tester, repository);

    final expectedTime = DateFormat.yMMMd(
      'en',
    ).add_Hm().format(startAt.toLocal());
    expect(
      find.text('$expectedTime · Sân Tân Bình, 12 Nguyễn Văn Cừ'),
      findsOneWidget,
    );

    await tester.tap(find.text('Kèo bóng đá cuối tuần'));
    await tester.pumpAndSettle();
    expect(find.text('Social detail session-42'), findsOneWidget);
  });

  testWidgets('kèo row keeps a touch target of at least 44dp', (tester) async {
    final repository = _SearchSocialSessionRepository(
      sessions: [_session('Kèo bóng đá cuối tuần')],
      total: 1,
    );
    await _pumpSessionsScope(tester, repository);

    final row = find.ancestor(
      of: find.text('Kèo bóng đá cuối tuần'),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(row).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty kèo search falls back to the shared empty state', (
    tester,
  ) async {
    final repository = _SearchSocialSessionRepository();
    await _pumpSessionsScope(tester, repository);

    expect(find.text(l10n.homeGlobalSearchEmpty), findsOneWidget);
    expect(find.text(l10n.homeGlobalSearchNoResultsQuestion), findsNothing);
  });

  testWidgets('load more asks the next page and appends without losing rows', (
    tester,
  ) async {
    final repository = _SearchSocialSessionRepository(
      sessions: [
        for (var index = 1; index <= 12; index++)
          _session('Kèo số $index', id: 'session-$index'),
      ],
      total: 12,
    );
    await _pumpSessionsScope(tester, repository);

    expect(repository.requests.single.page, 1);
    expect(find.text(l10n.homeGlobalSearchLoadMore), findsOneWidget);

    await tester.tap(find.text(l10n.homeGlobalSearchLoadMore));
    await tester.pumpAndSettle();

    expect(repository.requests, hasLength(2));
    expect(repository.requests.last.page, 2);
    expect(find.text('Kèo số 1'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('Kèo số 12'), findsOneWidget);
  });
}
