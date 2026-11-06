import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SignedIn extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final ResponseBody Function(RequestOptions) handler;
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, {int status = 200}) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

/// [profile] là UserProfile hoặc một Object lỗi để ném.
ProviderContainer _make(_Adapter adapter, {required Object profile}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      dioProvider.overrideWithValue(dio),
      authProvider.overrideWith(_SignedIn.new),
      userProfileProvider.overrideWith((ref) async {
        final p = profile;
        if (p is UserProfile) return p;
        throw p;
      }),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  final me = UserProfile(id: 'u1', fullName: 'Me', email: 'm@x.t');

  group('userRankingsProvider', () {
    test('API error surfaces as error, not empty list', () async {
      final c = _make(_Adapter((_) => _json('{}', status: 500)), profile: me);
      await expectLater(
        c.read(userRankingsProvider.future),
        throwsA(isA<DioException>()),
      );
    });

    test('profile error propagates', () async {
      final a = _Adapter((_) => _json('{}'));
      final c = _make(a, profile: StateError('profile down'));
      await expectLater(
        c.read(userRankingsProvider.future),
        throwsA(isA<StateError>()),
      );
      expect(a.paths, isEmpty);
    });

    test('empty userId returns [] without calling API', () async {
      final a = _Adapter((_) => _json('{}'));
      final c = _make(
        a,
        profile: UserProfile(id: '', fullName: 'Guest', email: ''),
      );
      expect(await c.read(userRankingsProvider.future), isEmpty);
      expect(a.paths, isEmpty);
    });

    test('wrong payload shape throws FormatException', () async {
      final c = _make(_Adapter((_) => _json('[1,2]')), profile: me);
      await expectLater(
        c.read(userRankingsProvider.future),
        throwsA(isA<FormatException>()),
      );
    });

    test('valid payload parses publicRanks', () async {
      final c = _make(
        _Adapter((_) => _json('{"data":{"publicRanks":[]}}')),
        profile: me,
      );
      expect(await c.read(userRankingsProvider.future), isEmpty);
    });
  });

  group('userFriendsProvider', () {
    test('API error surfaces as error', () async {
      final c = _make(_Adapter((_) => _json('{}', status: 500)), profile: me);
      await expectLater(
        c.read(userFriendsProvider.future),
        throwsA(isA<DioException>()),
      );
    });

    test('wrong payload shape throws FormatException', () async {
      final c = _make(_Adapter((_) => _json('{"data":{"x":1}}')), profile: me);
      await expectLater(
        c.read(userFriendsProvider.future),
        throwsA(isA<FormatException>()),
      );
    });

    test('valid list parses', () async {
      final c = _make(
        _Adapter(
          (_) => _json('{"data":[{"friendId":"f1","status":"accepted"}]}'),
        ),
        profile: me,
      );
      final items = await c.read(userFriendsProvider.future);
      expect(items.single.friendId, 'f1');
      expect(items.single.status, 'ACCEPTED');
    });
  });
}
