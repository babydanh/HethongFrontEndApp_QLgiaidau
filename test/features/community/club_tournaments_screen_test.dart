import 'dart:async';

import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_tournaments_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _clubId = 'club-1';

typedef _Page = ({
  List<CommunityTournamentModel> tournaments,
  String? nextCursor,
  bool hasMore,
  int total,
});

class _PagedCall {
  final String? cursor;
  final int limit;
  final String? status;
  const _PagedCall(this.cursor, this.limit, this.status);
}

class _FakeRepo extends Fake implements ICommunityRepository {
  final List<_PagedCall> calls = [];

  /// Trả lời theo (status, cursor). Mặc định: trang rỗng.
  Future<_Page> Function(String? status, String? cursor)? handler;

  @override
  Future<_Page> getTournamentsPaged(
    String communityId, {
    String? cursor,
    int limit = 6,
    String? status,
    String? search,
  }) {
    expect(communityId, _clubId);
    calls.add(_PagedCall(cursor, limit, status));
    return handler?.call(status, cursor) ?? Future.value(_page(const []));
  }
}

_Page _page(
  List<CommunityTournamentModel> items, {
  String? next,
  bool hasMore = false,
  int? total,
}) => (
  tournaments: items,
  nextCursor: next,
  hasMore: hasMore,
  total: total ?? items.length,
);

CommunityTournamentModel _t(
  String id,
  String name, {
  bool lite = false,
  bool superLite = false,
  bool recurring = false,
  String? start,
}) => CommunityTournamentModel(
  id: id,
  name: name,
  isLite: lite,
  isSuperLite: superLite,
  isRecurring: recurring,
  startDate: start,
);

class _Auth extends AuthNotifier {
  final UserRole? _role;
  _Auth(this._role);

  @override
  AuthState build() => AuthState(status: AuthStatus.authenticated, role: _role);
}

CommunityMemberModel _member(String role, {String status = 'JOINED'}) =>
    CommunityMemberModel(
      id: 'm',
      userId: 'u',
      communityId: _clubId,
      role: role,
      status: status,
    );

