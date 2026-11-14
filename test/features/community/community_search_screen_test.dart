import 'dart:async';

import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_search_models.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_search_repository.dart';
import 'package:app_quanly_giaidau/features/community/providers/community_search_provider.dart';
import 'package:app_quanly_giaidau/features/community/screens/community_search_screen.dart';
import 'package:app_quanly_giaidau/features/community/widgets/community_skeletons.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _clubId = 'club-1';
const _clubName = 'CLB Cầu lông & Bạn';

class _Call {
  final String communityId;
  final String query;
  final CommunitySearchType type;
  final int limit;
  const _Call(this.communityId, this.query, this.type, this.limit);
}

class _FakeSearchRepo implements ICommunitySearchRepository {
  final List<_Call> calls = [];
  CommunitySearchResults Function(String query)? resultFor;
  Object? error;
  Completer<CommunitySearchResults>? gate;

  @override
  Future<CommunitySearchResults> search(
    String communityId, {
    required String query,
    CommunitySearchType type = CommunitySearchType.all,
    int limit = 10,
  }) async {
    calls.add(_Call(communityId, query, type, limit));
    if (gate != null) return gate!.future;
    if (error != null) throw error!;
    return resultFor?.call(query) ?? CommunitySearchResults(query: query);
  }
}

const _post = CommunityPostModel(
  id: 'p1',
  authorId: 'u-author',
  authorName: 'Lan Phương',
  text: 'Cuối tuần đánh đôi nhé',
);
const _member = CommunityMemberModel(
  id: 'm1',
  userId: 'u-member',
  communityId: _clubId,
  role: 'ADMIN',
  userFullName: 'Trần Minh',
);
const _memberNoName = CommunityMemberModel(
  id: 'm2',
  userId: 'u-anon',
  communityId: _clubId,
);
const _memberNoId = CommunityMemberModel(
  id: 'm3',
  userId: '',
  communityId: _clubId,
  userFullName: 'Khách Lạ',
);
const _tournamentMatch = CommunitySearchMatchModel(
  id: 'mt1',
  source: 'TOURNAMENT',
  tournamentId: 't9',
  title: 'Vòng bảng A',
  tournamentName: 'Giải Mùa Hè',
  status: 'LIVE',
);
const _standaloneUntitled = CommunitySearchMatchModel(
  id: 'mt2',
  source: 'STANDALONE',
);
const _plainUntitled = CommunitySearchMatchModel(
  id: 'mt3',
  source: 'TOURNAMENT',
);
const _tournament = CommunityTournamentModel(
  id: 't1',
  name: 'Giải Mùa Hè',
  status: 'ongoing',
);

CommunitySearchResults _full(String query) => CommunitySearchResults(
  query: query,
  posts: const [_post],
  members: const [_member],
  matches: const [_tournamentMatch],
  tournaments: const [_tournament],
);

