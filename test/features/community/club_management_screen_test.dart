import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_ranking_model.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_social_repository.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_management_screen.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/community/widgets/community_skeletons.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _clubId = 'club-1';

class _EmptySessions extends ClubMatchSessionsNotifier {
  _EmptySessions() : super(_clubId);

  @override
  Future<List<ClubMatchSessionModel>> build() async => const [];
}

class _FakeCommunityRepo extends Fake implements ICommunityRepository {
  List<CommunityMemberModel> members;
  List<CommunityMemberModel> joinRequests;
  Object? loadError;
  Object? reviewError;
  final List<(String, String, String)> reviews = [];

  _FakeCommunityRepo({this.members = const [], this.joinRequests = const []});

  @override
  Future<List<CommunityMemberModel>> getMembers(
    String communityId, {
    int limit = 50,
    String? status,
    String? search,
    bool mentionableOnly = false,
  }) async {
    if (loadError != null) throw loadError!;
    return members;
  }

  @override
  Future<List<CommunityMemberModel>> getJoinRequests(
    String communityId,
  ) async => joinRequests;

  @override
  Future<List<CommunityRankingModel>> getRankings(
    String communityId, {
    int limit = 50,
  }) async => [
    for (final m in members)
      CommunityRankingModel(
        userId: m.userId,
        fullName: m.userFullName ?? '',
        eloPoints: 1000,
      ),
    for (final m in joinRequests)
      CommunityRankingModel(
        userId: m.userId,
        fullName: m.userFullName ?? '',
        eloPoints: 1000,
      ),
  ];

  @override
  Future<List<CommunityTournamentModel>> getTournaments(
    String communityId,
  ) async => const [];

  @override
  Future<void> reviewJoinRequest(
    String communityId,
    String memberId,
    String action,
  ) async {
    reviews.add((communityId, memberId, action));
    if (reviewError != null) throw reviewError!;
    joinRequests = joinRequests.where((r) => r.userId != memberId).toList();
  }
}

class _FakeSocialRepo extends Fake implements ICommunitySocialRepository {
  List<CommunityPostModel> pending;
  Object? moderateError;
  final List<(String, String)> moderated = [];

  _FakeSocialRepo({this.pending = const []});

  @override
  Future<List<CommunityPostModel>> getPendingPosts(String communityId) async =>
      pending;

  @override
  Future<List<CommunityReportModel>> getReports(
    String communityId, {
    String status = 'OPEN',
  }) async => const [];

  @override
  Future<void> moderatePost(
    String communityId,
    String postId, {
    required String status,
  }) async {
    moderated.add((postId, status));
    if (moderateError != null) throw moderateError!;
  }
}

const _joined = CommunityMemberModel(
  id: 'm1',
  userId: 'u1',
  communityId: _clubId,
  userFullName: 'Thành Viên Một',
);
const _invited = CommunityMemberModel(
  id: 'm2',
  userId: 'u2',
  communityId: _clubId,
  status: 'INVITED',
  userFullName: 'Người Được Mời',
);
const _banned = CommunityMemberModel(
  id: 'm3',
  userId: 'u3',
  communityId: _clubId,
  status: 'BANNED',
  userFullName: 'Người Bị Cấm',
);
const _requestA = CommunityMemberModel(
  id: 'r1',
  userId: 'ua',
  communityId: _clubId,
  status: 'PENDING',
  userFullName: 'Ứng Viên A',
);
const _requestB = CommunityMemberModel(
  id: 'r2',
  userId: 'ub',
  communityId: _clubId,
  status: 'PENDING',
  userFullName: 'Ứng Viên B',
);
const _post = CommunityPostModel(
  id: 'p1',
  authorName: 'Tác Giả Bài',
  text: 'Nội dung chờ duyệt',
  status: 'PENDING',
);