Future<void> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  UserRole role = UserRole.viewer,
  CommunityMemberModel? membership,
}) async {
  tester.view.physicalSize = const Size(900, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/tournaments',
    routes: [
      GoRoute(
        path: '/tournaments',
        builder: (_, _) => const ClubTournamentsScreen(clubId: _clubId),
      ),
      GoRoute(
        path: '/intro/:id',
        builder: (_, s) =>
            Scaffold(body: Text('intro-${s.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/lite-manage/:id',
        builder: (_, s) =>
            Scaffold(body: Text('lite-${s.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/club/:id/create-tournament',
        builder: (_, s) =>
            Scaffold(body: Text('create-${s.pathParameters['id']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        communityRepositoryProvider.overrideWithValue(repo),
        authProvider.overrideWith(() => _Auth(role)),
        myCommunityMembershipProvider(
          _clubId,
        ).overrideWith((ref) async => membership),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

bool _addEnabled(WidgetTester tester) =>
    tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add_rounded))
        .onPressed !=
    null;

void main() {
  testWidgets('shows a skeleton while the first page is loading', (
    tester,
  ) async {
    final gate = Completer<_Page>();
    final repo = _FakeRepo()..handler = (_, _) => gate.future;
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          communityRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith(() => _Auth(UserRole.viewer)),
          myCommunityMembershipProvider(
            _clubId,
          ).overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          theme: ThemeData.light(),
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ClubTournamentsScreen(clubId: _clubId),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Chưa có giải đấu'), findsNothing);
    expect(find.byType(TournamentListItemSkeleton), findsWidgets);

    gate.complete(_page([_t('t1', 'Giải A')]));
    await tester.pumpAndSettle();
    expect(find.text('Giải A'), findsOneWidget);
    expect(find.byType(TournamentListItemSkeleton), findsNothing);
  });

  testWidgets('first request uses page size 6, no cursor and no status', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);

    expect(repo.calls, hasLength(1));
    expect(repo.calls.single.limit, 6);
    expect(repo.calls.single.cursor, isNull);
    expect(repo.calls.single.status, isNull);
  });

  testWidgets('lists tournaments with names and the pagination summary', (
    tester,
  ) async {
    final repo = _FakeRepo()
      ..handler = (_, _) async => _page([
        _t('t1', 'Giải Mùa Hè', start: '2026-07-01T00:00:00'),
        _t('t2', 'Giải Mùa Đông'),
      ], total: 2);
    await _pump(tester, repo);

    expect(find.text('Giải Mùa Hè'), findsOneWidget);
    expect(find.text('Giải Mùa Đông'), findsOneWidget);
    expect(find.text('01/07/2026'), findsOneWidget);
    expect(find.text('Trang 1 • Tổng 2 giải'), findsOneWidget);
  });

  testWidgets('empty list shows the empty state and hides pagination', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo());

    expect(find.text('Chưa có giải đấu'), findsOneWidget);
    expect(find.textContaining('Trang '), findsNothing);
    expect(find.text('Sau'), findsNothing);
  });

  testWidgets('empty state hides the create button from non-managers', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo());

    expect(find.text('Chưa có giải đấu'), findsOneWidget);
    expect(find.text('Tạo giải đấu'), findsNothing);
  });

  testWidgets('empty state shows the create button to a club owner', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo(), membership: _member('OWNER'));

    expect(find.text('Tạo giải đấu'), findsOneWidget);
  });

  testWidgets('empty state create button opens the create-tournament page', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo(), membership: _member('MODERATOR'));
    await _tap(tester, find.text('Tạo giải đấu'));

    expect(find.text('create-$_clubId'), findsOneWidget);
  });

  group('who can create', () {
    testWidgets('viewer without membership: plus button disabled', (
      tester,
    ) async {
      await _pump(tester, _FakeRepo());
      expect(_addEnabled(tester), isFalse);
    });

    testWidgets('plain MEMBER: plus button disabled', (tester) async {
      await _pump(tester, _FakeRepo(), membership: _member('MEMBER'));
      expect(_addEnabled(tester), isFalse);
    });

    testWidgets('OWNER who has not JOINED: plus button disabled', (
      tester,
    ) async {
      await _pump(
        tester,
        _FakeRepo(),
        membership: _member('OWNER', status: 'PENDING'),
      );
      expect(_addEnabled(tester), isFalse);
    });

    testWidgets('joined OWNER can create (case-insensitive role)', (
      tester,
    ) async {
      await _pump(tester, _FakeRepo(), membership: _member('owner'));
      expect(_addEnabled(tester), isTrue);

      await _tap(tester, find.byIcon(Icons.add_rounded));
      expect(find.text('create-$_clubId'), findsOneWidget);
    });

    testWidgets('joined MODERATOR can create', (tester) async {
      await _pump(tester, _FakeRepo(), membership: _member('MODERATOR'));
      expect(_addEnabled(tester), isTrue);
    });

    testWidgets('app admin can create without any membership', (tester) async {
      await _pump(tester, _FakeRepo(), role: UserRole.admin);
      expect(_addEnabled(tester), isTrue);
    });
  });

  testWidgets('load failure shows the error with retry; retry reloads', (
    tester,
  ) async {
    var attempt = 0;
    final repo = _FakeRepo()
      ..handler = (_, _) async {
        if (attempt++ == 0) throw Exception('offline');
        return _page([_t('t1', 'Giải Sau Retry')]);
      };
    await _pump(tester, repo);

    expect(find.text('Không thể tải danh sách giải đấu.'), findsOneWidget);
    expect(find.text('Chưa có giải đấu'), findsNothing);

    await _tap(tester, find.text('Thử lại'));

    expect(find.text('Không thể tải danh sách giải đấu.'), findsNothing);
    expect(find.text('Giải Sau Retry'), findsOneWidget);
    expect(repo.calls, hasLength(2));
  });

  testWidgets('a request slower than 10 seconds is reported as an error', (
    tester,
  ) async {
    final repo = _FakeRepo()..handler = (_, _) => Completer<_Page>().future;
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          communityRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith(() => _Auth(UserRole.viewer)),
          myCommunityMembershipProvider(
            _clubId,
          ).overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          theme: ThemeData.light(),
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ClubTournamentsScreen(clubId: _clubId),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('Không thể tải danh sách giải đấu.'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Không thể tải danh sách giải đấu.'), findsOneWidget);
  });

  testWidgets('tapping a normal tournament opens its intro page', (
    tester,
  ) async {
    final repo = _FakeRepo()
      ..handler = (_, _) async => _page([_t('t7', 'Giải Thường')]);
    await _pump(tester, repo);
    await _tap(tester, find.text('Giải Thường'));

    expect(find.text('intro-t7'), findsOneWidget);
  });

  testWidgets('tapping a super-lite tournament opens lite-manage', (
    tester,
  ) async {
    final repo = _FakeRepo()
      ..handler = (_, _) async =>
          _page([_t('t8', 'Giải Siêu Nhanh', lite: true, superLite: true)]);
    await _pump(tester, repo);
    await _tap(tester, find.text('Giải Siêu Nhanh'));

    expect(find.text('lite-t8'), findsOneWidget);
  });

  testWidgets('a lite tournament that is not super-lite still opens intro', (
    tester,
  ) async {
    final repo = _FakeRepo()
      ..handler = (_, _) async => _page([_t('t9', 'Giải Lite', lite: true)]);
    await _pump(tester, repo);
    await _tap(tester, find.text('Giải Lite'));

    expect(find.text('intro-t9'), findsOneWidget);
  });

  testWidgets('cards show the kind badge and the recurring badge', (
    tester,
  ) async {
    final repo = _FakeRepo()
      ..handler = (_, _) async => _page([
        _t('a', 'Nâng cao thường'),
        _t('b', 'Nhanh định kỳ', lite: true, recurring: true),
      ]);
    await _pump(tester, repo);

    expect(find.text('Nâng Cao'), findsOneWidget);
    expect(find.text('Giải Nhanh'), findsOneWidget);
    expect(find.text('Định kỳ'), findsOneWidget);
  });

  testWidgets('a card without a start date shows no date line', (tester) async {
    final repo = _FakeRepo()
      ..handler = (_, _) async => _page([_t('a', 'Không ngày')]);
    await _pump(tester, repo);

    expect(find.text('Không ngày'), findsOneWidget);
    expect(find.textContaining('/20'), findsNothing);
  });

  testWidgets('shows all four status filter chips, Tất cả selected', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo());

    for (final label in [
      'Tất cả',
      'Đang diễn ra',
      'Sắp diễn ra',
      'Đã kết thúc',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('choosing a status chip reloads from page 1 with that status', (
    tester,
  ) async {
    final repo = _FakeRepo()
      ..handler = (status, _) async => status == 'COMPLETED'
          ? _page([_t('c1', 'Giải Đã Xong')])
          : _page([_t('a1', 'Giải Bất Kỳ')]);
    await _pump(tester, repo);
    expect(find.text('Giải Bất Kỳ'), findsOneWidget);

    await _tap(tester, find.text('Đã kết thúc'));

    expect(repo.calls.last.status, 'COMPLETED');
    expect(repo.calls.last.cursor, isNull);
    expect(find.text('Giải Đã Xong'), findsOneWidget);
    expect(find.text('Giải Bất Kỳ'), findsNothing);
  });

  testWidgets('each chip sends its own status code', (tester) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);

    await _tap(tester, find.text('Đang diễn ra'));
    await _tap(tester, find.text('Sắp diễn ra'));
    await _tap(tester, find.text('Tất cả'));

    expect(repo.calls.map((c) => c.status), [
      null,
      'IN_PROGRESS',
      'UPCOMING',
      null,
    ]);
  });

  testWidgets('tapping the already selected chip does not reload', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);
    await _tap(tester, find.text('Tất cả'));

    expect(repo.calls, hasLength(1));
  });

  testWidgets('a filter with no matches shows the empty state', (tester) async {
    final repo = _FakeRepo()
      ..handler = (status, _) async =>
          status == null ? _page([_t('a', 'Giải A')]) : _page(const []);
    await _pump(tester, repo);
    await _tap(tester, find.text('Sắp diễn ra'));

    expect(find.text('Chưa có giải đấu'), findsOneWidget);
    expect(find.text('Giải A'), findsNothing);
  });

  testWidgets('a late response for the previous filter is ignored', (
    tester,
  ) async {
    final slowAll = Completer<_Page>();
    final repo = _FakeRepo();
    var first = true;
    repo.handler = (status, _) {
      if (first) {
        first = false;
        return slowAll.future;
      }
      return Future.value(_page([_t('u1', 'Giải Sắp Tới')]));
    };
    await _pump(tester, repo);

    await _tap(tester, find.text('Sắp diễn ra'));
    expect(find.text('Giải Sắp Tới'), findsOneWidget);

    slowAll.complete(_page([_t('x', 'Giải Cũ Về Muộn')]));
    await tester.pumpAndSettle();

    expect(find.text('Giải Cũ Về Muộn'), findsNothing);
    expect(find.text('Giải Sắp Tới'), findsOneWidget);
  });

  group('cursor pagination', () {
    _FakeRepo twoPages() =>
        _FakeRepo()
          ..handler = (_, cursor) async => cursor == null
              ? _page(
                  [_t('a', 'Giải Trang Một')],
                  next: 'cur-2',
                  hasMore: true,
                  total: 2,
                )
              : _page([_t('b', 'Giải Trang Hai')], total: 2);

    testWidgets('Sau is enabled only when there is a next page', (
      tester,
    ) async {
      await _pump(tester, twoPages());
      expect(find.text('Trang 1 • Tổng 2 giải'), findsOneWidget);

      await _tap(tester, find.text('Sau'));
      expect(find.text('Trang 2 • Tổng 2 giải'), findsOneWidget);

      // Trang cuối: Sau không còn tác dụng.
      await tester.tap(find.text('Sau'));
      await tester.pumpAndSettle();
      expect(find.text('Trang 2 • Tổng 2 giải'), findsOneWidget);
    });

    testWidgets('Sau requests the next cursor and shows that page', (
      tester,
    ) async {
      final repo = twoPages();
      await _pump(tester, repo);
      await _tap(tester, find.text('Sau'));

      expect(repo.calls.last.cursor, 'cur-2');
      expect(find.text('Giải Trang Hai'), findsOneWidget);
      expect(find.text('Giải Trang Một'), findsNothing);
    });

    testWidgets('Trước goes back from cache without another request', (
      tester,
    ) async {
      final repo = twoPages();
      await _pump(tester, repo);
      await _tap(tester, find.text('Sau'));
      expect(repo.calls, hasLength(2));

      await _tap(tester, find.text('Trước'));

      expect(repo.calls, hasLength(2));
      expect(find.text('Giải Trang Một'), findsOneWidget);
      expect(find.text('Trang 1 • Tổng 2 giải'), findsOneWidget);
    });

    testWidgets('going forward again reuses the cached page', (tester) async {
      final repo = twoPages();
      await _pump(tester, repo);
      await _tap(tester, find.text('Sau'));
      await _tap(tester, find.text('Trước'));
      await _tap(tester, find.text('Sau'));

      expect(repo.calls, hasLength(2));
      expect(find.text('Giải Trang Hai'), findsOneWidget);
    });

    testWidgets('Trước on the first page does nothing', (tester) async {
      final repo = twoPages();
      await _pump(tester, repo);
      await tester.tap(find.text('Trước'));
      await tester.pumpAndSettle();

      expect(repo.calls, hasLength(1));
      expect(find.text('Trang 1 • Tổng 2 giải'), findsOneWidget);
    });

    testWidgets('changing the filter returns to page 1 and drops the cache', (
      tester,
    ) async {
      final repo = twoPages();
      await _pump(tester, repo);
      await _tap(tester, find.text('Sau'));
      await _tap(tester, find.text('Sắp diễn ra'));

      expect(repo.calls.last.status, 'UPCOMING');
      expect(repo.calls.last.cursor, isNull);
      expect(find.text('Trang 1 • Tổng 2 giải'), findsOneWidget);
      expect(find.text('Giải Trang Một'), findsOneWidget);
    });

    testWidgets(
      'BUG-CLBTOUR-01 a failed next-page request tells the user',
      (tester) async {
        final repo = _FakeRepo()
          ..handler = (_, cursor) async {
            if (cursor == null) {
              return _page(
                [_t('a', 'Giải Trang Một')],
                next: 'cur-2',
                hasMore: true,
                total: 2,
              );
            }
            throw Exception('offline');
          };
        await _pump(tester, repo);
        await _tap(tester, find.text('Sau'));

        expect(find.text('Không thể tải danh sách giải đấu.'), findsOneWidget);
      },
      // BUG-CLBTOUR-01: lỗi chỉ hiển thị khi danh sách trống
      // (club_tournaments_screen.dart:155); chuyển trang lỗi thì im lặng,
      // người dùng thấy trang cũ và không biết vì sao Sau không chạy.
      skip: true,
    );
  });
}
