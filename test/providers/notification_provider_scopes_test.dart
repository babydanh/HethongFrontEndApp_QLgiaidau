import 'package:app_quanly_giaidau/data/repositories/api/api_notification_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SignedIn extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

/// Repo giả: scope trong [failing] ném lỗi ở mọi lệnh gọi.
class _Repo implements ApiNotificationRepository {
  final pages = <String, List<NotificationPage>>{};
  final unread = <String, int>{'player': 0, 'management': 0};
  final failing = <String>{};
  final calls = <String>[];
  final markAllScopes = <String>[];

  @override
  Future<NotificationPage> getMyNotifications({
    String? cursor,
    int limit = 20,
    String scope = 'player',
  }) async {
    calls.add('$scope:${cursor ?? '-'}');
    if (failing.contains(scope)) throw Exception('$scope down');
    return pages[scope]!.removeAt(0);
  }

  @override
  Future<int> getUnreadCount({String scope = 'player'}) async {
    if (failing.contains(scope)) throw Exception('$scope down');
    return unread[scope]!;
  }

  @override
  Future<void> markAllAsRead({String scope = 'player'}) async {
    if (failing.contains(scope)) throw Exception('$scope down');
    markAllScopes.add(scope);
  }

  @override
  Future<void> markAsRead(String id) async {}
}

final _t0 = DateTime(2026, 1, 1, 10);

AppNotification _n(
  String id, {
  Duration at = Duration.zero,
  Map<String, dynamic>? data,
  String type = 'SYSTEM',
}) => AppNotification(
  id: id,
  type: type,
  title: id,
  createdAt: _t0.add(at),
  data: data,
);

ProviderContainer _make(_Repo repo) {
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      notificationRepositoryProvider.overrideWithValue(repo),
      authProvider.overrideWith(_SignedIn.new),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('markAsRead / markAllAsRead keep data', () {
    final invite = _n(
      'a',
      type: 'COMMUNITY_INVITED',
      data: {'communityId': 'c1', 'teamId': 't1'},
    );

    test('markAsRead keeps data and ids', () async {
      final repo = _Repo()
        ..pages['player'] = [NotificationPage(items: [invite], hasMore: false)]
        ..pages['management'] = [
          const NotificationPage(items: [], hasMore: false),
        ];
      final c = _make(repo);
      final n = c.read(notificationStateProvider.notifier);
      await n.loadPage(1);
      await n.markAsRead('a');
      final got = c.read(notificationStateProvider).notifications.single;
      expect(got.isRead, isTrue);
      expect(got.communityId, 'c1');
      expect(got.footballTeamId, 't1');
      expect(got.data, {'communityId': 'c1', 'teamId': 't1'});
    });

    test('markAllAsRead keeps data and ids', () async {
      final repo = _Repo()
        ..pages['player'] = [NotificationPage(items: [invite], hasMore: false)]
        ..pages['management'] = [
          const NotificationPage(items: [], hasMore: false),
        ];
      final c = _make(repo);
      final n = c.read(notificationStateProvider.notifier);
      await n.loadPage(1);
      await n.markAllAsRead();
      final got = c.read(notificationStateProvider).notifications.single;
      expect(got.isRead, isTrue);
      expect(got.communityId, 'c1');
      expect(got.footballTeamId, 't1');
    });
  });

  group('one failing scope', () {
    test('loadPage(1) merges the good scope, no error, keeps retry', () async {
      final repo = _Repo()
        ..failing.add('management')
        ..pages['player'] = [
          NotificationPage(items: [_n('p1')], hasMore: false),
        ];
      final c = _make(repo);
      await c.read(notificationStateProvider.notifier).loadPage(1);
      final s = c.read(notificationStateProvider);
      expect(s.notifications.map((n) => n.id), ['p1']);
      expect(s.errorMessage, isNull);
      expect(s.isLoading, isFalse);
    });

    test('failed scope keeps its cursor so next page retries it', () async {
      final repo = _Repo()
        ..pages['player'] = [
          NotificationPage(
            items: [_n('p1')],
            hasMore: true,
            nextCursor: 'cp',
          ),
          NotificationPage(items: [_n('p0')], hasMore: false),
        ]
        ..pages['management'] = [
          NotificationPage(
            items: [_n('m1')],
            hasMore: true,
            nextCursor: 'cm',
          ),
          NotificationPage(items: [_n('m0')], hasMore: false),
        ];
      final c = _make(repo);
      final n = c.read(notificationStateProvider.notifier);
      await n.loadPage(1);
      repo.failing.add('management');
      await n.loadPage(2);
      var s = c.read(notificationStateProvider);
      expect(s.cursors['management'], 'cm');
      expect(s.hasMore, isTrue);
      expect(s.notifications.map((x) => x.id), containsAll(['p1', 'm1', 'p0']));
      repo.failing.clear();
      await n.loadPage(2);
      expect(repo.calls.last, 'management:cm');
      s = c.read(notificationStateProvider);
      expect(s.notifications.map((x) => x.id), contains('m0'));
      expect(s.hasMore, isFalse);
    });

    test('all scopes failing sets errorMessage', () async {
      final repo = _Repo()..failing.addAll(['player', 'management']);
      final c = _make(repo);
      await c.read(notificationStateProvider.notifier).loadPage(1);
      final s = c.read(notificationStateProvider);
      expect(s.errorMessage, isNotNull);
      expect(s.isLoading, isFalse);
    });

    test('notificationsProvider returns the good scope', () async {
      final repo = _Repo()
        ..failing.add('player')
        ..pages['management'] = [
          NotificationPage(items: [_n('m1')], hasMore: false),
        ];
      final c = _make(repo);
      final list = await c.read(notificationsProvider.future);
      expect(list.map((n) => n.id), ['m1']);
    });

    test('notificationsProvider throws when all scopes fail', () async {
      final repo = _Repo()..failing.addAll(['player', 'management']);
      final c = _make(repo);
      await expectLater(
        c.read(notificationsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('unread count sums the successful scopes', () async {
      final repo = _Repo()
        ..failing.add('management')
        ..unread['player'] = 4;
      final c = _make(repo);
      expect(await c.read(unreadCountProvider.future), 4);
    });

    test('unread count is 0 when both scopes fail', () async {
      final repo = _Repo()..failing.addAll(['player', 'management']);
      final c = _make(repo);
      expect(await c.read(unreadCountProvider.future), 0);
    });

    test('markAllAsRead marks the good scope locally, resyncs, throws',
        () async {
      final repo = _Repo()
        ..pages['player'] = [
          NotificationPage(items: [_n('p1')], hasMore: false),
          NotificationPage(items: [_n('p1')], hasMore: false),
        ]
        ..pages['management'] = [
          NotificationPage(items: [_n('m1')], hasMore: false),
          NotificationPage(items: [_n('m1')], hasMore: false),
        ];
      final c = _make(repo);
      final n = c.read(notificationStateProvider.notifier);
      await n.loadPage(1);
      repo.failing.add('management');
      await expectLater(n.markAllAsRead(), throwsA(isA<Exception>()));
      expect(repo.markAllScopes, ['player']);
      // loadPage(1) được gọi lại để đồng bộ.
      expect(repo.calls.where((x) => x == 'player:-').length, 2);
    });
  });
}
