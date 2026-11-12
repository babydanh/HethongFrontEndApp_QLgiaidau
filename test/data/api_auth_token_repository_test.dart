import 'package:app_quanly_giaidau/data/repositories/api/api_auth_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_token_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

const _session = {
  'data': {
    'accessToken': 'acc',
    'refreshToken': 'ref',
    'user': {
      'roles': ['ORGANIZER', 'PLAYER'],
    },
  },
};

(ApiAuthRepository, FakeApiAdapter) _auth(Map<String, FakeReply> routes) {
  final adapter = FakeApiAdapter(routes);
  return (ApiAuthRepository(fakeDioClient(adapter)), adapter);
}

(ApiTokenRepository, FakeApiAdapter) _tokens(Map<String, FakeReply> routes) {
  final adapter = FakeApiAdapter(routes);
  return (ApiTokenRepository(fakeDioClient(adapter)), adapter);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('ApiAuthRepository sign-in', () {
    test('email login posts the credentials and maps the session', () async {
      final (repo, adapter) = _auth({
        'POST /auth/mobile/login': const FakeReply(201, _session),
      });

      final session = await repo.loginWithEmailPassword(
        email: 'a@b.vn',
        password: 'pw',
      );

      expect(session.accessToken, 'acc');
      expect(session.refreshToken, 'ref');
      expect(session.roles, ['ORGANIZER', 'PLAYER']);
      expect(adapter.requests.single.body, {'email': 'a@b.vn', 'password': 'pw'});
    });

    test('a session body without the wrapper still maps', () async {
      final (repo, _) = _auth({
        'POST /auth/mobile/google': const FakeReply(200, {
          'accessToken': 'a',
          'refreshToken': 'r',
        }),
      });

      final session = await repo.loginWithGoogle('id-token');

      expect(session.accessToken, 'a');
      expect(session.roles, isEmpty);
    });

    test('a response missing either token never yields a session', () async {
      final (repo, _) = _auth({
        'POST /auth/mobile/login': const FakeReply(200, {
          'data': {'accessToken': 'only-access'},
        }),
        'POST /auth/mobile/facebook': const FakeReply(200, {
          'data': {'refreshToken': 'only-refresh'},
        }),
      });

      await expectLater(
        repo.loginWithEmailPassword(email: 'a', password: 'b'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        repo.loginWithFacebook('fb'),
        throwsA(isA<Exception>()),
      );
    });

    test('the backend reason reaches the user for a rejected login', () async {
      final (repo, _) = _auth({
        'POST /auth/mobile/login': const FakeReply(401, {
          'message': 'Sai mật khẩu',
        }),
      });

      await expectLater(
        repo.loginWithEmailPassword(email: 'a', password: 'b'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Sai mật khẩu'),
          ),
        ),
      );
    });

    test('Apple login sends the nonce and name only when non-empty',
        () async {
      final (repo, adapter) = _auth({
        'POST /auth/mobile/apple': const FakeReply(200, _session),
      });

      await repo.loginWithApple(idToken: 'tok');
      await repo.loginWithApple(
        idToken: 'tok',
        nonce: 'n',
        fullName: 'Nguyễn An',
      );
      await repo.loginWithApple(idToken: 'tok', nonce: '', fullName: '');

      expect(adapter.requests[0].body, {'idToken': 'tok'});
      expect(adapter.requests[1].body, {
        'idToken': 'tok',
        'nonce': 'n',
        'fullName': 'Nguyễn An',
      });
      expect(adapter.requests[2].body, {'idToken': 'tok'});
    });

    test('Google and Facebook send their provider token', () async {
      final (repo, adapter) = _auth({
        'POST /auth/mobile/google': const FakeReply(200, _session),
        'POST /auth/mobile/facebook': const FakeReply(200, _session),
      });

      await repo.loginWithGoogle('g-token');
      await repo.loginWithFacebook('f-token');

      expect(adapter.requests[0].body, {'idToken': 'g-token'});
      expect(adapter.requests[1].body, {'accessToken': 'f-token'});
    });
  });

  group('ApiAuthRepository register and logout', () {
    test('register signs the user in right after creating the account',
        () async {
      final (repo, adapter) = _auth({
        'POST /auth/mobile/register': const FakeReply(201, {}),
        'POST /auth/mobile/login': const FakeReply(201, _session),
      });

      final session = await repo.registerWithEmailPassword(
        email: 'a@b.vn',
        password: 'pw',
        fullName: 'Nguyễn An',
      );

      expect(session.accessToken, 'acc');
      expect(adapter.requests.map((r) => r.path), [
        '/auth/mobile/register',
        '/auth/mobile/login',
      ]);
      expect(adapter.requests.first.body, {
        'email': 'a@b.vn',
        'password': 'pw',
        'fullName': 'Nguyễn An',
      });
    });

    test('a rejected registration does not attempt a login', () async {
      final (repo, adapter) = _auth({
        'POST /auth/mobile/register': const FakeReply(409, {
          'message': 'Email đã tồn tại',
        }),
      });

      await expectLater(
        repo.registerWithEmailPassword(
          email: 'a@b.vn',
          password: 'pw',
          fullName: 'An',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Email đã tồn tại'),
          ),
        ),
      );
      expect(adapter.requests.map((r) => r.path), ['/auth/mobile/register']);
    });

    test('logout sends the refresh token as the refreshToken cookie',
        () async {
      final (repo, adapter) = _auth({
        'POST /auth/logout': const FakeReply(200, {}),
      });

      await repo.logout(refreshToken: 'r-123');

      expect(adapter.requests.single.headers['Cookie'], 'refreshToken=r-123');
    });
  });

  group('ApiAuthRepository verification', () {
    test('email and phone verification call their routes with the payload',
        () async {
      final (repo, adapter) = _auth({
        'POST /auth/verify-email/request': const FakeReply(200, {}),
        'POST /auth/verify-email/confirm': const FakeReply(200, {}),
        'POST /auth/verify-phone/request': const FakeReply(200, {}),
        'POST /auth/verify-phone/confirm': const FakeReply(200, {}),
      });

      await repo.requestEmailVerification();
      await repo.confirmEmailVerification(token: 'tok');
      await repo.requestPhoneVerification(phoneNumber: '0900');
      await repo.confirmPhoneVerification(code: '123456');

      expect(adapter.requests.map((r) => r.body), [
        null,
        {'token': 'tok'},
        {'phoneNumber': '0900'},
        {'code': '123456'},
      ]);
    });

    test('failures surface as an Exception with the backend message',
        () async {
      final (repo, _) = _auth({
        'POST /auth/verify-phone/confirm': const FakeReply(400, {
          'message': 'Mã sai',
        }),
      });

      await expectLater(
        repo.confirmPhoneVerification(code: '0'),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'message', contains('Mã sai')),
        ),
      );
      await expectLater(
        repo.requestEmailVerification(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ApiTokenRepository', () {
    test('validateToken derives the role from an ADM-/REF- prefix and strips '
        'it from the lookup', () async {
      final (repo, adapter) = _tokens({
        'GET /tournaments/join/ABC123': const FakeReply(200, {
          'data': {'id': 't-9'},
        }),
        'GET /tournaments/join/XYZ789': const FakeReply(200, {
          'data': {'id': 't-9'},
        }),
        'GET /tournaments/join/PLAIN1': const FakeReply(200, {
          'data': {'id': 't-9'},
        }),
      });

      final admin = await repo.validateToken(' adm-abc123 ');
      final referee = await repo.validateToken('ref-xyz789');
      final viewer = await repo.validateToken('plain1');

      expect(admin?.role, 'admin');
      expect(admin?.code, 'ADM-ABC123');
      expect(admin?.tournamentId, 't-9');
      expect(referee?.role, 'referee');
      expect(viewer?.role, 'viewer');
      expect(adapter.requests.map((r) => r.path), [
        '/tournaments/join/ABC123',
        '/tournaments/join/XYZ789',
        '/tournaments/join/PLAIN1',
      ]);
    });

    test('validateToken returns null for an empty payload and rethrows '
        'failures', () async {
      final (repo, _) = _tokens({
        'GET /tournaments/join/EMPTY': const FakeReply(200, {'data': null}),
      });

      expect(await repo.validateToken('empty'), isNull);
      await expectLater(repo.validateToken('missing'), throwsA(anything));
    });

    test('getTokensByTournament lists three roles with real or fallback '
        'codes', () async {
      final (repo, _) = _tokens({
        'GET /tournaments/t1': const FakeReply(200, {
          'data': {'adminToken': 'ADM-REAL', 'viewerToken': 'VIEW-REAL'},
        }),
      });

      final tokens = await repo.getTokensByTournament('t1');

      expect(tokens.map((t) => (t.role, t.code)), [
        ('admin', 'ADM-REAL'),
        ('referee', 'REF-t1'),
        ('viewer', 'VIEW-REAL'),
      ]);
      expect(await repo.getTokensByTournament('missing'), isEmpty);
    });

    test('regenerateToken returns the token of the requested role or the '
        'supplied one', () async {
      final (repo, adapter) = _tokens({
        'POST /tournaments/t1/regenerate-invite': const FakeReply(200, {
          'data': {'adminToken': 'NEW-ADM', 'refereeToken': 'NEW-REF'},
        }),
      });

      expect(
        await repo.regenerateToken(
          tournamentId: 't1',
          role: 'admin',
          newCode: 'x',
        ),
        'NEW-ADM',
      );
      expect(
        await repo.regenerateToken(
          tournamentId: 't1',
          role: 'referee',
          newCode: 'x',
        ),
        'NEW-REF',
      );
      // No viewerToken in the reply: the caller's code is kept.
      expect(
        await repo.regenerateToken(
          tournamentId: 't1',
          role: 'viewer',
          newCode: 'KEEP',
        ),
        'KEEP',
      );
      expect(adapter.requests, hasLength(3));
    });

    test('watchToken emits a single active token with a prefix role',
        () async {
      final (repo, _) = _tokens({});

      final admin = await repo.watchToken('ADM-1').first;
      final viewer = await repo.watchToken('abc').first;

      expect(admin?.role, 'admin');
      expect(viewer?.role, 'viewer');
      expect(admin?.isActive, isTrue);
    });

    test('operations the mobile app does not own throw, and bulk delete is a '
        'no-op', () async {
      final (repo, adapter) = _tokens({});

      await expectLater(
        repo.createToken(code: 'c', role: 'admin', tournamentId: 't'),
        throwsA(isA<UnimplementedError>()),
      );
      await expectLater(
        repo.createTokensForTournament(
          tournamentId: 't',
          adminToken: 'a',
          refereeToken: 'r',
          viewerToken: 'v',
        ),
        throwsA(isA<UnimplementedError>()),
      );
      await expectLater(
        repo.deactivateToken('id'),
        throwsA(isA<UnimplementedError>()),
      );
      await repo.deleteTokensByTournament('t');
      expect(adapter.requests, isEmpty);
    });
  });
}
