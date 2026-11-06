import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_notification_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

({ApiNotificationRepository repo, List<RequestOptions> requests}) _harness() {
  final requests = <RequestOptions>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': <dynamic>[],
              'meta': {'hasMore': false},
              'count': 0,
            },
          ),
        );
      },
    ),
  );
  return (
    repo: ApiNotificationRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    ),
    requests: requests,
  );
}

AppNotification _n(String id, DateTime at, {bool read = false}) =>
    AppNotification(
      id: id,
      type: 'SYSTEM',
      title: id,
      isRead: read,
      createdAt: at,
    );

class _FakeRepo implements ApiNotificationRepository {
  final pages = <String, List<NotificationPage>>{};
  final unread = <String, int>{'player': 0, 'management': 0};
  final calls = <String>[];
  final markAllScopes = <String>[];

  @override
  Future<NotificationPage> getMyNotifications({
    String? cursor,
    int limit = 20,
    String scope = 'player',
  }) async {
    calls.add('$scope:${cursor ?? '-'}');
    return pages[scope]!.removeAt(0);
  }

  @override
  Future<int> getUnreadCount({String scope = 'player'}) async => unread[scope]!;

  @override
  Future<void> markAllAsRead({String scope = 'player'}) async =>
      markAllScopes.add(scope);

  @override
  Future<void> markAsRead(String id) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ApiNotificationRepository scope', () {
    test('list sends scope, default player', () async {
      final h = _harness();
      await h.repo.getMyNotifications();
      await h.repo.getMyNotifications(scope: 'management');
      expect(h.requests[0].queryParameters['scope'], 'player');
      expect(h.requests[1].queryParameters['scope'], 'management');
    });

    test('unread-count sends scope', () async {
      final h = _harness();
      await h.repo.getUnreadCount(scope: 'management');
      expect(h.requests.single.queryParameters['scope'], 'management');
    });

    test('read-all sends scope in body', () async {
      final h = _harness();
      await h.repo.markAllAsRead(scope: 'management');
      expect(h.requests.single.data, {'scope': 'management'});
    });
  });

  group('NotificationNotifier merges scopes', () {
    final t0 = DateTime(2026, 1, 1, 10);
    ProviderContainer make(_FakeRepo repo) {
      final c = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith(_SignedIn.new),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('loadPage(1) merges both scopes sorted newest first', () async {
      final repo = _FakeRepo()
        ..pages['player'] = [
          NotificationPage(
            items: [_n('p1', t0.add(const Duration(minutes: 5))), _n('p2', t0)],
            hasMore: false,
          ),
        ]
        ..pages['management'] = [
          NotificationPage(
            items: [_n('m1', t0.add(const Duration(minutes: 9)))],
            hasMore: false,
          ),
        ];
      final c = make(repo);
      await c.read(notificationStateProvider.notifier).loadPage(1);
      final s = c.read(notificationStateProvider);
      expect(s.notifications.map((n) => n.id), ['m1', 'p1', 'p2']);
      expect(s.hasMore, isFalse);
      expect(repo.calls, containsAll(['player:-', 'management:-']));
    });

    test('next page uses a cursor per scope, skips finished scopes', () async {
      final repo = _FakeRepo()
        ..pages['player'] = [
          NotificationPage(
            items: [_n('p1', t0)],
            hasMore: true,
            nextCursor: 'cp',
          ),
          NotificationPage(
            items: [_n('p0', t0.subtract(const Duration(hours: 1)))],
            hasMore: false,
          ),
        ]
        ..pages['management'] = [
          NotificationPage(items: [_n('m1', t0)], hasMore: false),
        ];
      final c = make(repo);
      final n = c.read(notificationStateProvider.notifier);
      await n.loadPage(1);
      expect(c.read(notificationStateProvider).hasMore, isTrue);
      await n.loadPage(2);
      expect(repo.calls.where((x) => x.startsWith('management')).length, 1);
      expect(repo.calls.last, 'player:cp');
      final s = c.read(notificationStateProvider);
      expect(s.notifications.length, 3);
      expect(s.hasMore, isFalse);
    });

    test('unread count is the sum of both scopes', () async {
      final repo = _FakeRepo()
        ..unread['player'] = 2
        ..unread['management'] = 3;
      final c = make(repo);
      expect(await c.read(unreadCountProvider.future), 5);
    });

    test('markAllAsRead calls both scopes', () async {
      final repo = _FakeRepo()
        ..pages['player'] = [
          NotificationPage(items: [_n('p1', t0)], hasMore: false),
        ]
        ..pages['management'] = [
          NotificationPage(items: [_n('m1', t0)], hasMore: false),
        ];
      final c = make(repo);
      final n = c.read(notificationStateProvider.notifier);
      await n.loadPage(1);
      await n.markAllAsRead();
      expect(repo.markAllScopes.toSet(), {'player', 'management'});
      expect(
        c.read(notificationStateProvider).notifications.every((x) => x.isRead),
        isTrue,
      );
    });
  });
}

class _SignedIn extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}