Future<void> _pump(
  WidgetTester tester,
  _FakeCommunityRepo repo,
  _FakeSocialRepo social,
) async {
  tester.view.physicalSize = const Size(1400, 2800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        communityRepositoryProvider.overrideWithValue(repo),
        communitySocialRepositoryProvider.overrideWithValue(social),
        clubMatchSessionsProvider(_clubId).overrideWith(_EmptySessions.new),
      ],
      child: MaterialApp(
        theme: ThemeData.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ClubManagementScreen(clubId: _clubId, isOwner: true),
      ),
    ),
  );
  // Màn có animation nên không dùng pumpAndSettle.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _inRow(String name, String button) => find.descendant(
  of: find.ancestor(of: find.text(name), matching: find.byType(Row)).first,
  matching: find.text(button),
);

/// Ô thống kê: nhãn và số nằm chung một Column.
Finder _stat(String label, String value) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.text(value),
);

void main() {
  testWidgets('shows a list skeleton first, then the management title', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          communityRepositoryProvider.overrideWithValue(_FakeCommunityRepo()),
          communitySocialRepositoryProvider.overrideWithValue(
            _FakeSocialRepo(),
          ),
          clubMatchSessionsProvider(_clubId).overrideWith(_EmptySessions.new),
        ],
        child: MaterialApp(
          theme: ThemeData.light(),
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ClubManagementScreen(clubId: _clubId, isOwner: true),
        ),
      ),
    );
    expect(find.byType(CommunityListSkeleton), findsOneWidget);
    expect(find.text('Điều phối Câu Lạc Bộ'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CommunityListSkeleton), findsNothing);
  });

  testWidgets('hides the join-request section when nothing is pending', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeCommunityRepo(members: [_joined]),
      _FakeSocialRepo(),
    );
    expect(find.textContaining('Đơn xin gia nhập'), findsNothing);
    expect(find.text('Không có bài viết chờ duyệt.'), findsOneWidget);
  });

  testWidgets('summary counts split joined, pending, invited and banned', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeCommunityRepo(
        members: [_joined, _invited, _banned],
        joinRequests: [_requestA, _requestB],
      ),
      _FakeSocialRepo(),
    );
    expect(find.text('Đơn xin gia nhập (2)'), findsOneWidget);
    expect(_stat('Thành viên', '1'), findsOneWidget);
    expect(_stat('Chờ duyệt', '2'), findsOneWidget);
    expect(_stat('Đã mời', '1'), findsOneWidget);
    expect(_stat('Bị cấm', '1'), findsOneWidget);
  });

  testWidgets('lists each join request with approve and reject buttons', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeCommunityRepo(joinRequests: [_requestA, _requestB]),
      _FakeSocialRepo(),
    );
    expect(find.text('Ứng Viên A'), findsWidgets);
    expect(find.text('Ứng Viên B'), findsWidgets);
    expect(_inRow('Ứng Viên A', 'Duyệt'), findsOneWidget);
    expect(_inRow('Ứng Viên A', 'Từ chối'), findsOneWidget);
  });

  testWidgets('approving a request calls APPROVE and reloads the list', (
    tester,
  ) async {
    final repo = _FakeCommunityRepo(joinRequests: [_requestA, _requestB]);
    await _pump(tester, repo, _FakeSocialRepo());
    await tester.tap(_inRow('Ứng Viên A', 'Duyệt'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(repo.reviews, [(_clubId, 'ua', 'APPROVE')]);
    expect(find.text('Đã chấp nhận thành viên!'), findsOneWidget);
    expect(find.text('Đơn xin gia nhập (1)'), findsOneWidget);
  });

  testWidgets('rejecting a request calls REJECT and confirms', (tester) async {
    final repo = _FakeCommunityRepo(joinRequests: [_requestA]);
    await _pump(tester, repo, _FakeSocialRepo());
    await tester.tap(_inRow('Ứng Viên A', 'Từ chối'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(repo.reviews, [(_clubId, 'ua', 'REJECT')]);
    expect(find.text('Đã từ chối đơn gia nhập.'), findsOneWidget);
    expect(find.textContaining('Đơn xin gia nhập'), findsNothing);
  });

  testWidgets('a failed review shows the error and keeps the request', (
    tester,
  ) async {
    final repo = _FakeCommunityRepo(joinRequests: [_requestA])
      ..reviewError = Exception('403');
    await _pump(tester, repo, _FakeSocialRepo());
    await tester.tap(_inRow('Ứng Viên A', 'Duyệt'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Không thể hoàn tất thao tác. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Đơn xin gia nhập (1)'), findsOneWidget);
  });

  testWidgets('pending posts show author, text and the moderation count', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeCommunityRepo(),
      _FakeSocialRepo(pending: [_post]),
    );
    expect(find.text('Bài viết chờ duyệt (1)'), findsOneWidget);
    expect(find.text('Tác Giả Bài'), findsOneWidget);
    expect(find.text('Nội dung chờ duyệt'), findsOneWidget);
    expect(find.text('Không có bài viết chờ duyệt.'), findsNothing);
  });

  testWidgets('approving a pending post publishes it and removes the card', (
    tester,
  ) async {
    final social = _FakeSocialRepo(pending: [_post]);
    await _pump(tester, _FakeCommunityRepo(), social);
    await tester.tap(find.widgetWithText(FilledButton, 'Duyệt').first);
    await tester.pump(const Duration(milliseconds: 100));

    expect(social.moderated, [('p1', 'PUBLISHED')]);
    expect(find.text('Đã duyệt bài viết.'), findsOneWidget);
    expect(find.text('Nội dung chờ duyệt'), findsNothing);
  });

  testWidgets('rejecting a pending post sends REJECTED', (tester) async {
    final social = _FakeSocialRepo(pending: [_post]);
    await _pump(tester, _FakeCommunityRepo(), social);
    await tester.ensureVisible(find.text('Nội dung chờ duyệt'));
    final rejectButton = find.widgetWithText(OutlinedButton, 'Từ chối');
    await tester.tap(rejectButton.first);
    await tester.pump(const Duration(milliseconds: 100));

    expect(social.moderated, [('p1', 'REJECTED')]);
    expect(find.text('Đã từ chối bài viết.'), findsOneWidget);
  });

  testWidgets('a failed post moderation shows an error and keeps the post', (
    tester,
  ) async {
    final social = _FakeSocialRepo(pending: [_post])
      ..moderateError = Exception('500');
    await _pump(tester, _FakeCommunityRepo(), social);
    await tester.tap(find.widgetWithText(FilledButton, 'Duyệt').first);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Không thể xử lý bài viết.'), findsOneWidget);
    expect(find.text('Nội dung chờ duyệt'), findsOneWidget);
  });

  testWidgets('a load failure stops the skeleton and shows no requests', (
    tester,
  ) async {
    final repo = _FakeCommunityRepo(joinRequests: [_requestA])
      ..loadError = Exception('offline');
    await _pump(tester, repo, _FakeSocialRepo());

    expect(find.byType(CommunityListSkeleton), findsNothing);
    expect(find.textContaining('Đơn xin gia nhập'), findsNothing);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });

  // BUG-CLUB-02: ClubManagementScreen không kiểm quyền người xem; router chỉ
  // truyền extra isOwner (app_router.dart:668-673), nên thành viên thường mở
  // /club/:id/manage vẫn thấy đơn xin gia nhập và nút Duyệt. Backend trả 403.
  testWidgets(
    'BUG-CLUB-02 a regular member opening the management screen gets no approve controls',
    (tester) async {
      await _pump(
        tester,
        _FakeCommunityRepo(joinRequests: [_requestA]),
        _FakeSocialRepo(),
      );
      expect(find.text('Duyệt'), findsNothing);
      expect(find.textContaining('Đơn xin gia nhập'), findsNothing);
    },
    skip: true,
  );
}