Future<GoRouter> _pump(
  WidgetTester tester,
  _FakeSearchRepo repo, {
  String? initialQuery,
  CommunitySearchType? initialType,
}) async {
  tester.view.physicalSize = const Size(420, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/search',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('root')),
      ),
      GoRoute(
        path: '/search',
        builder: (_, _) => CommunitySearchScreen(
          communityId: _clubId,
          communityName: _clubName,
          initialQuery: initialQuery,
          initialType: initialType,
        ),
      ),
      GoRoute(
        path: '/communities/:id/social',
        builder: (_, s) => Scaffold(
          body: Text('social-${s.pathParameters['id']}-${s.uri.query}'),
        ),
      ),
      GoRoute(
        path: '/tournament/:tid/match/:mid',
        builder: (_, s) => Scaffold(
          body: Text(
            'match-${s.pathParameters['tid']}-${s.pathParameters['mid']}',
          ),
        ),
      ),
      GoRoute(
        path: '/club/:id/match-sessions',
        builder: (_, s) =>
            Scaffold(body: Text('sessions-${s.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/intro/:id',
        builder: (_, s) =>
            Scaffold(body: Text('intro-${s.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/user/:id',
        builder: (_, s) => Scaffold(
          body: Text('user-${s.pathParameters['id']}-${s.uri.query}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        communitySearchRepositoryProvider.overrideWithValue(repo),
        userRankingsSummaryProvider.overrideWith(
          (ref, userId) async => const <PlayerRanking>[],
        ),
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
  return router;
}

/// Gõ chữ rồi chờ qua debounce 350ms.
Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  const idle = 'Nhập ít nhất 2 ký tự để tìm trong CLB';

  testWidgets('starts idle with hint, five type chips and no request', (
    tester,
  ) async {
    final repo = _FakeSearchRepo();
    await _pump(tester, repo);

    expect(find.text(idle), findsOneWidget);
    expect(find.text('Tìm bài viết, thành viên, trận đấu...'), findsOneWidget);
    for (final label in [
      'Tất cả',
      'Bài viết',
      'Thành viên',
      'Trận đấu',
      'Giải đấu',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(repo.calls, isEmpty);
  });

  testWidgets('a single character never triggers a search', (tester) async {
    final repo = _FakeSearchRepo();
    await _pump(tester, repo);
    await _type(tester, 'a');

    expect(repo.calls, isEmpty);
    expect(find.text(idle), findsOneWidget);
  });

  testWidgets('whitespace padding around one char stays idle', (tester) async {
    final repo = _FakeSearchRepo();
    await _pump(tester, repo);
    await _type(tester, '  a  ');

    expect(repo.calls, isEmpty);
    expect(find.text(idle), findsOneWidget);
  });

  testWidgets('typing waits for the debounce before calling the API', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), 'cầu');
    await tester.pump(const Duration(milliseconds: 200));
    expect(repo.calls, isEmpty);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(repo.calls, hasLength(1));
    expect(repo.calls.single.query, 'cầu');
  });

  testWidgets('rapid typing sends only the last query, trimmed', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), 'ca');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), '  cau long ');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(repo.calls.map((c) => c.query), ['cau long']);
  });

  testWidgets('request carries the club id, ALL type and default limit', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(tester, repo);
    await _type(tester, 'minh');

    final call = repo.calls.single;
    expect(call.communityId, _clubId);
    expect(call.type, CommunitySearchType.all);
    expect(call.limit, 10);
  });

  testWidgets('shows a skeleton while the request is in flight', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()..gate = Completer();
    await _pump(tester, repo);
    await tester.enterText(find.byType(TextField), 'minh');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.byType(CommunityListSkeleton), findsOneWidget);
    expect(find.text(idle), findsNothing);

    repo.gate!.complete(_full('minh'));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityListSkeleton), findsNothing);
    expect(find.text('Trần Minh'), findsOneWidget);
  });

  testWidgets('renders every section with its count when type is all', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(tester, repo);
    await _type(tester, 'minh');

    expect(find.text('Bài viết (1)'), findsOneWidget);
    expect(find.text('Thành viên (1)'), findsOneWidget);
    expect(find.text('Trận đấu (1)'), findsOneWidget);
    expect(find.text('Giải đấu (1)'), findsOneWidget);
    expect(find.text('Lan Phương'), findsOneWidget);
    expect(find.text('Cuối tuần đánh đôi nhé'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('Vòng bảng A'), findsOneWidget);
    expect(find.text('Giải Mùa Hè · LIVE'), findsOneWidget);
    expect(find.text('ongoing'), findsOneWidget);
  });

  testWidgets('omits sections that have no results', (tester) async {
    final repo = _FakeSearchRepo()
      ..resultFor = (q) =>
          CommunitySearchResults(query: q, tournaments: const [_tournament]);
    await _pump(tester, repo);
    await _type(tester, 'giai');

    expect(find.text('Giải đấu (1)'), findsOneWidget);
    expect(find.textContaining('Bài viết ('), findsNothing);
    expect(find.textContaining('Thành viên ('), findsNothing);
    expect(find.textContaining('Trận đấu ('), findsNothing);
  });

  testWidgets('shows the empty message when no section has results', (
    tester,
  ) async {
    final repo = _FakeSearchRepo();
    await _pump(tester, repo);
    await _type(tester, 'zzz');

    expect(find.text('Không tìm thấy kết quả phù hợp'), findsOneWidget);
    expect(find.text(idle), findsNothing);
  });

  testWidgets('API failure shows the error and retry calls the API again', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()..error = Exception('offline');
    await _pump(tester, repo);
    await _type(tester, 'minh');

    expect(find.text('Không thể tải kết quả tìm kiếm'), findsOneWidget);
    expect(repo.calls, hasLength(1));

    repo
      ..error = null
      ..resultFor = _full;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(repo.calls, hasLength(2));
    expect(find.text('Không thể tải kết quả tìm kiếm'), findsNothing);
    expect(find.text('Trần Minh'), findsOneWidget);
  });

  testWidgets('submitting from the keyboard searches immediately', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), 'minh');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.calls.map((c) => c.query), ['minh']);
  });

  testWidgets('submitting a one-char query does nothing', (tester) async {
    final repo = _FakeSearchRepo();
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), 'm');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(repo.calls, isEmpty);
    expect(find.text(idle), findsOneWidget);
  });

  testWidgets('clear button empties the field and returns to idle', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(tester, repo);
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    await _type(tester, 'minh');
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(_fieldText(tester), '');
    expect(find.text(idle), findsOneWidget);
    expect(find.text('Trần Minh'), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('shortening the text below 2 chars drops back to idle', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(tester, repo);
    await _type(tester, 'minh');
    expect(find.text('Trần Minh'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'm');
    await tester.pumpAndSettle();

    expect(find.text(idle), findsOneWidget);
    expect(find.text('Trần Minh'), findsNothing);
  });

  testWidgets('picking Thành viên shows only the member section', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(tester, repo);
    await _type(tester, 'minh');
    await _tapChip(tester, 'Thành viên');

    expect(find.text('Thành viên (1)'), findsOneWidget);
    expect(find.textContaining('Bài viết ('), findsNothing);
    expect(find.textContaining('Trận đấu ('), findsNothing);
    expect(find.textContaining('Giải đấu ('), findsNothing);
  });

  testWidgets('a type chip passes the type to the repository', (tester) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(tester, repo);
    await _type(tester, 'minh');
    await _tapChip(tester, 'Giải đấu');

    expect(repo.calls.last.type, CommunitySearchType.tournaments);
    expect(repo.calls.last.query, 'minh');
    expect(find.text('Giải đấu (1)'), findsOneWidget);
    expect(find.textContaining('Thành viên ('), findsNothing);
  });

  testWidgets(
    'BUG-SEARCH-01 type filter with no rows of that type shows the empty message',
    (tester) async {
      final repo = _FakeSearchRepo()
        ..resultFor = (q) =>
            CommunitySearchResults(query: q, tournaments: const [_tournament]);
      await _pump(tester, repo);
      await _type(tester, 'giai');
      await _tapChip(tester, 'Bài viết');

      expect(find.text('Không tìm thấy kết quả phù hợp'), findsOneWidget);
    },
    // BUG-SEARCH-01: hasResults đếm mọi loại, không theo chip đang chọn, nên
    // màn trắng trơn thay vì báo rỗng (community_search_screen.dart:312).
    skip: true,
  );

  testWidgets('initialQuery and initialType run a search on open', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(
      tester,
      repo,
      initialQuery: '  minh ',
      initialType: CommunitySearchType.members,
    );

    expect(repo.calls, hasLength(1));
    expect(repo.calls.single.query, 'minh');
    expect(repo.calls.single.type, CommunitySearchType.members);
    expect(find.text('Thành viên (1)'), findsOneWidget);
    expect(_fieldText(tester), 'minh');
  });

  testWidgets('a one-char initialQuery is shown in the field but stays idle', (
    tester,
  ) async {
    final repo = _FakeSearchRepo();
    await _pump(tester, repo, initialQuery: 'a');

    expect(repo.calls, isEmpty);
    expect(find.text(idle), findsOneWidget);
    expect(_fieldText(tester), 'a');
  });

  testWidgets('member without a name falls back to the section label', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()
      ..resultFor = (q) => CommunitySearchResults(
        query: q,
        members: const [_memberNoName, _memberNoId],
      );
    await _pump(tester, repo);
    await _type(tester, 'xx');

    expect(find.text('Thành viên (2)'), findsOneWidget);
    expect(find.text('Thành viên'), findsNWidgets(2)); // chip + dòng không tên
    expect(find.text('Khách Lạ'), findsOneWidget);
  });

  testWidgets('untitled matches fall back to a label by source', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()
      ..resultFor = (q) => CommunitySearchResults(
        query: q,
        matches: const [_standaloneUntitled, _plainUntitled],
      );
    await _pump(tester, repo);
    await _type(tester, 'xx');

    expect(find.text('Trận riêng'), findsOneWidget);
    expect(find.text('Trận đấu'), findsNWidgets(2)); // chip + dòng không tên
  });

  testWidgets('a post without text falls back to the section label', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()
      ..resultFor = (q) => CommunitySearchResults(
        query: q,
        posts: const [
          CommunityPostModel(id: 'p2', authorName: 'Không Lời', text: ''),
        ],
      );
    await _pump(tester, repo);
    await _type(tester, 'xx');

    expect(find.text('Không Lời'), findsOneWidget);
    expect(find.text('Bài viết'), findsNWidgets(2)); // chip + subtitle
  });

  testWidgets('tapping a post opens the club social feed with encoded name', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(tester, repo);
    await _type(tester, 'minh');
    await tester.tap(find.text('Cuối tuần đánh đôi nhé'));
    await tester.pumpAndSettle();

    expect(
      find.text('social-$_clubId-name=${Uri.encodeComponent(_clubName)}'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a tournament match opens that match', (tester) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(tester, repo);
    await _type(tester, 'minh');
    await tester.tap(find.text('Vòng bảng A'));
    await tester.pumpAndSettle();

    expect(find.text('match-t9-mt1'), findsOneWidget);
  });

  testWidgets('tapping a standalone match opens the club match sessions', (
    tester,
  ) async {
    final repo = _FakeSearchRepo()
      ..resultFor = (q) => CommunitySearchResults(
        query: q,
        matches: const [_standaloneUntitled],
      );
    await _pump(tester, repo);
    await _type(tester, 'xx');
    await tester.tap(find.text('Trận riêng'));
    await tester.pumpAndSettle();

    expect(find.text('sessions-$_clubId'), findsOneWidget);
  });

  testWidgets('tapping a tournament opens its intro page', (tester) async {
    final repo = _FakeSearchRepo()..resultFor = _full;
    await _pump(tester, repo);
    await _type(tester, 'minh');
    await tester.tap(find.text('ongoing'));
    await tester.pumpAndSettle();

    expect(find.text('intro-t1'), findsOneWidget);
  });

  group('on desktop platforms', () {
    testWidgets('tapping a member opens their profile within the club', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        final repo = _FakeSearchRepo()..resultFor = _full;
        await _pump(tester, repo);
        await _type(tester, 'minh');
        await tester.tap(find.text('Trần Minh'));
        await tester.pumpAndSettle();

        expect(find.text('user-u-member-communityId=$_clubId'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('a member row without a user id is not tappable', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        final repo = _FakeSearchRepo()
          ..resultFor = (q) =>
              CommunitySearchResults(query: q, members: const [_memberNoId]);
        await _pump(tester, repo);
        await _type(tester, 'xx');
        await tester.tap(find.text('Khách Lạ'));
        await tester.pumpAndSettle();

        expect(find.text('Khách Lạ'), findsOneWidget);
        expect(find.textContaining('user-'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  testWidgets('back button pops the screen', (tester) async {
    final repo = _FakeSearchRepo();
    final router = await _pump(tester, repo);
    router.go('/');
    await tester.pumpAndSettle();
    unawaited(router.push('/search'));
    await tester.pumpAndSettle();
    expect(find.byType(CommunitySearchScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(CommunitySearchScreen), findsNothing);
    expect(find.text('root'), findsOneWidget);
  });
}
