import 'package:app_quanly_giaidau/data/models/club_notification_pref_model.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_social_repository.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_detail_screen.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _clubId = 'club-1';

class _SignedIn extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    role: UserRole.organizer,
  );
}

class _FakeRepo extends Fake implements ICommunityRepository {
  /// null mô phỏng 404: người xem không phải thành viên.
  Map<String, dynamic>? membership;
  bool joinResult = true;
  Object? joinError;
  final List<String> joined = [];
  final List<(String, String)> responded = [];
  final List<String> left = [];

  _FakeRepo(this.membership);

  @override
  Future<Map<String, dynamic>?> getMyMembership(String communityId) async =>
      membership;

  @override
  Future<List<ClubNotificationPrefModel>>
  getMyNotificationPreferences() async => const [];

  @override
  Future<bool> joinCommunity(
    String communityId, {
    Map<String, dynamic>? answers,
  }) async {
    joined.add(communityId);
    if (joinError != null) throw joinError!;
    return joinResult;
  }

  @override
  Future<void> respondToInvite(String communityId, String action) async {
    responded.add((communityId, action));
    membership = {'memberId': 'm', 'role': 'MEMBER', 'status': 'JOINED'};
  }

  @override
  Future<bool> leaveCommunity(String communityId, String userId) async {
    left.add(userId);
    membership = null;
    return true;
  }
}

class _FakeSocial extends Fake implements ICommunitySocialRepository {
  @override
  Future<CommunityFeedPage> getFeed(
    String communityId, {
    String? cursor,
    int limit = 12,
  }) async => const CommunityFeedPage(items: [], hasMore: false);
}

const _club = Community(
  id: _clubId,
  name: 'CLB Cầu lông Quận 7',
  ownerId: 'owner-1',
);

Future<_FakeRepo> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? membership,
  Future<Community?> Function()? club,
}) async {
  final repo = _FakeRepo(membership);
  tester.view.physicalSize = const Size(1400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authProvider.overrideWith(_SignedIn.new),
        userProfileProvider.overrideWith(
          (ref) async =>
              const UserProfile(id: 'me', fullName: 'Tôi', email: ''),
        ),
        communityRepositoryProvider.overrideWithValue(repo),
        communitySocialRepositoryProvider.overrideWithValue(_FakeSocial()),
        communityDetailProvider.overrideWith(
          (ref, id) => club != null ? club() : Future.value(_club),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ClubDetailScreen(clubId: _clubId),
      ),
    ),
  );
  await _settle(tester);
  return repo;
}

/// runAsync cho phép future giả hoàn tất; màn có animation nên không pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _membership(String role, [String status = 'JOINED']) => {
  'memberId': 'm1',
  'role': role,
  'status': status,
};

void main() {
  testWidgets('outsider sees the join button and no management entry', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('CLB Cầu lông Quận 7'), findsWidgets);
    expect(find.text('Tham gia'), findsWidgets);
    expect(find.text('Đã tham gia'), findsNothing);
    expect(find.text('Quản lý CLB'), findsNothing);
  });

  testWidgets('pending applicant sees the awaiting-approval label', (
    tester,
  ) async {
    await _pump(tester, membership: _membership('MEMBER', 'PENDING'));
    expect(find.text('Chờ phê duyệt'), findsWidgets);
    expect(find.text('Tham gia'), findsNothing);
    expect(find.text('Quản lý CLB'), findsNothing);
  });

  testWidgets('invited user sees the accept-invite label', (tester) async {
    await _pump(tester, membership: _membership('MEMBER', 'INVITED'));
    expect(find.text('Chấp nhận lời mời'), findsWidgets);
    expect(find.text('Tham gia'), findsNothing);
  });

  testWidgets('regular member sees Joined and no management button', (
    tester,
  ) async {
    await _pump(tester, membership: _membership('MEMBER'));
    expect(find.text('Đã tham gia'), findsWidgets);
    expect(find.text('Quản lý CLB'), findsNothing);
    expect(find.text('Tham gia'), findsNothing);
  });

  for (final role in ['OWNER', 'ADMIN', 'MODERATOR']) {
    testWidgets('$role sees the management button', (tester) async {
      await _pump(tester, membership: _membership(role));
      expect(find.text('Quản lý CLB'), findsOneWidget);
    });
  }

  testWidgets('the club creator sees the management button', (tester) async {
    await _pump(
      tester,
      club: () async => const Community(
        id: _clubId,
        name: 'CLB Của Tôi',
        ownerId: 'me',
        myRole: 'OWNER',
      ),
    );
    expect(find.text('Quản lý CLB'), findsOneWidget);
  });

  testWidgets('tapping Join on an open club sends the join request', (
    tester,
  ) async {
    final repo = await _pump(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Tham gia').first);
    await _settle(tester);

    expect(repo.joined, [_clubId]);
    expect(find.text('Tham gia câu lạc bộ thành công!'), findsOneWidget);
  });

  testWidgets('joining an approval club explains it awaits approval', (
    tester,
  ) async {
    await _pump(
      tester,
      club: () async => const Community(
        id: _clubId,
        name: 'CLB Xét Duyệt',
        joinMode: 'APPROVAL',
        ownerId: 'owner-1',
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Tham gia').first);
    await _settle(tester);

    expect(find.textContaining('chờ Ban chủ nhiệm xét duyệt'), findsOneWidget);
  });

  testWidgets('a rejected join shows the failure message', (tester) async {
    final repo = await _pump(tester);
    repo.joinResult = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Tham gia').first);
    await _settle(tester);

    expect(find.text('Không thể tham gia câu lạc bộ'), findsOneWidget);
  });

  testWidgets('a join error shows the reason instead of crashing', (
    tester,
  ) async {
    final repo = await _pump(tester);
    repo.joinError = Exception('CLB đã đủ thành viên');
    await tester.tap(find.widgetWithText(FilledButton, 'Tham gia').first);
    await _settle(tester);

    expect(find.textContaining('CLB đã đủ thành viên'), findsOneWidget);
    expect(find.text('Tham gia'), findsWidgets);
  });

  testWidgets('accepting an invite responds with accept', (tester) async {
    final repo = await _pump(
      tester,
      membership: _membership('MEMBER', 'INVITED'),
    );
    await tester.tap(find.text('Chấp nhận lời mời').first);
    await _settle(tester);

    expect(repo.responded, [(_clubId, 'accept')]);
    expect(find.text('Đã tham gia'), findsWidgets);
  });

  testWidgets('a missing club shows the not-found message', (tester) async {
    await _pump(tester, club: () async => null);
    expect(find.text('Không tìm thấy câu lạc bộ'), findsOneWidget);
  });

  testWidgets('a load error shows retry that reloads the club', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      club: () async {
        if (calls++ == 0) throw Exception('offline');
        return _club;
      },
    );
    expect(find.text('Không thể tải thông tin câu lạc bộ'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await _settle(tester);
    expect(find.text('Không thể tải thông tin câu lạc bộ'), findsNothing);
    expect(find.text('CLB Cầu lông Quận 7'), findsWidgets);
  });
}
